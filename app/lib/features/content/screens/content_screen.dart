import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../audio/providers/audio_provider.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _categories = ['All', 'Nature', 'Binaural', 'Breathing', 'Guided'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(audioTracksProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Content Library',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          
                        )),
                    const SizedBox(height: 4),
                    const Text('Real soundscapes & guided sessions',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          
                        )),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabCtrl,
                      isScrollable: true,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        
                        fontSize: 13,
                      ),
                      indicatorColor: AppTheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: _categories.map((c) => Tab(text: c)).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tracksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: AppTheme.accentWarm)),
                  ),
                  data: (tracks) => TabBarView(
                    controller: _tabCtrl,
                    children: _categories.map((cat) {
                      final filtered = cat == 'All'
                          ? tracks
                          : tracks.where((t) =>
                              (t['category'] as String).toLowerCase() ==
                              cat.toLowerCase()).toList();
                      return _TrackGrid(tracks: filtered);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackGrid extends ConsumerWidget {
  final List<Map<String, dynamic>> tracks;
  const _TrackGrid({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text('No tracks in this category',
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Inter')),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) => _TrackCard(track: tracks[i]),
    );
  }
}

class _TrackCard extends ConsumerWidget {
  final Map<String, dynamic> track;
  const _TrackCard({required this.track});

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = track['category'] as String? ?? '';
    final catColor = _catColor(cat);

    return GestureDetector(
      onTap: () => context.push('/audio', extra: track),
      child: Container(
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
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: track['thumbnail_url'] as String? ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: catColor.withOpacity(0.15),
                      child: Icon(
                        _catIcon(cat),
                        color: catColor,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['title'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 11, color: catColor),
                      const SizedBox(width: 3),
                      Text(
                        _formatDuration(track['duration_seconds'] as int?),
                        style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'nature':    return AppTheme.stressLow;
      case 'binaural':  return AppTheme.primary;
      case 'breathing': return AppTheme.accent;
      case 'guided':    return AppTheme.stressMed;
      default:          return AppTheme.textSecondary;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'nature':    return Icons.park_outlined;
      case 'binaural':  return Icons.graphic_eq;
      case 'breathing': return Icons.air;
      case 'guided':    return Icons.self_improvement;
      default:          return Icons.music_note;
    }
  }
}


