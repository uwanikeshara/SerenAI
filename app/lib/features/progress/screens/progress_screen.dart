import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/theme/app_theme.dart';

import '../../../core/database/local_db.dart';

final progressDataProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(localDbProvider);
  
  // 1. Reactive Watch on Local DB (Instant Offline Experience)
  return db.watchRecentScans().map((list) {
    return list.map((s) => {
      'id': s.id,
      'stress_score': s.stressScore,
      'stress_level': s.stressLevel,
      'dominant_emotion': s.dominantEmotion,
      'scanned_at': s.scannedAt.toIso8601String(),
    }).toList();
  });
});

// background silent sync provider
final syncStatusProvider = FutureProvider<void>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;

  final db = ref.read(localDbProvider);

  try {
    // 2. Clear out local data older than 7 days
    await db.purgeOldScans();

    // 3. Pull latest 7 days from Supabase and upsert local cache
    final data = await Supabase.instance.client
        .from('stress_scans')
        .select()
        .eq('user_id', uid)
        .order('scanned_at', ascending: false);

    for (final row in data) {
      await db.insertScan(LocalScansCompanion.insert(
        id: row['id'],
        stressScore: (row['stress_score'] as num).toDouble(),
        stressLevel: row['stress_level'],
        dominantEmotion: row['dominant_emotion'],
        emotionProbs: row['emotion_probs'] ?? '',
        scannedAt: DateTime.parse(row['scanned_at']),
        synced: const Value(true),
      ));
    }
  } catch (_) {
    // Fail silently in background sync — UI still has local cache
  }
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(progressDataProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: scansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (err, _) {
              // If we have an error but the provider is still showing local cached data,
              // we ignore it. The 'Retry' screen is now removed to ensure high signal resilience.
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            },
            data: (scans) {
              // Trigger a background sync every time we view the screen
              ref.read(syncStatusProvider);
              
              if (scans.isEmpty) return _buildEmpty();
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text('Progress',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          )),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatsRow(scans),
                        const SizedBox(height: 32),
                        _buildStressTrendChart(scans),
                        const SizedBox(height: 32),
                        _buildEmotionDistribution(scans),
                        const SizedBox(height: 32),
                        _buildScanHistory(context, scans),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.textSecondary, size: 60),
            SizedBox(height: 16),
            Text('No scans yet',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  
                )),
            SizedBox(height: 8),
            Text('Complete your first stress scan to see your progress here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<Map<String, dynamic>> scans) {
    final avg = scans.map((s) => (s['stress_score'] as num).toDouble()).reduce((a, b) => a + b) / scans.length;
    final highCount = scans.where((s) => s['stress_level'] == 'high').length;
    final lowCount  = scans.where((s) => s['stress_level'] == 'low').length;
    return Row(
      children: [
        _StatCard(
          label: 'Avg Stress',
          value: avg.toStringAsFixed(0),
          icon: Icons.trending_up_rounded,
          color: AppTheme.stressMed,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'High Stress',
          value: '$highCount',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.stressHigh,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Low Stress',
          value: '$lowCount',
          icon: Icons.check_circle_outline,
          color: AppTheme.stressLow,
        ),
      ],
    );
  }

  Widget _buildStressTrendChart(List<Map<String, dynamic>> scans) {
    final reversed = scans.reversed.toList();
    final spots = reversed.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['stress_score'] as num).toDouble());
    }).toList();

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
          const Text('Stress Trend',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                
              )),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution(List<Map<String, dynamic>> scans) {
    final emotionCounts = <String, int>{};
    for (final s in scans) {
      final e = s['dominant_emotion'] as String? ?? 'neutral';
      emotionCounts[e] = (emotionCounts[e] ?? 0) + 1;
    }
    final total = scans.length;
    final colors = [
      AppTheme.stressHigh, AppTheme.primary, const Color(0xFFCC55FF),
      AppTheme.stressLow,  AppTheme.stressMed, const Color(0xFFFFD93D),
      const Color(0xFF5B9BFF),
    ];
    int ci = 0;
    final sections = emotionCounts.entries.map((e) {
      final color = colors[ci++ % colors.length];
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${((e.value / total) * 100).toInt()}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          
        ),
      );
    }).toList();

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
          const Text('Emotion Distribution',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(sections: sections, sectionsSpace: 2)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: (){
              int ci2 = 0;
              return emotionCounts.entries.map((e) {
                final color = colors[ci2++ % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('${e.key[0].toUpperCase()}${e.key.substring(1)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          
                        )),
                  ],
                );
              }).toList();
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistory(BuildContext context, List<Map<String, dynamic>> scans) {
    final recentScans = scans.take(4).toList();
    final hasMore = scans.length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scan History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
            if (hasMore)
              TextButton(
                onPressed: () => _showAllScans(context, scans),
                child: const Text('See All',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentScans.map((s) => _buildScanItem(s)),
        if (scans.isEmpty)
           const Center(
             child: Padding(
               padding: EdgeInsets.only(top: 20),
               child: Text('No scans in the last 7 days', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
             ),
           ),
      ],
    );
  }

  Widget _buildScanItem(Map<String, dynamic> s) {
    final score  = (s['stress_score'] as num).toDouble();
    final level  = s['stress_level'] as String? ?? 'medium';
    final color  = level == 'high' ? AppTheme.stressHigh
        : level == 'medium' ? AppTheme.stressMed : AppTheme.stressLow;
    
    // Smooth time parsing using native toLocal() for Sri Lankan / User Region accuracy
    final date   = DateFormat.yMMMd().add_jm().format(
      DateTime.parse(s['scanned_at']).toLocal(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                score.toInt().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${level[0].toUpperCase()}${level.substring(1)} Stress',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            s['dominant_emotion'] as String? ?? '',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAllScans(BuildContext context, List<Map<String, dynamic>> scans) {
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
            const Text('Past 7 Days History',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: scans.length,
                itemBuilder: (ctx, i) => _buildScanItem(scans[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  
                )),
            Text(label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
