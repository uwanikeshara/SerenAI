import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> trackData;
  const AudioPlayerScreen({super.key, required this.trackData});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  double _currentVolume = 0.5;
  StreamSubscription<double>? _volumeSub;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Keep screen on while player is open
    WakelockPlus.enable();

    // Volume controller setup
    FlutterVolumeController.updateShowSystemUI(false);
    FlutterVolumeController.getVolume().then((v) {
      if (mounted && v != null) setState(() => _currentVolume = v);
    });
    
    _volumeSub = FlutterVolumeController.addListener((volume) {
      if (mounted && volume != _currentVolume) {
        setState(() => _currentVolume = volume);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerProvider.notifier).playTrack(widget.trackData);
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _volumeSub?.cancel();
    FlutterVolumeController.updateShowSystemUI(true);
    WakelockPlus.disable();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioPlayerProvider);
    final track = audio.currentTrack ?? widget.trackData;
    final cat   = track['category'] as String? ?? 'nature';

    final progress = audio.duration.inMilliseconds > 0
        ? (audio.position.inMilliseconds / audio.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // Keep spinning when playing
    if (audio.isPlaying && !_spinCtrl.isAnimating) _spinCtrl.repeat();
    if (!audio.isPlaying && _spinCtrl.isAnimating) _spinCtrl.stop();

    final catColor = _catColor(cat);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) {
        // Audio continues playing in background via mini player
        WakelockPlus.disable();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textPrimary, size: 32),
                        onPressed: () {
                          WakelockPlus.disable();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/content');
                          }
                        },
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text('NOW PLAYING',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Album Art ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedBuilder(
                      animation: _spinCtrl,
                      builder: (_, child) => Transform.rotate(
                        angle: _spinCtrl.value * 2 * 3.14159,
                        child: child,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: track['thumbnail_url'] as String? ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: catColor.withOpacity(0.2),
                              child: Icon(_catIcon(cat), color: catColor, size: 80),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Track info ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track['title'] as String? ?? '',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track['artist'] as String? ?? 'SerenAI',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cat[0].toUpperCase() + cat.substring(1),
                          style: TextStyle(
                            color: catColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Progress bar ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: catColor,
                          inactiveTrackColor: AppTheme.surfaceHigh,
                          thumbColor: catColor,
                          overlayColor: catColor.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (v) {
                            final pos = Duration(
                              milliseconds: (v * audio.duration.inMilliseconds).toInt(),
                            );
                            ref.read(audioPlayerProvider.notifier).seekTo(pos);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(audio.position),
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            Text(_fmt(audio.duration),
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Play / Pause / Error ──────────────────────
                if (audio.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentWarm.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentWarm.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppTheme.accentWarm, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Could not load audio. Check internet connection.',
                              style: TextStyle(color: AppTheme.accentWarm, fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(audioPlayerProvider.notifier).playTrack(track),
                            child: const Text('Retry',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skip Previous Track
                    IconButton(
                      onPressed: () {
                        final tracks = ref.read(audioTracksProvider).value ?? [];
                        ref.read(audioPlayerProvider.notifier).playPrevious(tracks);
                      },
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: AppTheme.textSecondary, size: 36),
                    ),
                    const SizedBox(width: 8),

                    // Seek backward 10s
                    IconButton(
                      onPressed: () {
                        final pos = audio.position - const Duration(seconds: 10);
                        ref.read(audioPlayerProvider.notifier).seekTo(
                          pos < Duration.zero ? Duration.zero : pos,
                        );
                      },
                      icon: const Icon(Icons.replay_10_rounded,
                          color: AppTheme.textSecondary, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Main play/pause
                    GestureDetector(
                      onTap: () => ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [catColor, catColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: audio.isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.white),
                              )
                            : Icon(
                                audio.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                      ),
                    ),

                    const SizedBox(width: 16),
                    // Seek forward 10s
                    IconButton(
                      onPressed: () {
                        final pos = audio.position + const Duration(seconds: 10);
                        ref.read(audioPlayerProvider.notifier).seekTo(pos);
                      },
                      icon: const Icon(Icons.forward_10_rounded,
                          color: AppTheme.textSecondary, size: 28),
                    ),
                    const SizedBox(width: 8),

                    // Skip Next Track
                    IconButton(
                      onPressed: () {
                        final tracks = ref.read(audioTracksProvider).value ?? [];
                        ref.read(audioPlayerProvider.notifier).playNext(tracks);
                      },
                      icon: const Icon(Icons.skip_next_rounded,
                          color: AppTheme.textSecondary, size: 36),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Volume (app-level) ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.surfaceHigh,
                            thumbColor: AppTheme.primary,
                          ),
                          child: Slider(
                            value: _currentVolume.clamp(0.0, 1.0),
                            onChanged: (v) {
                              setState(() => _currentVolume = v);
                              FlutterVolumeController.setVolume(v);
                            },
                          ),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 8),                const SizedBox(height: 24),
              ],
            ),
          ),
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
      default:          return AppTheme.primary;
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


