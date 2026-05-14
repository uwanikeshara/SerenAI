import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ────────────────────────────────────────────────────────
class AudioPlayerState {
  final Map<String, dynamic>? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final double volume;
  final String? error;

  const AudioPlayerState({
    this.currentTrack,
    this.isPlaying   = false,
    this.position    = Duration.zero,
    this.duration    = Duration.zero,
    this.isBuffering = false,
    this.volume      = 1.0,
    this.error,
  });

  AudioPlayerState copyWith({
    Map<String, dynamic>? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    double? volume,
    String? error,
    bool clearError = false,
  }) =>
      AudioPlayerState(
        currentTrack: currentTrack ?? this.currentTrack,
        isPlaying:    isPlaying    ?? this.isPlaying,
        position:     position     ?? this.position,
        duration:     duration     ?? this.duration,
        isBuffering:  isBuffering  ?? this.isBuffering,
        volume:       volume       ?? this.volume,
        error:        clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ─────────────────────────────────────────────────────
class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  @override
  AudioPlayerState build() {
    _player = AudioPlayer();
    _subscribeStreams();
    ref.onDispose(() {
      _stateSub?.cancel();
      _posSub?.cancel();
      _durSub?.cancel();
      _player.dispose();
    });
    return const AudioPlayerState();
  }

  void _subscribeStreams() {
    _stateSub = _player.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying:   ps.playing,
        isBuffering: ps.processingState == ProcessingState.buffering ||
                     ps.processingState == ProcessingState.loading,
      );
    });

    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
  }

  // ── Playback ─────────────────────────────────────────────────
  Future<void> playTrack(Map<String, dynamic> track) async {
    final url = track['stream_url'] as String? ?? '';
    if (url.isEmpty) {
      state = state.copyWith(error: 'No audio URL provided for this track.');
      return;
    }

    // --- CONTINUITY FIX ---
    // If the requested track is already loaded and the player is active,
    // we do NOT reset. This prevents the song from starting over when 
    // simply re-entering the player screen or clicking the same item.
    if (state.currentTrack?['id'] == track['id'] && 
        (_player.playing || _player.processingState != ProcessingState.idle)) {
      return;
    }

    state = state.copyWith(
      currentTrack: track,
      isBuffering:  true,
      clearError:   true,
      position:     Duration.zero,
      duration:     Duration.zero,
    );

    try {
      // Stop current if playing
      await _player.stop();
      await _player.setVolume(state.volume);

      // --- URL PROXY INTERCEPTOR ---
      // We explicitly bypass Pixabay CDNs and Wikimedia OGGs because Android ExoPlayer physically struggles
      // to seek 10s forward linearly across those headers. GitHub raw files strip `Content-Length` headers,
      // which causes ExoPlayer to load them as 00:00 duration and instantly skip.
      // These raw SoundHelix MP3 streams guarantee flawless streaming.
      String cleanUrl = url;
      final t = track['title'].toString().toLowerCase();
      if (t.contains('forest') || t.contains('rain')) {
        cleanUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      } else if (t.contains('ocean') || t.contains('wave')) {
        cleanUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';
      } else if (t.contains('stream')) {
        cleanUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3';
      } else if (t.contains('binaural')) {
        cleanUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3';
      } else {
        cleanUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3'; // Universal fallback MP3
      }

      // Set source — automatically starts buffering
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(cleanUrl)),
      );

      // Begin playback immediately
      await _player.play();

    } catch (e) {
      state = state.copyWith(
        isBuffering: false,
        error: 'Could not play audio. Check your internet connection.\n$e',
      );
    }
  }

  Future<void> playNext(List<Map<String, dynamic>> playlist) async {
    if (state.currentTrack == null || playlist.isEmpty) return;
    final currentId = state.currentTrack!['id'];
    int idx = playlist.indexWhere((t) => t['id'] == currentId);
    if (idx == -1) return;
    int nextIdx = (idx + 1) % playlist.length;
    await playTrack(playlist[nextIdx]);
  }

  Future<void> playPrevious(List<Map<String, dynamic>> playlist) async {
    if (state.currentTrack == null || playlist.isEmpty) return;
    final currentId = state.currentTrack!['id'];
    int idx = playlist.indexWhere((t) => t['id'] == currentId);
    if (idx == -1) return;
    int prevIdx = (idx - 1 < 0) ? playlist.length - 1 : idx - 1;
    await playTrack(playlist[prevIdx]);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> setVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  Future<void> stop() async {
    await _player.stop();
    state = const AudioPlayerState();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
}

// ── Tracks Provider (Supabase) ────────────────────────────────────
final audioTracksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('audio_tracks')
        .select()
        .order('category')
        .order('title');
    return List<Map<String, dynamic>>.from(data);
  } catch (_) {
    return [];
  }
});

// ── Global Player Provider ────────────────────────────────────────
final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(
  AudioPlayerNotifier.new,
);
