import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/providers/user_provider.dart';

final gamificationEventsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return Stream.value([]);
  return Supabase.instance.client
      .from('gamification_events')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .order('earned_at', ascending: false)
      .limit(20)
      .map((data) => data.map((e) => Map<String, dynamic>.from(e)).toList());
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStreamProvider);
    final gamificAsync = ref.watch(gamificationEventsProvider);
    final stats        = ref.watch(userStatsProvider).value ?? const UserStats();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileCard(
                      context, 
                      ref, 
                      profileAsync.valueOrNull, 
                      stats
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildGamificationCard(context, gamificAsync),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildAchievements(stats),
                    const SizedBox(height: 24),
                    _buildSettings(context, ref),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, Map<String, dynamic>? profile, UserStats stats) {
    final user  = Supabase.instance.client.auth.currentUser;
    
    String name = 'Friend';
    final customName = profile?['username'] as String?;
    
    // 1. Priotise explicit profile username if they edited it
    if (customName != null && customName.trim().isNotEmpty) {
      name = customName.trim();
    } else {
      // 2. Fallback to Full Name meta
      final metaName = user?.userMetadata?['full_name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        final first = metaName.split(' ').first.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (first.isNotEmpty) name = first[0].toUpperCase() + first.substring(1);
      } else {
        // 3. Fallback to email
        final rawEmail = user?.email?.split('@').first ?? 'Friend';
        final first = rawEmail.split(' ').first.replaceAll(RegExp(r'[0-9]'), '');
        if (first.isNotEmpty) name = first[0].toUpperCase() + first.substring(1);
      }
    }
    
    final email = user?.email ?? '';
    final pts   = stats.totalPoints;
    final streak = profile?['streak_count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGrad,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditNameDialog(context, ref, name),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          Text(email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                
              )),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStat(value: '$pts', label: 'Points', icon: Icons.star_rounded),
              Container(width: 1, height: 40, color: Colors.white24),
              _ProfileStat(value: '$streak', label: 'Streak', icon: Icons.local_fire_department_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context, AsyncValue<List<Map<String, dynamic>>> gamificAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
              gamificAsync.when(
                data: (events) => events.length > 4 
                    ? TextButton(
                        onPressed: () => _showAllActivities(context, events),
                        child: const Text('See All',
                            style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          gamificAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (_, __) => const SizedBox.shrink(),
            data: (events) {
              if (events.isEmpty) {
                return const Text('Complete your first scan to earn points!',
                    style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Inter'));
              }
              return Column(
                children: events.take(4).map((e) => _buildActivityItem(e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> e) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.star_rounded, color: AppTheme.primary, size: 18),
      ),
      title: Text(
        _formatEventType(e['event_type'] as String? ?? ''),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      ),
      trailing: Text(
        '+${e['points']} pts',
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAllActivities(BuildContext context, List<Map<String, dynamic>> events) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('All Activity History',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: events.length,
                itemBuilder: (ctx, i) => _buildActivityItem(events[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAchievements(UserStats stats) {
    final achievements = [
      (icon: '🎯', title: 'First Scan',       desc: 'Completed your first stress scan', unlocked: stats.totalScans > 0),
      (icon: '🔥', title: '7-Day Streak',     desc: 'Used SerenAI 7 days in a row',     unlocked: stats.currentStreak >= 7),
      (icon: '🧘', title: 'Mindful Minute',   desc: 'Listened to 60 min of audio',      unlocked: stats.totalAudioMinutes >= 60),
      (icon: '📓', title: 'Journaling Habit', desc: 'Written 10 journal entries',       unlocked: stats.totalJournals >= 10),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Achievements',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              
            )),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: achievements.map((a) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: a.unlocked ? AppTheme.primary : AppTheme.divider),
            ),
            child: Opacity(
              opacity: a.unlocked ? 1.0 : 0.4,
              child: Row(
                children: [
                  Text(a.icon, style: TextStyle(fontSize: 24, color: !a.unlocked ? Colors.grey : null)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              
                            )),
                        Text(a.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                              
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => _showNotificationsDialog(context),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'About SerenAI',
                onTap: () => _showAbout(context),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: AppTheme.accentWarm,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your new name',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({'username': newName})
                      .eq('id', uid);
                  
                  // Instantly invalidate the local provider cache to force a UI rebuild
                  ref.invalidate(profileStreamProvider);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text('Notifications',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'SerenAI currently sends you daily reminders to scan your stress and practice mindfulness. You established these permissions during your first launch.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => CustomScrollView(
          controller: ctrl,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Privacy Policy',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ..._privacySections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$1, style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(s.$2, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
                      ],
                    ),
                  )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.self_improvement, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            const Text('SerenAI',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            const Text(
              'SerenAI uses completely secure, local on-device machine learning algorithms to detect stress through abstract facial layouts. No image data is ever transmitted out of your device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Built with privacy-first architecture.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to sign out? Your data will remain saved.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentWarm,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  static const _privacySections = [
    ('Data Collection', 'SerenAI collects facial scan data processed entirely on your device. We store stress scores, emotion labels, and journal entries in your personal Supabase account. No raw images or video are ever stored.'),
    ('Data Usage', 'Your data is used solely to display your personal progress and provide personalised recommendations. We do not sell or share your data with third parties.'),
    ('Security', 'All data is encrypted in transit via HTTPS. Your account is protected by Supabase Auth with email/password authentication.'),
    ('Your Rights', 'You may delete your account and all associated data at any time by contacting support. Deleting your account permanently removes all stored scan results, journal entries, and profile information.'),
    ('Contact', 'For privacy questions, contact: privacy@serenai.app'),
  ];


  String _formatEventType(String type) {
    switch (type) {
      case 'scan_complete': return 'Completed a stress scan';
      case 'journal_entry': return 'Added journal entry';
      case 'audio_session': return 'Completed audio session';
      default:              return type.replaceAll('_', ' ');
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _ProfileStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              
            )),
        Text(label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              
            )),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            
          )),
      trailing: Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
      onTap: onTap,
    );
  }
}
