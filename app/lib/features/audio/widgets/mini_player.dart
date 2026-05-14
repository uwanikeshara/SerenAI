import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';
import '../../../core/theme/app_theme.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);

    if (audio.currentTrack == null) return const SizedBox.shrink();

    final track    = audio.currentTrack!;
    final progress = audio.duration.inMilliseconds > 0
        ? audio.position.inMilliseconds / audio.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/audio', extra: track),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress line
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: track['thumbnail_url'] as String? ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 40,
                        height: 40,
                        color: AppTheme.surfaceHigh,
                        child: const Icon(Icons.music_note, color: AppTheme.primary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track['title'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            
                          ),
                        ),
                        Text(
                          track['category'] as String? ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  if (audio.isBuffering)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                      icon: Icon(
                        audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => ref.read(audioPlayerProvider.notifier).stop(),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
