import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../scan/providers/scan_provider.dart';
import '../../audio/providers/audio_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final recentScans = ref.watch(recentScansProvider);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _buildPointsTip(context, ref),
                const SizedBox(height: 24),
                _buildScanCard(context),
                const SizedBox(height: 24),
                _buildLastScan(recentScans),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecommendedAudio(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(profileStreamProvider).value;
    
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

    final stats = ref.watch(userStatsProvider).value ?? const UserStats();

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      snap: false,
      backgroundColor: AppTheme.bg,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$_greeting,',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              
                            ),
                          ),
                        ],
                      ),
              ),
              // Points badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppTheme.accentWarm, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${stats.totalPoints} pts',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/scan'),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGrad,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Stress Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to scan your stress level now',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastScan(AsyncValue<List<Map<String, dynamic>>> recentScans) {
    return recentScans.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (scans) {
        if (scans.isEmpty) return const SizedBox.shrink();
        final last  = scans.first;
        final score = (last['stress_score'] as num).toDouble();
        final level = last['stress_level'] as String? ?? 'medium';
        final color = level == 'high'
            ? AppTheme.stressHigh
            : level == 'medium'
                ? AppTheme.stressMed
                : AppTheme.stressLow;
        final emotion  = last['dominant_emotion'] as String? ?? '';
        final dateStr  = DateFormat.yMMMd().format(
          DateTime.parse(last['scanned_at']).toLocal(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last Scan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 5,
                          backgroundColor: color.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text(
                        '${score.toInt()}',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${level[0].toUpperCase()}${level.substring(1)} Stress',
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            
                          ),
                        ),
                        Text(
                          'Emotion: ${emotion[0].toUpperCase()}${emotion.substring(1)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (icon: Icons.air, label: 'Breathe', color: AppTheme.accent, route: '/breathe'),
      (icon: Icons.headphones, label: 'Listen', color: AppTheme.primary, route: '/content'),
      (icon: Icons.edit_note, label: 'Journal', color: AppTheme.accentWarm, route: '/journal'),
      (icon: Icons.bar_chart, label: 'Progress', color: const Color(0xFFFFB347), route: '/progress'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              
            )),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _QuickActionCard(
                        icon: a.icon,
                        label: a.label,
                        color: a.color,
                        onTap: () {
                          // Push-style routes need push() so back-swipe works
                          if (a.route == '/breathe' || a.route == '/journal') {
                            context.push(a.route);
                          } else {
                            context.go(a.route);
                          }
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendedAudio(BuildContext context) {
    final tracks = ref.watch(audioTracksProvider);
    return tracks.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommended',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      
                    )),
                TextButton(
                  onPressed: () => context.go('/content'),
                  child: const Text('See all',
                      style: TextStyle(color: AppTheme.primary, fontFamily: 'Inter')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final track = list[i];
                  return _AudioCard(track: track);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsTip(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pointsTipStatusProvider);
    return status.when(
      data: (hasSeen) {
        if (hasSeen) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('What are Points?',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await OnboardingService.markPointsTipSeen();
                      ref.invalidate(pointsTipStatusProvider);
                    },
                    child: Icon(Icons.close_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Earn points by completing stress scans, journaling your thoughts, or relaxing with mindfulness audio. Turn your mental wellness into visible progress!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5, fontFamily: 'Inter'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioCard extends ConsumerWidget {
  final Map<String, dynamic> track;
  const _AudioCard({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/audio', extra: track),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                track['thumbnail_url'] ?? '',
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: AppTheme.surfaceHigh,
                  child: const Icon(Icons.music_note, color: AppTheme.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                track['title'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
