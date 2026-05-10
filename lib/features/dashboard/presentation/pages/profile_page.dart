import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/edit_profile_sheet.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';
import 'package:script_automator/features/dashboard/data/services/user_stats_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/glass_header_actions.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:script_automator/core/ui/glass_sliver_header.dart';

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
  int _totalRuns = 0;
  bool _loaded = false;

  String _displayName = 'My Workspace';
  String _bio = 'Widget automation workspace';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final result = await GetIt.I<ScriptRepository>().getScripts();
    result.fold(
      (failure) => setState(() => _loaded = true),
      (scripts) => setState(() {
        _scriptCount = scripts.length;
        _widgetCount = scripts
            .where((s) => s.content.contains('renderWidget'))
            .length;
        _loaded = true;
      }),
    );

    final prefs = GetIt.I<UserPreferencesService>();
    final name = await prefs.displayName;
    final b = await prefs.bio;
    final ap = await prefs.avatarPath;

    int totalRuns = 0;
    if (GetIt.I.isRegistered<UserStatsService>()) {
      totalRuns = await GetIt.I<UserStatsService>().get('total_runs');
    }

    if (mounted) {
      setState(() {
        _displayName = name;
        _bio = b;
        _totalRuns = totalRuns;
        _avatarPath = ap;
      });
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
        // ── Pinned Glass Header: Avatar + Name + Actions (fixed, NO collapse) ──
        SliverPersistentHeader(
          pinned: true,
          delegate: GlassSliverHeaderDelegate(
            height: topPadding + 100,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: _buildProfileHeaderRow(context),
              ),
            ),
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
                const SizedBox(height: 12),
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

  /// The avatar + name + actions row used as pinned header content.
  Widget _buildProfileHeaderRow(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [LiquidTheme.primary, LiquidTheme.cyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: LiquidTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).extension<LiquidColors>()!.sheetBackground,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _avatarPath != null && File(_avatarPath!).existsSync()
                        ? Image.file(
                            File(_avatarPath!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: LiquidTheme.primary,
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => _openEditProfile(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: LiquidTheme.textDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Name + Stats
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).extension<LiquidColors>()!.textTitle,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _loaded
                    ? "$_scriptCount scripts · $_widgetCount widgets"
                    : "Loading...",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LiquidTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        // Actions
        StreamBuilder<int>(
          stream: GetIt.I<NotificationService>().unreadCount,
          builder: (context, snapshot) {
            return GlassHeaderActions(
              hasNotificationBadge: (snapshot.data ?? 0) > 0,
            );
          },
        ),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileSheet(
        currentName: _displayName,
        currentBio: _bio,
      ),
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
            child: _buildStatCard(
              _loaded ? "$_scriptCount" : "-",
              "Scripts\nCreated",
              LiquidTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              _loaded ? "$_widgetCount" : "-",
              "Widgets\nDeployed",
              LiquidTheme.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              _loaded ? "$_totalRuns" : "-",
              "Total\nRuns",
              const Color(0xFFEC4899),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: LiquidTheme.textMedium,
              height: 1.3,
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LiquidTheme.textDeep,
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
        // Build the 52-week x 7-day grid
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
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
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
                                color: LiquidTheme.textLight.withValues(
                                  alpha: 0.6,
                                ),
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
                                      final intensity = count == 0
                                          ? 0.0
                                          : (count / maxVal).clamp(0.15, 1.0);

                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: count == 0
                                              ? const Color(0xFFE8ECF4)
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
                                : LiquidTheme.textLight.withValues(alpha: 0.6),
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
                            color: LiquidTheme.textLight.withValues(alpha: 0.6),
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
                            color: LiquidTheme.textLight.withValues(alpha: 0.6),
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
            "10 widgets deployed",
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
            backgroundColor: LiquidTheme.textDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(icon, color: unlocked ? color : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              unlocked ? "Unlocked: $subtitle." : "Locked. Goal: $subtitle.",
              style: const TextStyle(color: Colors.white70),
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
                color: unlocked ? LiquidTheme.textDeep : LiquidTheme.textLight,
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
      ("Weather Scripts", Icons.cloud_rounded, _widgetCount, LiquidTheme.cyan),
      (
        "Productivity",
        Icons.task_alt_rounded,
        _scriptCount > 0
            ? (_scriptCount - _widgetCount).clamp(0, _scriptCount)
            : 0,
        LiquidTheme.primary,
      ),
      (
        "Deployed Widgets",
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
                    c.$4.withValues(alpha: 0.12),
                    c.$4.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LiquidTheme.textDeep,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${c.$3} scripts",
                        style: TextStyle(
                          fontSize: 11,
                          color: LiquidTheme.textLight.withValues(alpha: 0.7),
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final extension = p.extension(pickedFile.path);
      final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$filename');
      
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
