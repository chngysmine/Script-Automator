import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/utils/debouncer.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/edit_profile_sheet.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_stats_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/core/auth/auth_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/profile_cards.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Profile page displaying the user's script statistics, contribution heatmap,
/// achievements, and collections.
///
/// Reads real data from [ScriptRepository] for script counts and stats.
/// Social features (followers, following, DMs) have been removed as they
/// are outside the scope of a widget automation tool.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _scriptCount = 0;
  int _widgetCount = 0;
  int _weatherCount = 0;
  int _productivityCount = 0;
  int _publishedCount = 0;
  int _totalRuns = 0;

  String _displayName = '';
  String _bio = '';
  String? _avatarPath;
  String? _email;
  StreamSubscription<void>? _scriptSub;
  StreamSubscription<User?>? _authSub;
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _loadStats();
    _scriptSub = GetIt.I<ScriptRepository>().onScriptsChanged.listen((_) {
      _debouncer.run(() {
        if (mounted) _loadStats();
      });
    });

    if (GetIt.I.isRegistered<AuthService>()) {
      _authSub = GetIt.I<AuthService>().authStateChanges.listen((user) async {
        // Re-initialize preference box for the new user account UID
        await GetIt.I<UserPreferencesService>().init();
        if (mounted) {
          _loadStats();
        }
      });
    }
  }

  @override
  void dispose() {
    _scriptSub?.cancel();
    _authSub?.cancel();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    // Phase 1: Load local database scripts (very fast, no network blocking)
    final result = await GetIt.I<ScriptRepository>().getScripts();
    result.fold(
      (failure) => {},
      (scripts) {
        if (mounted) {
          setState(() {
            _scriptCount = scripts.length;
            _widgetCount = scripts
                .where((s) => s.content.contains('renderWidget'))
                .length;
            _weatherCount = scripts
                .where((s) =>
                    s.name.toLowerCase().contains('weather') ||
                    s.content.toLowerCase().contains('weather'))
                .length;
            _productivityCount = scripts
                .where((s) =>
                    s.name.toLowerCase().contains('task') ||
                    s.name.toLowerCase().contains('todo') ||
                    s.name.toLowerCase().contains('productivity') ||
                    s.name.toLowerCase().contains('timer') ||
                    s.content.toLowerCase().contains('task') ||
                    s.content.toLowerCase().contains('todo') ||
                    s.content.toLowerCase().contains('timer'))
                .length;
          });
        }
      },
    );

    final prefs = GetIt.I<UserPreferencesService>();
    String name = await prefs.displayName;
    if ((name == 'My Workspace' || name.isEmpty) && GetIt.I.isRegistered<AuthService>()) {
      final authName = GetIt.I<AuthService>().displayName;
      if (authName != 'Guest') {
        name = authName;
      }
    }
    final b = await prefs.bio;
    final ap = await prefs.avatarPath;

    int totalRuns = 0;
    if (GetIt.I.isRegistered<UserStatsService>()) {
      totalRuns = await GetIt.I<UserStatsService>().get('total_runs');
    }

    String? userEmail;
    if (GetIt.I.isRegistered<AuthService>()) {
      userEmail = GetIt.I<AuthService>().email;
    }

    // Immediately render critical profile information to UI
    if (mounted) {
      setState(() {
        _displayName = name;
        _bio = b;
        _totalRuns = totalRuns;
        _avatarPath = ap;
        _email = userEmail;
      });
    }

    // Phase 2: Fetch Firestore data in the background (slower network call)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid != 'guest') {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('gallery_published')
            .where('author_uid', isEqualTo: uid)
            .get();
        if (mounted) {
          setState(() {
            _publishedCount = snap.docs.length;
          });
        }
      } catch (e) {
        debugPrint('Failed to fetch published scripts count: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── Collapsible Instagram-Style Header ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _ProfileCollapsingHeaderDelegate(
            topPadding: topPadding,
            displayName: _displayName,
            bio: _bio,
            avatarPath: _avatarPath,
            email: _email,
            onEditProfile: () => _openEditProfile(context),
            onPickAvatar: _pickAvatar,
          ),
        ),

        // ── Scrollable Content ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildStatsRow()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 28),
                _buildSectionTitle("Contribution Activity"),
                const SizedBox(height: 12),
                _buildContributionHeatmap()
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 28),
                _buildSectionTitle("Achievements"),
                const SizedBox(height: 12),
                _buildAchievementsScroll(
                  context,
                ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.05),
                const SizedBox(height: 28),
                _buildSectionTitle("Collections"),
                const SizedBox(height: 8),
                _buildCollectionsGrid(
                  context,
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditProfileSheet(currentName: _displayName, currentBio: _bio),
    );

    if (result != null) {
      final prefs = GetIt.I<UserPreferencesService>();
      final newName = result['name'] ?? _displayName;
      final newBio = result['bio'] ?? _bio;
      await prefs.setDisplayName(newName);
      await prefs.setBio(newBio);
      if (mounted) {
        setState(() {
          _displayName = newName;
          _bio = newBio;
        });
      }
    }
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ProfileStatCard(
              value: _scriptCount.toString(),
              label: "Scripts\nCreated",
              color: LiquidTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileStatCard(
              value: _publishedCount.toString(),
              label: "Published\nWidgets",
              color: LiquidTheme.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileStatCard(
              value: _totalRuns > 1000
                  ? "${(_totalRuns / 1000).toStringAsFixed(1)}k"
                  : _totalRuns.toString(),
              label: "Total\nRuns",
              color: const Color(0xFFEC4899),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).extension<LiquidColors>()!.textTitle,
              letterSpacing: -0.5,
            ),
          ),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                "See All",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LiquidTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContributionHeatmap() {
    if (!GetIt.I.isRegistered<UserStatsService>()) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<int, int>>(
      future: GetIt.I<UserStatsService>().getDailyActivity(days: 364),
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activityData = snapshot.data ?? {};
        final now = DateTime.now();

        // Find max value for normalization
        int maxVal = 1;
        for (final v in activityData.values) {
          if (v > maxVal) maxVal = v;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 8),
                        ...['M', '', 'W', '', 'F', '', 'S'].map(
                          (d) => SizedBox(
                            height: 14,
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context)
                                    .extension<LiquidColors>()!
                                    .textCaption
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 7 * 14.0,
                        child: CustomScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                weekIndex,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(7, (dayIndex) {
                                      final daysAgo =
                                          weekIndex * 7 + (6 - dayIndex);
                                      final date = now.subtract(
                                        Duration(days: daysAgo),
                                      );
                                      final key =
                                          date.year * 10000 +
                                          date.month * 100 +
                                          date.day;
                                      final count = activityData[key] ?? 0;
                                      final emptyColor = isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE8ECF4);
                                      final intensity = count == 0
                                          ? 0.0
                                          : (count / maxVal).clamp(0.15, 1.0);

                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: count == 0
                                              ? emptyColor
                                              : LiquidTheme.primary.withValues(
                                                  alpha: intensity,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }, childCount: 52),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<int>(
                      future: GetIt.I<UserStatsService>().get('streak_days'),
                      builder: (context, streakSnap) {
                        final streak = streakSnap.data ?? 0;
                        return Text(
                          streak > 0
                              ? "🔥 $streak day streak"
                              : "Start a streak!",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: streak > 0
                                ? LiquidTheme.primary
                                : Theme.of(context)
                                      .extension<LiquidColors>()!
                                      .textCaption
                                      .withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Text(
                          "Less",
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .extension<LiquidColors>()!
                                .textCaption
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...[0.0, 0.25, 0.5, 0.75, 1.0].map(
                          (v) => Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: v == 0
                                  ? const Color(0xFFE8ECF4)
                                  : LiquidTheme.primary.withValues(alpha: v),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "More",
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .extension<LiquidColors>()!
                                .textCaption
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsScroll(BuildContext context) {
    if (!GetIt.I.isRegistered<UserStatsService>()) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Map<String, bool>>(
      future: GetIt.I<UserStatsService>().getAchievementStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data ?? {};
        final badges = [
          _BadgeData(
            Icons.bolt_rounded,
            "Syntax God",
            "50 error-free runs",
            const Color(0xFFEAB308),
            unlocked: status['syntax_god'] ?? false,
          ),
          _BadgeData(
            Icons.widgets_rounded,
            "Widget Lord",
            "10 widgets created",
            LiquidTheme.primary,
            unlocked: status['widget_lord'] ?? false,
          ),
          _BadgeData(
            Icons.local_fire_department,
            "Streak x7",
            "7-day run streak",
            const Color(0xFFEF4444),
            unlocked: status['streak_x7'] ?? false,
          ),
          _BadgeData(
            Icons.auto_awesome,
            "AI Whisperer",
            "100 AI suggestions",
            const Color(0xFF8B5CF6),
            unlocked: status['ai_whisperer'] ?? false,
          ),
          _BadgeData(
            Icons.public_rounded,
            "Community Star",
            "5 published scripts",
            LiquidTheme.cyan,
            unlocked: status['community_star'] ?? false,
          ),
          _BadgeData(
            Icons.code_rounded,
            "1K Lines",
            "1000 lines written",
            const Color(0xFF10B981),
            unlocked: status['1k_lines'] ?? false,
          ),
        ];

        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = badges[index];
              return _buildBadgeCard(
                context,
                b.icon,
                b.title,
                b.subtitle,
                b.color,
                unlocked: b.unlocked,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    bool unlocked = true,
  }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(
              context,
            ).extension<LiquidColors>()!.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(icon, color: unlocked ? color : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<LiquidColors>()!.textTitle,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              unlocked ? "Unlocked: $subtitle." : "Locked. Goal: $subtitle.",
              style: TextStyle(
                color: Theme.of(context).extension<LiquidColors>()!.textBody,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Awesome",
                  style: TextStyle(color: LiquidTheme.cyan),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: unlocked
                ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
                : [
                    Colors.grey.withValues(alpha: 0.1),
                    Colors.grey.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked
                ? color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: unlocked
                      ? [
                          color.withValues(alpha: 0.8),
                          color.withValues(alpha: 0.2),
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.3),
                          Colors.grey.withValues(alpha: 0.1),
                        ],
                ),
              ),
              child: Icon(
                icon,
                color: unlocked ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: unlocked
                    ? Theme.of(context).extension<LiquidColors>()!.textTitle
                    : Theme.of(context).extension<LiquidColors>()!.textCaption,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsGrid(BuildContext context) {
    final collections = [
      ("Weather Scripts", Icons.cloud_rounded, _weatherCount, LiquidTheme.cyan),
      (
        "Productivity",
        Icons.task_alt_rounded,
        _productivityCount,
        LiquidTheme.primary,
      ),
      (
        "Widget Scripts",
        Icons.widgets_rounded,
        _widgetCount,
        const Color(0xFF10B981),
      ),
      (
        "All Scripts",
        Icons.folder_rounded,
        _scriptCount,
        const Color(0xFFEC4899),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: collections.map((c) {
          return GestureDetector(
            onTap: () {
              // Collections are informational in V1
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.$4.withValues(alpha: 0.15),
                    c.$4.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.$4.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(c.$2, color: c.$4, size: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(
                            context,
                          ).extension<LiquidColors>()!.textTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${c.$3} scripts",
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .extension<LiquidColors>()!
                              .textCaption
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final extension = p.extension(pickedFile.path);
      final filename =
          'avatar_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedImage = await File(
        pickedFile.path,
      ).copy('${appDir.path}/$filename');

      await GetIt.I<UserPreferencesService>().setAvatarPath(savedImage.path);
      if (mounted) {
        setState(() => _avatarPath = savedImage.path);
      }
    }
  }
}

class _BadgeData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool unlocked;
  const _BadgeData(
    this.icon,
    this.title,
    this.subtitle,
    this.color, {
    this.unlocked = false,
  });
}

class _ProfileCollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final String displayName;
  final String bio;
  final String? avatarPath;
  final String? email;
  final VoidCallback onEditProfile;
  final VoidCallback onPickAvatar;

  _ProfileCollapsingHeaderDelegate({
    required this.topPadding,
    required this.displayName,
    required this.bio,
    required this.avatarPath,
    required this.email,
    required this.onEditProfile,
    required this.onPickAvatar,
  });

  @override
  double get minExtent => topPadding + 70;

  @override
  double get maxExtent => topPadding + 280;

  @override
  bool shouldRebuild(covariant _ProfileCollapsingHeaderDelegate old) {
    return old.displayName != displayName ||
        old.bio != bio ||
        old.avatarPath != avatarPath ||
        old.email != email;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final double percent = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );
    final bool isScrolled = shrinkOffset > 0;

    // Fast fade out for expanded-only elements (Email, Bio, Edit Button)
    final double fadeOutOpacity = (1.0 - (percent * 2)).clamp(0.0, 1.0);

    // Fade in for the small edit button on the pinned header?
    // Wait, Edit button was always visible in the expanded, but we have GlassHeaderActions always pinned.

    // Calculate Interpolated Positions
    final double avatarSize = lerpDouble(88, 40, percent)!;
    final double avatarTop = lerpDouble(
      topPadding + 96,
      topPadding + 15,
      percent,
    )!;

    final double nameTop = lerpDouble(
      topPadding + 196,
      topPadding + 24,
      percent,
    )!;
    final double nameLeft = lerpDouble(24, 76, percent)!;
    final double nameFontSize = lerpDouble(24, 18, percent)!;

    // Elements that scroll up naturally
    final double coverTop = -shrinkOffset;
    final double editButtonTop = topPadding + 150 - shrinkOffset;
    final double emailTop = topPadding + 230 - shrinkOffset;
    final double bioTop = topPadding + 252 - shrinkOffset;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 20.0 : 0.0,
          sigmaY: isScrolled ? 20.0 : 0.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isScrolled ? colors.glassOverlay : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isScrolled ? colors.glassBorder : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Cover Photo (Scrolls up and fades out slightly)
              Positioned(
                top: coverTop,
                left: 0,
                right: 0,
                height: topPadding + 140,
                child: Opacity(
                  opacity: fadeOutOpacity,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2000&auto=format&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Morphing Avatar
              Positioned(
                top: avatarTop,
                left: 24,
                child: _buildAvatar(
                  context,
                  size: avatarSize,
                  onPickAvatar: onPickAvatar,
                  avatarPath: avatarPath,
                  hideEditBadge:
                      percent > 0.5, // Hide badge when it becomes small
                ),
              ),

              // 3. Edit Profile Button (Fades out and scrolls up)
              if (fadeOutOpacity > 0)
                Positioned(
                  top: editButtonTop,
                  right: 24,
                  child: Opacity(
                    opacity: fadeOutOpacity,
                    child: GestureDetector(
                      onTap: onEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "Edit profile",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Morphing Name
              Positioned(
                top: nameTop,
                left: nameLeft,
                right: 90, // Prevent overlapping with right actions
                child: Text(
                  displayName.isEmpty ? 'Guest User' : displayName,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w900,
                    color: colors.textTitle,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 5. Email (Fades out and scrolls up)
              if (fadeOutOpacity > 0 && email != null && email!.isNotEmpty)
                Positioned(
                  top: emailTop,
                  left: 24,
                  right: 24,
                  child: Opacity(
                    opacity: fadeOutOpacity,
                    child: Text(
                      email!,
                      style: TextStyle(
                        fontSize: 14,
                        color: LiquidTheme.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // 6. Bio (Fades out and scrolls up)
              if (fadeOutOpacity > 0 && bio.isNotEmpty)
                Positioned(
                  top: bioTop,
                  left: 24,
                  right: 24,
                  child: Opacity(
                    opacity: fadeOutOpacity,
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textBody,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // 7. Pinned Actions (Top Right)
              Positioned(
                top: topPadding + 8,
                right: 24,
                child: const GlassHeaderActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context, {
    required double size,
    required VoidCallback? onPickAvatar,
    required String? avatarPath,
    bool hideEditBadge = false,
  }) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [LiquidTheme.primary, LiquidTheme.cyan],
            ),
            boxShadow: [
              if (!hideEditBadge)
                BoxShadow(
                  color: LiquidTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: GestureDetector(
            onTap: onPickAvatar,
            child: Padding(
              padding: EdgeInsets.all(size > 50 ? 3.0 : 2.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.sheetBackground,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarPath != null && File(avatarPath).existsSync()
                    ? Image.file(File(avatarPath), fit: BoxFit.cover)
                    : Icon(
                        Icons.person_rounded,
                        size: size * 0.5,
                        color: LiquidTheme.primary,
                      ),
              ),
            ),
          ),
        ),
        if (!hideEditBadge && onPickAvatar != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onPickAvatar,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: colors.textTitle,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.sheetBackground, width: 2),
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  size: size * 0.18,
                  color: colors.sheetBackground,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
