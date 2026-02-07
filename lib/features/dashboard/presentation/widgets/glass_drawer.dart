import 'package:flutter/material.dart';
import 'dart:ui';

class GlassDrawer extends StatelessWidget {
  const GlassDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 280,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Profile Header
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://i. Pravatar.cc/300",
                              ), // Placeholder
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "CodeForge User",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          "Pro Member",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  _buildDrawerItem(Icons.settings_rounded, "Settings"),
                  _buildDrawerItem(Icons.cloud_sync_rounded, "Sync Status"),
                  _buildDrawerItem(Icons.extension_rounded, "Extensions"),
                  _buildDrawerItem(Icons.history_rounded, "History"),

                  const Spacer(),

                  _buildDrawerItem(
                    Icons.logout_rounded,
                    "Log Out",
                    isDestructive: true,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF1E293B),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      onTap: () {},
    );
  }
}
