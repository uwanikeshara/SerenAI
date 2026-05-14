import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/onboarding_provider.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    // Request Camera & Notifications
    await [
      Permission.camera,
      Permission.notification,
    ].request();

    // Save flag that we've asked
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);
    
    // Invalidate the provider so the router rebuilds its state
    ref.invalidate(permissionsStatusProvider);

    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Before we start',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SerenAI needs a few permissions to provide you with the best experience. We value your privacy and only ask for what is strictly necessary.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Permission List
                _PermissionItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  desc: 'Used legally and securely to scan your face for stress analysis. No images are saved or transmitted.',
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 24),
                _PermissionItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  desc: 'Receive gentle reminders to check in on your stress levels and practice mindfulness.',
                  color: AppTheme.primary,
                ),

                const Spacer(),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _requestPermissions(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_permissions', true);
                    ref.invalidate(permissionsStatusProvider);
                    if (context.mounted) context.go('/home');
                  },
                  child: const Text('Not Now',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
