// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalScansTable extends LocalScans
    with TableInfo<$LocalScansTable, LocalScan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stressScoreMeta =
      const VerificationMeta('stressScore');
  @override
  late final GeneratedColumn<double> stressScore = GeneratedColumn<double>(
      'stress_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stressLevelMeta =
      const VerificationMeta('stressLevel');
  @override
  late final GeneratedColumn<String> stressLevel = GeneratedColumn<String>(
      'stress_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dominantEmotionMeta =
      const VerificationMeta('dominantEmotion');
  @override
  late final GeneratedColumn<String> dominantEmotion = GeneratedColumn<String>(
      'dominant_emotion', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emotionProbsMeta =
      const VerificationMeta('emotionProbs');
  @override
  late final GeneratedColumn<String> emotionProbs = GeneratedColumn<String>(
      'emotion_probs', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scannedAtMeta =
      const VerificationMeta('scannedAt');
  @override
  late final GeneratedColumn<DateTime> scannedAt = GeneratedColumn<DateTime>(
      'scanned_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        stressScore,
        stressLevel,
        dominantEmotion,
        emotionProbs,
        scannedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_scans';
  @override
  VerificationContext validateIntegrity(Insertable<LocalScan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stress_score')) {
      context.handle(
          _stressScoreMeta,
          stressScore.isAcceptableOrUnknown(
              data['stress_score']!, _stressScoreMeta));
    } else if (isInserting) {
      context.missing(_stressScoreMeta);
    }
    if (data.containsKey('stress_level')) {
      context.handle(
          _stressLevelMeta,
          stressLevel.isAcceptableOrUnknown(
              data['stress_level']!, _stressLevelMeta));
    } else if (isInserting) {
      context.missing(_stressLevelMeta);
    }
    if (data.containsKey('dominant_emotion')) {
      context.handle(
          _dominantEmotionMeta,
          dominantEmotion.isAcceptableOrUnknown(
              data['dominant_emotion']!, _dominantEmotionMeta));
    } else if (isInserting) {
      context.missing(_dominantEmotionMeta);
    }
    if (data.containsKey('emotion_probs')) {
      context.handle(
          _emotionProbsMeta,
          emotionProbs.isAcceptableOrUnknown(
              data['emotion_probs']!, _emotionProbsMeta));
    } else if (isInserting) {
      context.missing(_emotionProbsMeta);
    }
    if (data.containsKey('scanned_at')) {
      context.handle(_scannedAtMeta,
          scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta));
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalScan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalScan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      stressScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stress_score'])!,
      stressLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stress_level'])!,
      dominantEmotion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dominant_emotion'])!,
      emotionProbs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emotion_probs'])!,
      scannedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}scanned_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $LocalScansTable createAlias(String alias) {
    return $LocalScansTable(attachedDatabase, alias);
  }
}

class LocalScan extends DataClass implements Insertable<LocalScan> {
  final String id;
  final double stressScore;
  final String stressLevel;
  final String dominantEmotion;
  final String emotionProbs;
  final DateTime scannedAt;
  final bool synced;
  const LocalScan(
      {required this.id,
      required this.stressScore,
      required this.stressLevel,
      required this.dominantEmotion,
      required this.emotionProbs,
      required this.scannedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stress_score'] = Variable<double>(stressScore);
    map['stress_level'] = Variable<String>(stressLevel);
    map['dominant_emotion'] = Variable<String>(dominantEmotion);
    map['emotion_probs'] = Variable<String>(emotionProbs);
    map['scanned_at'] = Variable<DateTime>(scannedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalScansCompanion toCompanion(bool nullToAbsent) {
    return LocalScansCompanion(
      id: Value(id),
      stressScore: Value(stressScore),
      stressLevel: Value(stressLevel),
      dominantEmotion: Value(dominantEmotion),
      emotionProbs: Value(emotionProbs),
      scannedAt: Value(scannedAt),
      synced: Value(synced),
    );
  }

  factory LocalScan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalScan(
      id: serializer.fromJson<String>(json['id']),
      stressScore: serializer.fromJson<double>(json['stressScore']),
      stressLevel: serializer.fromJson<String>(json['stressLevel']),
      dominantEmotion: serializer.fromJson<String>(json['dominantEmotion']),
      emotionProbs: serializer.fromJson<String>(json['emotionProbs']),
      scannedAt: serializer.fromJson<DateTime>(json['scannedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stressScore': serializer.toJson<double>(stressScore),
      'stressLevel': serializer.toJson<String>(stressLevel),
      'dominantEmotion': serializer.toJson<String>(dominantEmotion),
      'emotionProbs': serializer.toJson<String>(emotionProbs),
      'scannedAt': serializer.toJson<DateTime>(scannedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalScan copyWith(
          {String? id,
          double? stressScore,
          String? stressLevel,
          String? dominantEmotion,
          String? emotionProbs,
          DateTime? scannedAt,
          bool? synced}) =>
      LocalScan(
        id: id ?? this.id,
        stressScore: stressScore ?? this.stressScore,
        stressLevel: stressLevel ?? this.stressLevel,
        dominantEmotion: dominantEmotion ?? this.dominantEmotion,
        emotionProbs: emotionProbs ?? this.emotionProbs,
        scannedAt: scannedAt ?? this.scannedAt,
        synced: synced ?? this.synced,
      );
  LocalScan copyWithCompanion(LocalScansCompanion data) {
    return LocalScan(
      id: data.id.present ? data.id.value : this.id,
      stressScore:
          data.stressScore.present ? data.stressScore.value : this.stressScore,
      stressLevel:
          data.stressLevel.present ? data.stressLevel.value : this.stressLevel,
      dominantEmotion: data.dominantEmotion.present
          ? data.dominantEmotion.value
          : this.dominantEmotion,
      emotionProbs: data.emotionProbs.present
          ? data.emotionProbs.value
          : this.emotionProbs,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalScan(')
          ..write('id: $id, ')
          ..write('stressScore: $stressScore, ')
          ..write('stressLevel: $stressLevel, ')
          ..write('dominantEmotion: $dominantEmotion, ')
          ..write('emotionProbs: $emotionProbs, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stressScore, stressLevel, dominantEmotion,
      emotionProbs, scannedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalScan &&
          other.id == this.id &&
          other.stressScore == this.stressScore &&
          other.stressLevel == this.stressLevel &&
          other.dominantEmotion == this.dominantEmotion &&
          other.emotionProbs == this.emotionProbs &&
          other.scannedAt == this.scannedAt &&
          other.synced == this.synced);
}

class LocalScansCompanion extends UpdateCompanion<LocalScan> {
  final Value<String> id;
  final Value<double> stressScore;
  final Value<String> stressLevel;
  final Value<String> dominantEmotion;
  final Value<String> emotionProbs;
  final Value<DateTime> scannedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalScansCompanion({
    this.id = const Value.absent(),
    this.stressScore = const Value.absent(),
    this.stressLevel = const Value.absent(),
    this.dominantEmotion = const Value.absent(),
    this.emotionProbs = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalScansCompanion.insert({
    required String id,
    required double stressScore,
    required String stressLevel,
    required String dominantEmotion,
    required String emotionProbs,
    required DateTime scannedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        stressScore = Value(stressScore),
        stressLevel = Value(stressLevel),
        dominantEmotion = Value(dominantEmotion),
        emotionProbs = Value(emotionProbs),
        scannedAt = Value(scannedAt);
  static Insertable<LocalScan> custom({
    Expression<String>? id,
    Expression<double>? stressScore,
    Expression<String>? stressLevel,
    Expression<String>? dominantEmotion,
    Expression<String>? emotionProbs,
    Expression<DateTime>? scannedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stressScore != null) 'stress_score': stressScore,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (dominantEmotion != null) 'dominant_emotion': dominantEmotion,
      if (emotionProbs != null) 'emotion_probs': emotionProbs,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalScansCompanion copyWith(
      {Value<String>? id,
      Value<double>? stressScore,
      Value<String>? stressLevel,
      Value<String>? dominantEmotion,
      Value<String>? emotionProbs,
      Value<DateTime>? scannedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return LocalScansCompanion(
      id: id ?? this.id,
      stressScore: stressScore ?? this.stressScore,
      stressLevel: stressLevel ?? this.stressLevel,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      emotionProbs: emotionProbs ?? this.emotionProbs,
      scannedAt: scannedAt ?? this.scannedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stressScore.present) {
      map['stress_score'] = Variable<double>(stressScore.value);
    }
    if (stressLevel.present) {
      map['stress_level'] = Variable<String>(stressLevel.value);
    }
    if (dominantEmotion.present) {
      map['dominant_emotion'] = Variable<String>(dominantEmotion.value);
    }
    if (emotionProbs.present) {
      map['emotion_probs'] = Variable<String>(emotionProbs.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<DateTime>(scannedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalScansCompanion(')
          ..write('id: $id, ')
          ..write('stressScore: $stressScore, ')
          ..write('stressLevel: $stressLevel, ')
          ..write('dominantEmotion: $dominantEmotion, ')
          ..write('emotionProbs: $emotionProbs, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalJournalEntriesTable extends LocalJournalEntries
    with TableInfo<$LocalJournalEntriesTable, LocalJournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalJournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodTagMeta =
      const VerificationMeta('moodTag');
  @override
  late final GeneratedColumn<String> moodTag = GeneratedColumn<String>(
      'mood_tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, content, moodTag, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_journal_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LocalJournalEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('mood_tag')) {
      context.handle(_moodTagMeta,
          moodTag.isAcceptableOrUnknown(data['mood_tag']!, _moodTagMeta));
    } else if (isInserting) {
      context.missing(_moodTagMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalJournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalJournalEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      moodTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood_tag'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $LocalJournalEntriesTable createAlias(String alias) {
    return $LocalJournalEntriesTable(attachedDatabase, alias);
  }
}

class LocalJournalEntry extends DataClass
    implements Insertable<LocalJournalEntry> {
  final String id;
  final String content;
  final String moodTag;
  final DateTime createdAt;
  final bool synced;
  const LocalJournalEntry(
      {required this.id,
      required this.content,
      required this.moodTag,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['mood_tag'] = Variable<String>(moodTag);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalJournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalJournalEntriesCompanion(
      id: Value(id),
      content: Value(content),
      moodTag: Value(moodTag),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory LocalJournalEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalJournalEntry(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      moodTag: serializer.fromJson<String>(json['moodTag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'moodTag': serializer.toJson<String>(moodTag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalJournalEntry copyWith(
          {String? id,
          String? content,
          String? moodTag,
          DateTime? createdAt,
          bool? synced}) =>
      LocalJournalEntry(
        id: id ?? this.id,
        content: content ?? this.content,
        moodTag: moodTag ?? this.moodTag,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  LocalJournalEntry copyWithCompanion(LocalJournalEntriesCompanion data) {
    return LocalJournalEntry(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      moodTag: data.moodTag.present ? data.moodTag.value : this.moodTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalJournalEntry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, moodTag, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalJournalEntry &&
          other.id == this.id &&
          other.content == this.content &&
          other.moodTag == this.moodTag &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class LocalJournalEntriesCompanion extends UpdateCompanion<LocalJournalEntry> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> moodTag;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalJournalEntriesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.moodTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalJournalEntriesCompanion.insert({
    required String id,
    required String content,
    required String moodTag,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content),
        moodTag = Value(moodTag),
        createdAt = Value(createdAt);
  static Insertable<LocalJournalEntry> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? moodTag,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (moodTag != null) 'mood_tag': moodTag,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalJournalEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? content,
      Value<String>? moodTag,
      Value<DateTime>? createdAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return LocalJournalEntriesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      moodTag: moodTag ?? this.moodTag,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (moodTag.present) {
      map['mood_tag'] = Variable<String>(moodTag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalJournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAudioTable extends LocalAudio
    with TableInfo<$LocalAudioTable, LocalAudioData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAudioTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, category, localPath, downloadedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_audio';
  @override
  VerificationContext validateIntegrity(Insertable<LocalAudioData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAudioData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAudioData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $LocalAudioTable createAlias(String alias) {
    return $LocalAudioTable(attachedDatabase, alias);
  }
}

class LocalAudioData extends DataClass implements Insertable<LocalAudioData> {
  final String id;
  final String title;
  final String category;
  final String localPath;
  final DateTime downloadedAt;
  const LocalAudioData(
      {required this.id,
      required this.title,
      required this.category,
      required this.localPath,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['local_path'] = Variable<String>(localPath);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  LocalAudioCompanion toCompanion(bool nullToAbsent) {
    return LocalAudioCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      localPath: Value(localPath),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory LocalAudioData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAudioData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      localPath: serializer.fromJson<String>(json['localPath']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'localPath': serializer.toJson<String>(localPath),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  LocalAudioData copyWith(
          {String? id,
          String? title,
          String? category,
          String? localPath,
          DateTime? downloadedAt}) =>
      LocalAudioData(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        localPath: localPath ?? this.localPath,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  LocalAudioData copyWithCompanion(LocalAudioCompanion data) {
    return LocalAudioData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAudioData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, category, localPath, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAudioData &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.localPath == this.localPath &&
          other.downloadedAt == this.downloadedAt);
}

class LocalAudioCompanion extends UpdateCompanion<LocalAudioData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> localPath;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const LocalAudioCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAudioCompanion.insert({
    required String id,
    required String title,
    required String category,
    required String localPath,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        category = Value(category),
        localPath = Value(localPath),
        downloadedAt = Value(downloadedAt);
  static Insertable<LocalAudioData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? localPath,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (localPath != null) 'local_path': localPath,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAudioCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? category,
      Value<String>? localPath,
      Value<DateTime>? downloadedAt,
      Value<int>? rowid}) {
    return LocalAudioCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAudioCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalScansTable localScans = $LocalScansTable(this);
  late final $LocalJournalEntriesTable localJournalEntries =
      $LocalJournalEntriesTable(this);
  late final $LocalAudioTable localAudio = $LocalAudioTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localScans, localJournalEntries, localAudio];
}

typedef $$LocalScansTableCreateCompanionBuilder = LocalScansCompanion Function({
  required String id,
  required double stressScore,
  required String stressLevel,
  required String dominantEmotion,
  required String emotionProbs,
  required DateTime scannedAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$LocalScansTableUpdateCompanionBuilder = LocalScansCompanion Function({
  Value<String> id,
  Value<double> stressScore,
  Value<String> stressLevel,
  Value<String> dominantEmotion,
  Value<String> emotionProbs,
  Value<DateTime> scannedAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$LocalScansTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalScansTable> {
  $$LocalScansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stressScore => $composableBuilder(
      column: $table.stressScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stressLevel => $composableBuilder(
      column: $table.stressLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dominantEmotion => $composableBuilder(
      column: $table.dominantEmotion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emotionProbs => $composableBuilder(
      column: $table.emotionProbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$LocalScansTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalScansTable> {
  $$LocalScansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stressScore => $composableBuilder(
      column: $table.stressScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stressLevel => $composableBuilder(
      column: $table.stressLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dominantEmotion => $composableBuilder(
      column: $table.dominantEmotion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emotionProbs => $composableBuilder(
      column: $table.emotionProbs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scannedAt => $composableBuilder(
      column: $table.scannedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$LocalScansTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalScansTable> {
  $$LocalScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get stressScore => $composableBuilder(
      column: $table.stressScore, builder: (column) => column);

  GeneratedColumn<String> get stressLevel => $composableBuilder(
      column: $table.stressLevel, builder: (column) => column);

  GeneratedColumn<String> get dominantEmotion => $composableBuilder(
      column: $table.dominantEmotion, builder: (column) => column);

  GeneratedColumn<String> get emotionProbs => $composableBuilder(
      column: $table.emotionProbs, builder: (column) => column);

  GeneratedColumn<DateTime> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$LocalScansTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalScansTable,
    LocalScan,
    $$LocalScansTableFilterComposer,
    $$LocalScansTableOrderingComposer,
    $$LocalScansTableAnnotationComposer,
    $$LocalScansTableCreateCompanionBuilder,
    $$LocalScansTableUpdateCompanionBuilder,
    (LocalScan, BaseReferences<_$LocalDatabase, $LocalScansTable, LocalScan>),
    LocalScan,
    PrefetchHooks Function()> {
  $$LocalScansTableTableManager(_$LocalDatabase db, $LocalScansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> stressScore = const Value.absent(),
            Value<String> stressLevel = const Value.absent(),
            Value<String> dominantEmotion = const Value.absent(),
            Value<String> emotionProbs = const Value.absent(),
            Value<DateTime> scannedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalScansCompanion(
            id: id,
            stressScore: stressScore,
            stressLevel: stressLevel,
            dominantEmotion: dominantEmotion,
            emotionProbs: emotionProbs,
            scannedAt: scannedAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double stressScore,
            required String stressLevel,
            required String dominantEmotion,
            required String emotionProbs,
            required DateTime scannedAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalScansCompanion.insert(
            id: id,
            stressScore: stressScore,
            stressLevel: stressLevel,
            dominantEmotion: dominantEmotion,
            emotionProbs: emotionProbs,
            scannedAt: scannedAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalScansTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalScansTable,
    LocalScan,
    $$LocalScansTableFilterComposer,
    $$LocalScansTableOrderingComposer,
    $$LocalScansTableAnnotationComposer,
    $$LocalScansTableCreateCompanionBuilder,
    $$LocalScansTableUpdateCompanionBuilder,
    (LocalScan, BaseReferences<_$LocalDatabase, $LocalScansTable, LocalScan>),
    LocalScan,
    PrefetchHooks Function()>;
typedef $$LocalJournalEntriesTableCreateCompanionBuilder
    = LocalJournalEntriesCompanion Function({
  required String id,
  required String content,
  required String moodTag,
  required DateTime createdAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$LocalJournalEntriesTableUpdateCompanionBuilder
    = LocalJournalEntriesCompanion Function({
  Value<String> id,
  Value<String> content,
  Value<String> moodTag,
  Value<DateTime> createdAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$LocalJournalEntriesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moodTag => $composableBuilder(
      column: $table.moodTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$LocalJournalEntriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moodTag => $composableBuilder(
      column: $table.moodTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$LocalJournalEntriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get moodTag =>
      $composableBuilder(column: $table.moodTag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$LocalJournalEntriesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalJournalEntriesTable,
    LocalJournalEntry,
    $$LocalJournalEntriesTableFilterComposer,
    $$LocalJournalEntriesTableOrderingComposer,
    $$LocalJournalEntriesTableAnnotationComposer,
    $$LocalJournalEntriesTableCreateCompanionBuilder,
    $$LocalJournalEntriesTableUpdateCompanionBuilder,
    (
      LocalJournalEntry,
      BaseReferences<_$LocalDatabase, $LocalJournalEntriesTable,
          LocalJournalEntry>
    ),
    LocalJournalEntry,
    PrefetchHooks Function()> {
  $$LocalJournalEntriesTableTableManager(
      _$LocalDatabase db, $LocalJournalEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalJournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalJournalEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalJournalEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> moodTag = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalJournalEntriesCompanion(
            id: id,
            content: content,
            moodTag: moodTag,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String content,
            required String moodTag,
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalJournalEntriesCompanion.insert(
            id: id,
            content: content,
            moodTag: moodTag,
            createdAt: createdAt,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalJournalEntriesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalJournalEntriesTable,
    LocalJournalEntry,
    $$LocalJournalEntriesTableFilterComposer,
    $$LocalJournalEntriesTableOrderingComposer,
    $$LocalJournalEntriesTableAnnotationComposer,
    $$LocalJournalEntriesTableCreateCompanionBuilder,
    $$LocalJournalEntriesTableUpdateCompanionBuilder,
    (
      LocalJournalEntry,
      BaseReferences<_$LocalDatabase, $LocalJournalEntriesTable,
          LocalJournalEntry>
    ),
    LocalJournalEntry,
    PrefetchHooks Function()>;
typedef $$LocalAudioTableCreateCompanionBuilder = LocalAudioCompanion Function({
  required String id,
  required String title,
  required String category,
  required String localPath,
  required DateTime downloadedAt,
  Value<int> rowid,
});
typedef $$LocalAudioTableUpdateCompanionBuilder = LocalAudioCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> category,
  Value<String> localPath,
  Value<DateTime> downloadedAt,
  Value<int> rowid,
});

class $$LocalAudioTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalAudioTable> {
  $$LocalAudioTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalAudioTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalAudioTable> {
  $$LocalAudioTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalAudioTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalAudioTable> {
  $$LocalAudioTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$LocalAudioTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalAudioTable,
    LocalAudioData,
    $$LocalAudioTableFilterComposer,
    $$LocalAudioTableOrderingComposer,
    $$LocalAudioTableAnnotationComposer,
    $$LocalAudioTableCreateCompanionBuilder,
    $$LocalAudioTableUpdateCompanionBuilder,
    (
      LocalAudioData,
      BaseReferences<_$LocalDatabase, $LocalAudioTable, LocalAudioData>
    ),
    LocalAudioData,
    PrefetchHooks Function()> {
  $$LocalAudioTableTableManager(_$LocalDatabase db, $LocalAudioTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAudioTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAudioTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAudioTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAudioCompanion(
            id: id,
            title: title,
            category: category,
            localPath: localPath,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String category,
            required String localPath,
            required DateTime downloadedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAudioCompanion.insert(
            id: id,
            title: title,
            category: category,
            localPath: localPath,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalAudioTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalAudioTable,
    LocalAudioData,
    $$LocalAudioTableFilterComposer,
    $$LocalAudioTableOrderingComposer,
    $$LocalAudioTableAnnotationComposer,
    $$LocalAudioTableCreateCompanionBuilder,
    $$LocalAudioTableUpdateCompanionBuilder,
    (
      LocalAudioData,
      BaseReferences<_$LocalDatabase, $LocalAudioTable, LocalAudioData>
    ),
    LocalAudioData,
    PrefetchHooks Function()>;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalScansTableTableManager get localScans =>
      $$LocalScansTableTableManager(_db, _db.localScans);
  $$LocalJournalEntriesTableTableManager get localJournalEntries =>
      $$LocalJournalEntriesTableTableManager(_db, _db.localJournalEntries);
  $$LocalAudioTableTableManager get localAudio =>
      $$LocalAudioTableTableManager(_db, _db.localAudio);
}
