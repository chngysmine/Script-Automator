import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, String>>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = GetIt.I<GalleryRepository>().getTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Script Gallery",
          style: LiquidTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: LiquidTheme.textDeep,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LiquidTheme.textDeep),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LiquidTheme.auroraGradient),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: FutureBuilder<List<Map<String, String>>>(
              future: _templatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: LiquidTheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Failed to load gallery",
                      style: TextStyle(color: Colors.red[400]),
                    ),
                  );
                }

                final templates = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final item = templates[index];
                    return _buildGlassCard(context, item);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showPreview(context, item),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LiquidTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.widgets_rounded,
                        color: LiquidTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(
                                0xFF4B5563,
                              ).withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showPreview(context, item),
                      child: const Text("Preview Code"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LiquidTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _installScript(context, item),
                      child: const Text("Install"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                item['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    item['content']!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFE5E7EB),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LiquidTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _installScript(context, item);
                    },
                    child: const Text(
                      "Install Script",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _installScript(
    BuildContext context,
    Map<String, String> item,
  ) async {
    final repo = GetIt.I<ScriptRepository>();
    final script = Script(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item['name']!,
      content: item['content']!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.saveScript(script);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Installed ${item['name']}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: LiquidTheme.primary,
        ),
      );
    }
  }
}
