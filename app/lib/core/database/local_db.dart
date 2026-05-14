import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_db.g.dart';

// ── Tables ─────────────────────────────────────────────────────

class LocalScans extends Table {
  TextColumn get id           => text()();
  RealColumn get stressScore  => real()();
  TextColumn get stressLevel  => text()();
  TextColumn get dominantEmotion => text()();
  TextColumn get emotionProbs => text()(); // JSON string
  DateTimeColumn get scannedAt => dateTime()();
  BoolColumn get synced       => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalJournalEntries extends Table {
  TextColumn get id        => text()();
  TextColumn get content   => text()();
  TextColumn get moodTag   => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced    => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalAudio extends Table {
  TextColumn get id        => text()();
  TextColumn get title     => text()();
  TextColumn get category  => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────

@DriftDatabase(tables: [LocalScans, LocalJournalEntries, LocalAudio])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Scans
  Stream<List<LocalScan>> watchRecentScans() =>
    (select(localScans)
      ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)])
      ..where((t) => t.scannedAt.isBiggerThanValue(DateTime.now().subtract(const Duration(days: 7)))))
    .watch();

  Future<void> insertScan(LocalScansCompanion scan) =>
    into(localScans).insertOnConflictUpdate(scan);
  
  Future<void> purgeOldScans() async {
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    await (delete(localScans)..where((t) => t.scannedAt.isSmallerThanValue(threshold))).go();
  }

  // Audio
  Future<LocalAudioData?> getDownloadedAudio(String id) =>
    (select(localAudio)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> saveDownloadedAudio(LocalAudioCompanion audio) =>
    into(localAudio).insertOnConflictUpdate(audio);

  Future<void> deleteDownloadedAudio(String id) =>
    (delete(localAudio)..where((t) => t.id.equals(id))).go();

  Future<List<LocalScan>> getUnsyncedScans() =>
    (select(localScans)..where((t) => t.synced.equals(false))).get();

  Future<void> markScanSynced(String id) =>
    (update(localScans)..where((t) => t.id.equals(id)))
    .write(const LocalScansCompanion(synced: Value(true)));

  // Journal
  Future<List<LocalJournalEntry>> getAllJournalEntries() =>
    (select(localJournalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
    .get();

  Future<void> insertJournalEntry(LocalJournalEntriesCompanion entry) =>
    into(localJournalEntries).insertOnConflictUpdate(entry);

  Future<List<LocalJournalEntry>> getUnsyncedJournalEntries() =>
    (select(localJournalEntries)..where((t) => t.synced.equals(false))).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docDir = await getApplicationDocumentsDirectory();
    final file   = File(p.join(docDir.path, 'serenai.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// Riverpod provider
final localDbProvider = Provider<LocalDatabase>(
  (ref) => throw UnimplementedError('Override in main'),
);
