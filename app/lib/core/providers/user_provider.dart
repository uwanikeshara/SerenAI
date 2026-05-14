import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserStats {
  final int totalPoints;
  final int totalScans;
  final int totalJournals;
  final int totalAudioMinutes;
  final int currentStreak;

  const UserStats({
    this.totalPoints = 0,
    this.totalScans = 0,
    this.totalJournals = 0,
    this.totalAudioMinutes = 0,
    this.currentStreak = 0,
  });
}

final userStatsProvider = StreamProvider<UserStats>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return Stream.value(const UserStats());

  // Listen to ALL gamification events to calculate aggregates
  return Supabase.instance.client
      .from('gamification_events')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .handleError((_) => const Stream.empty()) // Prevent Realtime crashes from killing the provider
      .map((events) {
        int pts = 0;
        int scans = 0;
        int journals = 0;
        int audioMins = 0; // if points are derived from duration, etc.

        for (final e in events) {
          pts += (e['points'] as int? ?? 0);
          final type = e['event_type'] as String? ?? '';
          if (type == 'scan_complete') scans++;
          if (type == 'journal_entry') journals++;
          if (type == 'audio_session') audioMins += 10; // rough minute counter based on event
        }

        // We can fetch streak from the profile table if we want, or just default to 0
        // for now, until we get a profile stream running.
        return UserStats(
          totalPoints: pts,
          totalScans: scans,
          totalJournals: journals,
          totalAudioMinutes: audioMins,
        );
      });
});

final profileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return Stream.value(null);

  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .handleError((_) => const Stream.empty()) // Protect profile card from vanishing on network flicker
      .map((docs) => docs.isNotEmpty ? docs.first : null);
});
