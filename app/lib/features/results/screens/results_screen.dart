import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/local_db.dart';
import '../../../ml/inference_engine.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> scanData;
  const ResultsScreen({super.key, required this.scanData});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scoreAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final score = (widget.scanData['stress_score'] as num?)?.toDouble() ?? 0;
    _scoreAnim = Tween<double>(begin: 0, end: score / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    _saveScan();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveScan() async {
    if (_saved) return;
    _saved = true;

    final score    = (widget.scanData['stress_score'] as num?)?.toDouble() ?? 0;
    final level    = widget.scanData['stress_level'] as String? ?? 'medium';
    final emotion  = widget.scanData['dominant_emotion'] as String? ?? 'neutral';
    final probs    = widget.scanData['emotion_probs'] as List<double>? ?? [];
    final uid      = Supabase.instance.client.auth.currentUser?.id;
    final id       = const Uuid().v4();
    final now      = DateTime.now();

    // Save locally first
    final db = ref.read(localDbProvider);
    await db.insertScan(LocalScansCompanion(
      id:              drift.Value(id),
      stressScore:     drift.Value(score),
      stressLevel:     drift.Value(level),
      dominantEmotion: drift.Value(emotion),
      emotionProbs:    drift.Value(jsonEncode(probs)),
      scannedAt:       drift.Value(now),
    ));

    // Sync to Supabase
    if (uid != null) {
      try {
        await Supabase.instance.client.from('stress_scans').insert({
          'id':                   id,
          'user_id':              uid,
          'stress_score':         score,
          'stress_level':         level,
          'dominant_emotion':     emotion,
          'emotion_probabilities': Map.fromIterables(
            emotionLabels,
            probs.map((p) => double.parse(p.toStringAsFixed(4))),
          ),
          'scanned_at':           now.toIso8601String(),
        });
        await db.markScanSynced(id);

        // Award points
        await Supabase.instance.client.from('gamification_events').insert({
          'user_id':    uid,
          'event_type': 'scan_complete',
          'points':     10,
        });
        // Profile points are updated via the gamification_events trigger in Supabase
      } catch (_) {
        // Will retry on next sync
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final score   = (widget.scanData['stress_score'] as num?)?.toDouble() ?? 0;
    final level   = widget.scanData['stress_level'] as String? ?? 'medium';
    final emotion = widget.scanData['dominant_emotion'] as String? ?? 'neutral';
    final probs   = widget.scanData['emotion_probs'] as List<double>? ?? [];
    final color   = level == 'high'
        ? AppTheme.stressHigh
        : level == 'medium'
            ? AppTheme.stressMed
            : AppTheme.stressLow;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
                  onPressed: () => context.go('/home'),
                ),
                title: const Text('Scan Results',
                    style: TextStyle(color: AppTheme.textPrimary,  fontWeight: FontWeight.w700)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Animated stress gauge
                    _StressGauge(animation: _scoreAnim, color: color, score: score),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${level[0].toUpperCase()}${level.substring(1)} Stress',
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Dominant: ${emotion[0].toUpperCase()}${emotion.substring(1)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Emotion breakdown
                    if (probs.isNotEmpty) _EmotionBars(probs: probs),
                    const SizedBox(height: 32),
                    // Recommendations
                    _RecommendationSection(stressLevel: level),
                    const SizedBox(height: 24),
                    // Journal prompt
                    _JournalPromptCard(stressLevel: level),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StressGauge extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double score;

  const _StressGauge({
    required this.animation,
    required this.color,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _GaugePainter(animation.value, color),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(animation.value * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: color,
                      
                    ),
                  ),
                  const Text(
                    'stress score',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final startAngle = math.pi * 0.75;
    final sweepAngle = math.pi * 1.5;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppTheme.surfaceHigh
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, color == AppTheme.stressHigh ? 6 : 3),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

class _EmotionBars extends StatelessWidget {
  final List<double> probs;
  const _EmotionBars({required this.probs});

  @override
  Widget build(BuildContext context) {
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
          const Text('Emotion Breakdown',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                
              )),
          const SizedBox(height: 16),
          ...List.generate(
            emotionLabels.length,
            (i) {
              if (i >= probs.length) return const SizedBox.shrink();
              final label = emotionLabels[i];
              final pct   = probs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${label[0].toUpperCase()}${label.substring(1)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppTheme.surfaceHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(_emotionColor(label)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _emotionColor(String label) {
    switch (label) {
      case 'angry':    return AppTheme.stressHigh;
      case 'fear':     return const Color(0xFFCC55FF);
      case 'disgust':  return const Color(0xFFFF8C42);
      case 'sad':      return const Color(0xFF5B9BFF);
      case 'neutral':  return AppTheme.stressMed;
      case 'happy':    return AppTheme.stressLow;
      case 'surprise': return const Color(0xFFFFD93D);
      default:         return AppTheme.textSecondary;
    }
  }
}

class _RecommendationSection extends StatelessWidget {
  final String stressLevel;
  const _RecommendationSection({required this.stressLevel});

  @override
  Widget build(BuildContext context) {
    final recs = _getRecommendations(stressLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended For You',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              
            )),
        const SizedBox(height: 12),
        ...recs.map((r) => _RecCard(rec: r)),
      ],
    );
  }

  List<Map<String, dynamic>> _getRecommendations(String level) {
    if (level == 'high') {
      return [
        {'route': '/breathe', 'icon': Icons.air, 'title': 'Box Breathing', 'desc': 'Inhale 4s → Hold 4s → Exhale 4s → Hold 4s', 'color': AppTheme.accent},
        {'route': '/content', 'icon': Icons.water_drop, 'title': 'Cold Water Splash', 'desc': 'Activate dive reflex for instant calm', 'color': AppTheme.primary},
        {'route': '/journal', 'icon': Icons.edit_note, 'title': 'Write It Out', 'desc': 'Journal what you\'re feeling right now', 'color': AppTheme.accentWarm},
      ];
    } else if (level == 'medium') {
      return [
        {'route': '/content', 'icon': Icons.headphones, 'title': 'Nature Soundscape', 'desc': 'Calming rain or ocean sounds', 'color': AppTheme.primary},
        {'route': '/content', 'icon': Icons.psychology, 'title': '5-4-3-2-1 Grounding', 'desc': 'Name 5 things you see, 4 you hear...', 'color': AppTheme.accent},
        {'route': '/content', 'icon': Icons.accessibility_new, 'title': 'Neck Stretches', 'desc': 'Release tension with gentle rolls', 'color': AppTheme.stressMed},
      ];
    } else {
      return [
        {'route': '/journal', 'icon': Icons.favorite, 'title': 'Gratitude Moment', 'desc': 'Write 3 things you\'re grateful for', 'color': AppTheme.stressLow},
        {'route': '/content', 'icon': Icons.graphic_eq, 'title': 'Alpha Binaural', 'desc': 'Listen for calm focus', 'color': AppTheme.primary},
      ];
    }
  }
}

class _RecCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  const _RecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = rec['color'] as Color;
    final route = rec['route'] as String?;
    return GestureDetector(
      onTap: () {
        if (route != null) {
          if (route == '/breathe' || route == '/journal') {
            context.push(route);
          } else {
            context.go(route);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(rec['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec['title'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        
                      )),
                  Text(rec['desc'] as String,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

class _JournalPromptCard extends StatelessWidget {
  final String stressLevel;
  const _JournalPromptCard({required this.stressLevel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/journal'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1838), Color(0xFF241C3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_note, color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How are you feeling?',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        
                      )),
                  const SizedBox(height: 4),
                  Text(
                    stressLevel == 'high'
                        ? 'Write about what\'s troubling you'
                        : 'Capture this moment in your journal',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.primary, size: 14),
          ],
        ),
      ),
    );
  }
}
