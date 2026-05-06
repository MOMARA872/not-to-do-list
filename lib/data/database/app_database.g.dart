// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BlockListTable extends BlockList
    with TableInfo<$BlockListTable, BlockListData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockListTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
      'kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonNoteMeta =
      const VerificationMeta('reasonNote');
  @override
  late final GeneratedColumn<String> reasonNote = GeneratedColumn<String>(
      'reason_note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _streakBreakThresholdMinutesMeta =
      const VerificationMeta('streakBreakThresholdMinutes');
  @override
  late final GeneratedColumn<int> streakBreakThresholdMinutes =
      GeneratedColumn<int>('streak_break_threshold_minutes', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(5));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _blockModeMeta =
      const VerificationMeta('blockMode');
  @override
  late final GeneratedColumn<String> blockMode = GeneratedColumn<String>(
      'block_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('soft'));
  static const VerificationMeta _scheduleStartMinutesMeta =
      const VerificationMeta('scheduleStartMinutes');
  @override
  late final GeneratedColumn<int> scheduleStartMinutes = GeneratedColumn<int>(
      'schedule_start_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scheduleEndMinutesMeta =
      const VerificationMeta('scheduleEndMinutes');
  @override
  late final GeneratedColumn<int> scheduleEndMinutes = GeneratedColumn<int>(
      'schedule_end_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scheduleWeekdayMaskMeta =
      const VerificationMeta('scheduleWeekdayMask');
  @override
  late final GeneratedColumn<int> scheduleWeekdayMask = GeneratedColumn<int>(
      'schedule_weekday_mask', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        packageName,
        displayName,
        reasonNote,
        streakBreakThresholdMinutes,
        createdAt,
        updatedAt,
        blockMode,
        scheduleStartMinutes,
        scheduleEndMinutes,
        scheduleWeekdayMask
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'block_list';
  @override
  VerificationContext validateIntegrity(Insertable<BlockListData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('reason_note')) {
      context.handle(
          _reasonNoteMeta,
          reasonNote.isAcceptableOrUnknown(
              data['reason_note']!, _reasonNoteMeta));
    }
    if (data.containsKey('streak_break_threshold_minutes')) {
      context.handle(
          _streakBreakThresholdMinutesMeta,
          streakBreakThresholdMinutes.isAcceptableOrUnknown(
              data['streak_break_threshold_minutes']!,
              _streakBreakThresholdMinutesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('block_mode')) {
      context.handle(_blockModeMeta,
          blockMode.isAcceptableOrUnknown(data['block_mode']!, _blockModeMeta));
    }
    if (data.containsKey('schedule_start_minutes')) {
      context.handle(
          _scheduleStartMinutesMeta,
          scheduleStartMinutes.isAcceptableOrUnknown(
              data['schedule_start_minutes']!, _scheduleStartMinutesMeta));
    }
    if (data.containsKey('schedule_end_minutes')) {
      context.handle(
          _scheduleEndMinutesMeta,
          scheduleEndMinutes.isAcceptableOrUnknown(
              data['schedule_end_minutes']!, _scheduleEndMinutesMeta));
    }
    if (data.containsKey('schedule_weekday_mask')) {
      context.handle(
          _scheduleWeekdayMaskMeta,
          scheduleWeekdayMask.isAcceptableOrUnknown(
              data['schedule_weekday_mask']!, _scheduleWeekdayMaskMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {kind, packageName},
      ];
  @override
  BlockListData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockListData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      reasonNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_note'])!,
      streakBreakThresholdMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}streak_break_threshold_minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      blockMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}block_mode'])!,
      scheduleStartMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}schedule_start_minutes']),
      scheduleEndMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}schedule_end_minutes']),
      scheduleWeekdayMask: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}schedule_weekday_mask']),
    );
  }

  @override
  $BlockListTable createAlias(String alias) {
    return $BlockListTable(attachedDatabase, alias);
  }
}

class BlockListData extends DataClass implements Insertable<BlockListData> {
  final int id;
  final int kind;
  final String? packageName;
  final String displayName;
  final String reasonNote;
  final int streakBreakThresholdMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String blockMode;
  final int? scheduleStartMinutes;
  final int? scheduleEndMinutes;
  final int? scheduleWeekdayMask;
  const BlockListData(
      {required this.id,
      required this.kind,
      this.packageName,
      required this.displayName,
      required this.reasonNote,
      required this.streakBreakThresholdMinutes,
      required this.createdAt,
      required this.updatedAt,
      required this.blockMode,
      this.scheduleStartMinutes,
      this.scheduleEndMinutes,
      this.scheduleWeekdayMask});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || packageName != null) {
      map['package_name'] = Variable<String>(packageName);
    }
    map['display_name'] = Variable<String>(displayName);
    map['reason_note'] = Variable<String>(reasonNote);
    map['streak_break_threshold_minutes'] =
        Variable<int>(streakBreakThresholdMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['block_mode'] = Variable<String>(blockMode);
    if (!nullToAbsent || scheduleStartMinutes != null) {
      map['schedule_start_minutes'] = Variable<int>(scheduleStartMinutes);
    }
    if (!nullToAbsent || scheduleEndMinutes != null) {
      map['schedule_end_minutes'] = Variable<int>(scheduleEndMinutes);
    }
    if (!nullToAbsent || scheduleWeekdayMask != null) {
      map['schedule_weekday_mask'] = Variable<int>(scheduleWeekdayMask);
    }
    return map;
  }

  BlockListCompanion toCompanion(bool nullToAbsent) {
    return BlockListCompanion(
      id: Value(id),
      kind: Value(kind),
      packageName: packageName == null && nullToAbsent
          ? const Value.absent()
          : Value(packageName),
      displayName: Value(displayName),
      reasonNote: Value(reasonNote),
      streakBreakThresholdMinutes: Value(streakBreakThresholdMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      blockMode: Value(blockMode),
      scheduleStartMinutes: scheduleStartMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleStartMinutes),
      scheduleEndMinutes: scheduleEndMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleEndMinutes),
      scheduleWeekdayMask: scheduleWeekdayMask == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleWeekdayMask),
    );
  }

  factory BlockListData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockListData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<int>(json['kind']),
      packageName: serializer.fromJson<String?>(json['packageName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      reasonNote: serializer.fromJson<String>(json['reasonNote']),
      streakBreakThresholdMinutes:
          serializer.fromJson<int>(json['streakBreakThresholdMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      blockMode: serializer.fromJson<String>(json['blockMode']),
      scheduleStartMinutes:
          serializer.fromJson<int?>(json['scheduleStartMinutes']),
      scheduleEndMinutes: serializer.fromJson<int?>(json['scheduleEndMinutes']),
      scheduleWeekdayMask:
          serializer.fromJson<int?>(json['scheduleWeekdayMask']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<int>(kind),
      'packageName': serializer.toJson<String?>(packageName),
      'displayName': serializer.toJson<String>(displayName),
      'reasonNote': serializer.toJson<String>(reasonNote),
      'streakBreakThresholdMinutes':
          serializer.toJson<int>(streakBreakThresholdMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'blockMode': serializer.toJson<String>(blockMode),
      'scheduleStartMinutes': serializer.toJson<int?>(scheduleStartMinutes),
      'scheduleEndMinutes': serializer.toJson<int?>(scheduleEndMinutes),
      'scheduleWeekdayMask': serializer.toJson<int?>(scheduleWeekdayMask),
    };
  }

  BlockListData copyWith(
          {int? id,
          int? kind,
          Value<String?> packageName = const Value.absent(),
          String? displayName,
          String? reasonNote,
          int? streakBreakThresholdMinutes,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? blockMode,
          Value<int?> scheduleStartMinutes = const Value.absent(),
          Value<int?> scheduleEndMinutes = const Value.absent(),
          Value<int?> scheduleWeekdayMask = const Value.absent()}) =>
      BlockListData(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        packageName: packageName.present ? packageName.value : this.packageName,
        displayName: displayName ?? this.displayName,
        reasonNote: reasonNote ?? this.reasonNote,
        streakBreakThresholdMinutes:
            streakBreakThresholdMinutes ?? this.streakBreakThresholdMinutes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        blockMode: blockMode ?? this.blockMode,
        scheduleStartMinutes: scheduleStartMinutes.present
            ? scheduleStartMinutes.value
            : this.scheduleStartMinutes,
        scheduleEndMinutes: scheduleEndMinutes.present
            ? scheduleEndMinutes.value
            : this.scheduleEndMinutes,
        scheduleWeekdayMask: scheduleWeekdayMask.present
            ? scheduleWeekdayMask.value
            : this.scheduleWeekdayMask,
      );
  BlockListData copyWithCompanion(BlockListCompanion data) {
    return BlockListData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      reasonNote:
          data.reasonNote.present ? data.reasonNote.value : this.reasonNote,
      streakBreakThresholdMinutes: data.streakBreakThresholdMinutes.present
          ? data.streakBreakThresholdMinutes.value
          : this.streakBreakThresholdMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      blockMode: data.blockMode.present ? data.blockMode.value : this.blockMode,
      scheduleStartMinutes: data.scheduleStartMinutes.present
          ? data.scheduleStartMinutes.value
          : this.scheduleStartMinutes,
      scheduleEndMinutes: data.scheduleEndMinutes.present
          ? data.scheduleEndMinutes.value
          : this.scheduleEndMinutes,
      scheduleWeekdayMask: data.scheduleWeekdayMask.present
          ? data.scheduleWeekdayMask.value
          : this.scheduleWeekdayMask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockListData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('reasonNote: $reasonNote, ')
          ..write('streakBreakThresholdMinutes: $streakBreakThresholdMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blockMode: $blockMode, ')
          ..write('scheduleStartMinutes: $scheduleStartMinutes, ')
          ..write('scheduleEndMinutes: $scheduleEndMinutes, ')
          ..write('scheduleWeekdayMask: $scheduleWeekdayMask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      packageName,
      displayName,
      reasonNote,
      streakBreakThresholdMinutes,
      createdAt,
      updatedAt,
      blockMode,
      scheduleStartMinutes,
      scheduleEndMinutes,
      scheduleWeekdayMask);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockListData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.packageName == this.packageName &&
          other.displayName == this.displayName &&
          other.reasonNote == this.reasonNote &&
          other.streakBreakThresholdMinutes ==
              this.streakBreakThresholdMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.blockMode == this.blockMode &&
          other.scheduleStartMinutes == this.scheduleStartMinutes &&
          other.scheduleEndMinutes == this.scheduleEndMinutes &&
          other.scheduleWeekdayMask == this.scheduleWeekdayMask);
}

class BlockListCompanion extends UpdateCompanion<BlockListData> {
  final Value<int> id;
  final Value<int> kind;
  final Value<String?> packageName;
  final Value<String> displayName;
  final Value<String> reasonNote;
  final Value<int> streakBreakThresholdMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> blockMode;
  final Value<int?> scheduleStartMinutes;
  final Value<int?> scheduleEndMinutes;
  final Value<int?> scheduleWeekdayMask;
  const BlockListCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.packageName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.reasonNote = const Value.absent(),
    this.streakBreakThresholdMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.blockMode = const Value.absent(),
    this.scheduleStartMinutes = const Value.absent(),
    this.scheduleEndMinutes = const Value.absent(),
    this.scheduleWeekdayMask = const Value.absent(),
  });
  BlockListCompanion.insert({
    this.id = const Value.absent(),
    required int kind,
    this.packageName = const Value.absent(),
    required String displayName,
    this.reasonNote = const Value.absent(),
    this.streakBreakThresholdMinutes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.blockMode = const Value.absent(),
    this.scheduleStartMinutes = const Value.absent(),
    this.scheduleEndMinutes = const Value.absent(),
    this.scheduleWeekdayMask = const Value.absent(),
  })  : kind = Value(kind),
        displayName = Value(displayName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BlockListData> custom({
    Expression<int>? id,
    Expression<int>? kind,
    Expression<String>? packageName,
    Expression<String>? displayName,
    Expression<String>? reasonNote,
    Expression<int>? streakBreakThresholdMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? blockMode,
    Expression<int>? scheduleStartMinutes,
    Expression<int>? scheduleEndMinutes,
    Expression<int>? scheduleWeekdayMask,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (packageName != null) 'package_name': packageName,
      if (displayName != null) 'display_name': displayName,
      if (reasonNote != null) 'reason_note': reasonNote,
      if (streakBreakThresholdMinutes != null)
        'streak_break_threshold_minutes': streakBreakThresholdMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (blockMode != null) 'block_mode': blockMode,
      if (scheduleStartMinutes != null)
        'schedule_start_minutes': scheduleStartMinutes,
      if (scheduleEndMinutes != null)
        'schedule_end_minutes': scheduleEndMinutes,
      if (scheduleWeekdayMask != null)
        'schedule_weekday_mask': scheduleWeekdayMask,
    });
  }

  BlockListCompanion copyWith(
      {Value<int>? id,
      Value<int>? kind,
      Value<String?>? packageName,
      Value<String>? displayName,
      Value<String>? reasonNote,
      Value<int>? streakBreakThresholdMinutes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? blockMode,
      Value<int?>? scheduleStartMinutes,
      Value<int?>? scheduleEndMinutes,
      Value<int?>? scheduleWeekdayMask}) {
    return BlockListCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      reasonNote: reasonNote ?? this.reasonNote,
      streakBreakThresholdMinutes:
          streakBreakThresholdMinutes ?? this.streakBreakThresholdMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockMode: blockMode ?? this.blockMode,
      scheduleStartMinutes: scheduleStartMinutes ?? this.scheduleStartMinutes,
      scheduleEndMinutes: scheduleEndMinutes ?? this.scheduleEndMinutes,
      scheduleWeekdayMask: scheduleWeekdayMask ?? this.scheduleWeekdayMask,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (reasonNote.present) {
      map['reason_note'] = Variable<String>(reasonNote.value);
    }
    if (streakBreakThresholdMinutes.present) {
      map['streak_break_threshold_minutes'] =
          Variable<int>(streakBreakThresholdMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (blockMode.present) {
      map['block_mode'] = Variable<String>(blockMode.value);
    }
    if (scheduleStartMinutes.present) {
      map['schedule_start_minutes'] = Variable<int>(scheduleStartMinutes.value);
    }
    if (scheduleEndMinutes.present) {
      map['schedule_end_minutes'] = Variable<int>(scheduleEndMinutes.value);
    }
    if (scheduleWeekdayMask.present) {
      map['schedule_weekday_mask'] = Variable<int>(scheduleWeekdayMask.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockListCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('reasonNote: $reasonNote, ')
          ..write('streakBreakThresholdMinutes: $streakBreakThresholdMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('blockMode: $blockMode, ')
          ..write('scheduleStartMinutes: $scheduleStartMinutes, ')
          ..write('scheduleEndMinutes: $scheduleEndMinutes, ')
          ..write('scheduleWeekdayMask: $scheduleWeekdayMask')
          ..write(')'))
        .toString();
  }
}

class $DailyStreakTable extends DailyStreak
    with TableInfo<$DailyStreakTable, DailyStreakData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStreakTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES block_list (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
      'day', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _usageMinutesObservedMeta =
      const VerificationMeta('usageMinutesObserved');
  @override
  late final GeneratedColumn<int> usageMinutesObserved = GeneratedColumn<int>(
      'usage_minutes_observed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _evaluatedAtMeta =
      const VerificationMeta('evaluatedAt');
  @override
  late final GeneratedColumn<DateTime> evaluatedAt = GeneratedColumn<DateTime>(
      'evaluated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entryId, day, status, source, usageMinutesObserved, evaluatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_streak';
  @override
  VerificationContext validateIntegrity(Insertable<DailyStreakData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('usage_minutes_observed')) {
      context.handle(
          _usageMinutesObservedMeta,
          usageMinutesObserved.isAcceptableOrUnknown(
              data['usage_minutes_observed']!, _usageMinutesObservedMeta));
    }
    if (data.containsKey('evaluated_at')) {
      context.handle(
          _evaluatedAtMeta,
          evaluatedAt.isAcceptableOrUnknown(
              data['evaluated_at']!, _evaluatedAtMeta));
    } else if (isInserting) {
      context.missing(_evaluatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {entryId, day},
      ];
  @override
  DailyStreakData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStreakData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      usageMinutesObserved: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}usage_minutes_observed'])!,
      evaluatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}evaluated_at'])!,
    );
  }

  @override
  $DailyStreakTable createAlias(String alias) {
    return $DailyStreakTable(attachedDatabase, alias);
  }
}

class DailyStreakData extends DataClass implements Insertable<DailyStreakData> {
  final int id;
  final int entryId;
  final DateTime day;
  final int status;
  final int source;
  final int usageMinutesObserved;
  final DateTime evaluatedAt;
  const DailyStreakData(
      {required this.id,
      required this.entryId,
      required this.day,
      required this.status,
      required this.source,
      required this.usageMinutesObserved,
      required this.evaluatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['day'] = Variable<DateTime>(day);
    map['status'] = Variable<int>(status);
    map['source'] = Variable<int>(source);
    map['usage_minutes_observed'] = Variable<int>(usageMinutesObserved);
    map['evaluated_at'] = Variable<DateTime>(evaluatedAt);
    return map;
  }

  DailyStreakCompanion toCompanion(bool nullToAbsent) {
    return DailyStreakCompanion(
      id: Value(id),
      entryId: Value(entryId),
      day: Value(day),
      status: Value(status),
      source: Value(source),
      usageMinutesObserved: Value(usageMinutesObserved),
      evaluatedAt: Value(evaluatedAt),
    );
  }

  factory DailyStreakData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStreakData(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      day: serializer.fromJson<DateTime>(json['day']),
      status: serializer.fromJson<int>(json['status']),
      source: serializer.fromJson<int>(json['source']),
      usageMinutesObserved:
          serializer.fromJson<int>(json['usageMinutesObserved']),
      evaluatedAt: serializer.fromJson<DateTime>(json['evaluatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'day': serializer.toJson<DateTime>(day),
      'status': serializer.toJson<int>(status),
      'source': serializer.toJson<int>(source),
      'usageMinutesObserved': serializer.toJson<int>(usageMinutesObserved),
      'evaluatedAt': serializer.toJson<DateTime>(evaluatedAt),
    };
  }

  DailyStreakData copyWith(
          {int? id,
          int? entryId,
          DateTime? day,
          int? status,
          int? source,
          int? usageMinutesObserved,
          DateTime? evaluatedAt}) =>
      DailyStreakData(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        day: day ?? this.day,
        status: status ?? this.status,
        source: source ?? this.source,
        usageMinutesObserved: usageMinutesObserved ?? this.usageMinutesObserved,
        evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      );
  DailyStreakData copyWithCompanion(DailyStreakCompanion data) {
    return DailyStreakData(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      day: data.day.present ? data.day.value : this.day,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      usageMinutesObserved: data.usageMinutesObserved.present
          ? data.usageMinutesObserved.value
          : this.usageMinutesObserved,
      evaluatedAt:
          data.evaluatedAt.present ? data.evaluatedAt.value : this.evaluatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStreakData(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('usageMinutesObserved: $usageMinutesObserved, ')
          ..write('evaluatedAt: $evaluatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entryId, day, status, source, usageMinutesObserved, evaluatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStreakData &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.day == this.day &&
          other.status == this.status &&
          other.source == this.source &&
          other.usageMinutesObserved == this.usageMinutesObserved &&
          other.evaluatedAt == this.evaluatedAt);
}

class DailyStreakCompanion extends UpdateCompanion<DailyStreakData> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<DateTime> day;
  final Value<int> status;
  final Value<int> source;
  final Value<int> usageMinutesObserved;
  final Value<DateTime> evaluatedAt;
  const DailyStreakCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.day = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.usageMinutesObserved = const Value.absent(),
    this.evaluatedAt = const Value.absent(),
  });
  DailyStreakCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required DateTime day,
    required int status,
    required int source,
    this.usageMinutesObserved = const Value.absent(),
    required DateTime evaluatedAt,
  })  : entryId = Value(entryId),
        day = Value(day),
        status = Value(status),
        source = Value(source),
        evaluatedAt = Value(evaluatedAt);
  static Insertable<DailyStreakData> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<DateTime>? day,
    Expression<int>? status,
    Expression<int>? source,
    Expression<int>? usageMinutesObserved,
    Expression<DateTime>? evaluatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (day != null) 'day': day,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (usageMinutesObserved != null)
        'usage_minutes_observed': usageMinutesObserved,
      if (evaluatedAt != null) 'evaluated_at': evaluatedAt,
    });
  }

  DailyStreakCompanion copyWith(
      {Value<int>? id,
      Value<int>? entryId,
      Value<DateTime>? day,
      Value<int>? status,
      Value<int>? source,
      Value<int>? usageMinutesObserved,
      Value<DateTime>? evaluatedAt}) {
    return DailyStreakCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      day: day ?? this.day,
      status: status ?? this.status,
      source: source ?? this.source,
      usageMinutesObserved: usageMinutesObserved ?? this.usageMinutesObserved,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (usageMinutesObserved.present) {
      map['usage_minutes_observed'] = Variable<int>(usageMinutesObserved.value);
    }
    if (evaluatedAt.present) {
      map['evaluated_at'] = Variable<DateTime>(evaluatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStreakCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('day: $day, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('usageMinutesObserved: $usageMinutesObserved, ')
          ..write('evaluatedAt: $evaluatedAt')
          ..write(')'))
        .toString();
  }
}

class $PauseEventsTable extends PauseEvents
    with TableInfo<$PauseEventsTable, PauseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PauseEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES block_list (id) ON DELETE CASCADE'));
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _triggeredAtMeta =
      const VerificationMeta('triggeredAt');
  @override
  late final GeneratedColumn<DateTime> triggeredAt = GeneratedColumn<DateTime>(
      'triggered_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _cooldownChosenSecondsMeta =
      const VerificationMeta('cooldownChosenSeconds');
  @override
  late final GeneratedColumn<int> cooldownChosenSeconds = GeneratedColumn<int>(
      'cooldown_chosen_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _outcomeMeta =
      const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<int> outcome = GeneratedColumn<int>(
      'outcome', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entryId, packageName, triggeredAt, cooldownChosenSeconds, outcome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pause_events';
  @override
  VerificationContext validateIntegrity(Insertable<PauseEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('triggered_at')) {
      context.handle(
          _triggeredAtMeta,
          triggeredAt.isAcceptableOrUnknown(
              data['triggered_at']!, _triggeredAtMeta));
    } else if (isInserting) {
      context.missing(_triggeredAtMeta);
    }
    if (data.containsKey('cooldown_chosen_seconds')) {
      context.handle(
          _cooldownChosenSecondsMeta,
          cooldownChosenSeconds.isAcceptableOrUnknown(
              data['cooldown_chosen_seconds']!, _cooldownChosenSecondsMeta));
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta,
          outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PauseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PauseEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      triggeredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}triggered_at'])!,
      cooldownChosenSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cooldown_chosen_seconds']),
      outcome: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}outcome'])!,
    );
  }

  @override
  $PauseEventsTable createAlias(String alias) {
    return $PauseEventsTable(attachedDatabase, alias);
  }
}

class PauseEvent extends DataClass implements Insertable<PauseEvent> {
  final int id;
  final int entryId;
  final String packageName;
  final DateTime triggeredAt;
  final int? cooldownChosenSeconds;
  final int outcome;
  const PauseEvent(
      {required this.id,
      required this.entryId,
      required this.packageName,
      required this.triggeredAt,
      this.cooldownChosenSeconds,
      required this.outcome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['package_name'] = Variable<String>(packageName);
    map['triggered_at'] = Variable<DateTime>(triggeredAt);
    if (!nullToAbsent || cooldownChosenSeconds != null) {
      map['cooldown_chosen_seconds'] = Variable<int>(cooldownChosenSeconds);
    }
    map['outcome'] = Variable<int>(outcome);
    return map;
  }

  PauseEventsCompanion toCompanion(bool nullToAbsent) {
    return PauseEventsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      packageName: Value(packageName),
      triggeredAt: Value(triggeredAt),
      cooldownChosenSeconds: cooldownChosenSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(cooldownChosenSeconds),
      outcome: Value(outcome),
    );
  }

  factory PauseEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PauseEvent(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      triggeredAt: serializer.fromJson<DateTime>(json['triggeredAt']),
      cooldownChosenSeconds:
          serializer.fromJson<int?>(json['cooldownChosenSeconds']),
      outcome: serializer.fromJson<int>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'packageName': serializer.toJson<String>(packageName),
      'triggeredAt': serializer.toJson<DateTime>(triggeredAt),
      'cooldownChosenSeconds': serializer.toJson<int?>(cooldownChosenSeconds),
      'outcome': serializer.toJson<int>(outcome),
    };
  }

  PauseEvent copyWith(
          {int? id,
          int? entryId,
          String? packageName,
          DateTime? triggeredAt,
          Value<int?> cooldownChosenSeconds = const Value.absent(),
          int? outcome}) =>
      PauseEvent(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        packageName: packageName ?? this.packageName,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        cooldownChosenSeconds: cooldownChosenSeconds.present
            ? cooldownChosenSeconds.value
            : this.cooldownChosenSeconds,
        outcome: outcome ?? this.outcome,
      );
  PauseEvent copyWithCompanion(PauseEventsCompanion data) {
    return PauseEvent(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      triggeredAt:
          data.triggeredAt.present ? data.triggeredAt.value : this.triggeredAt,
      cooldownChosenSeconds: data.cooldownChosenSeconds.present
          ? data.cooldownChosenSeconds.value
          : this.cooldownChosenSeconds,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PauseEvent(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('packageName: $packageName, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('cooldownChosenSeconds: $cooldownChosenSeconds, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entryId, packageName, triggeredAt, cooldownChosenSeconds, outcome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PauseEvent &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.packageName == this.packageName &&
          other.triggeredAt == this.triggeredAt &&
          other.cooldownChosenSeconds == this.cooldownChosenSeconds &&
          other.outcome == this.outcome);
}

class PauseEventsCompanion extends UpdateCompanion<PauseEvent> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> packageName;
  final Value<DateTime> triggeredAt;
  final Value<int?> cooldownChosenSeconds;
  final Value<int> outcome;
  const PauseEventsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.triggeredAt = const Value.absent(),
    this.cooldownChosenSeconds = const Value.absent(),
    this.outcome = const Value.absent(),
  });
  PauseEventsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String packageName,
    required DateTime triggeredAt,
    this.cooldownChosenSeconds = const Value.absent(),
    required int outcome,
  })  : entryId = Value(entryId),
        packageName = Value(packageName),
        triggeredAt = Value(triggeredAt),
        outcome = Value(outcome);
  static Insertable<PauseEvent> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? packageName,
    Expression<DateTime>? triggeredAt,
    Expression<int>? cooldownChosenSeconds,
    Expression<int>? outcome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (packageName != null) 'package_name': packageName,
      if (triggeredAt != null) 'triggered_at': triggeredAt,
      if (cooldownChosenSeconds != null)
        'cooldown_chosen_seconds': cooldownChosenSeconds,
      if (outcome != null) 'outcome': outcome,
    });
  }

  PauseEventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? entryId,
      Value<String>? packageName,
      Value<DateTime>? triggeredAt,
      Value<int?>? cooldownChosenSeconds,
      Value<int>? outcome}) {
    return PauseEventsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      packageName: packageName ?? this.packageName,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      cooldownChosenSeconds:
          cooldownChosenSeconds ?? this.cooldownChosenSeconds,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (triggeredAt.present) {
      map['triggered_at'] = Variable<DateTime>(triggeredAt.value);
    }
    if (cooldownChosenSeconds.present) {
      map['cooldown_chosen_seconds'] =
          Variable<int>(cooldownChosenSeconds.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(outcome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PauseEventsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('packageName: $packageName, ')
          ..write('triggeredAt: $triggeredAt, ')
          ..write('cooldownChosenSeconds: $cooldownChosenSeconds, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }
}

class $DailyCheckinsTable extends DailyCheckins
    with TableInfo<$DailyCheckinsTable, DailyCheckin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCheckinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
      'entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES block_list (id) ON DELETE CASCADE'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
      'day', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _avoidedMeta =
      const VerificationMeta('avoided');
  @override
  late final GeneratedColumn<bool> avoided = GeneratedColumn<bool>(
      'avoided', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("avoided" IN (0, 1))'));
  static const VerificationMeta _answeredAtMeta =
      const VerificationMeta('answeredAt');
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
      'answered_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, entryId, day, avoided, answeredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_checkins';
  @override
  VerificationContext validateIntegrity(Insertable<DailyCheckin> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('avoided')) {
      context.handle(_avoidedMeta,
          avoided.isAcceptableOrUnknown(data['avoided']!, _avoidedMeta));
    } else if (isInserting) {
      context.missing(_avoidedMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
          _answeredAtMeta,
          answeredAt.isAcceptableOrUnknown(
              data['answered_at']!, _answeredAtMeta));
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {entryId, day},
      ];
  @override
  DailyCheckin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCheckin(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      avoided: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}avoided'])!,
      answeredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}answered_at'])!,
    );
  }

  @override
  $DailyCheckinsTable createAlias(String alias) {
    return $DailyCheckinsTable(attachedDatabase, alias);
  }
}

class DailyCheckin extends DataClass implements Insertable<DailyCheckin> {
  final int id;
  final int entryId;
  final DateTime day;
  final bool avoided;
  final DateTime answeredAt;
  const DailyCheckin(
      {required this.id,
      required this.entryId,
      required this.day,
      required this.avoided,
      required this.answeredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['day'] = Variable<DateTime>(day);
    map['avoided'] = Variable<bool>(avoided);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  DailyCheckinsCompanion toCompanion(bool nullToAbsent) {
    return DailyCheckinsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      day: Value(day),
      avoided: Value(avoided),
      answeredAt: Value(answeredAt),
    );
  }

  factory DailyCheckin.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCheckin(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      day: serializer.fromJson<DateTime>(json['day']),
      avoided: serializer.fromJson<bool>(json['avoided']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'day': serializer.toJson<DateTime>(day),
      'avoided': serializer.toJson<bool>(avoided),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  DailyCheckin copyWith(
          {int? id,
          int? entryId,
          DateTime? day,
          bool? avoided,
          DateTime? answeredAt}) =>
      DailyCheckin(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        day: day ?? this.day,
        avoided: avoided ?? this.avoided,
        answeredAt: answeredAt ?? this.answeredAt,
      );
  DailyCheckin copyWithCompanion(DailyCheckinsCompanion data) {
    return DailyCheckin(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      day: data.day.present ? data.day.value : this.day,
      avoided: data.avoided.present ? data.avoided.value : this.avoided,
      answeredAt:
          data.answeredAt.present ? data.answeredAt.value : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCheckin(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('day: $day, ')
          ..write('avoided: $avoided, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, day, avoided, answeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCheckin &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.day == this.day &&
          other.avoided == this.avoided &&
          other.answeredAt == this.answeredAt);
}

class DailyCheckinsCompanion extends UpdateCompanion<DailyCheckin> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<DateTime> day;
  final Value<bool> avoided;
  final Value<DateTime> answeredAt;
  const DailyCheckinsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.day = const Value.absent(),
    this.avoided = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  DailyCheckinsCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required DateTime day,
    required bool avoided,
    required DateTime answeredAt,
  })  : entryId = Value(entryId),
        day = Value(day),
        avoided = Value(avoided),
        answeredAt = Value(answeredAt);
  static Insertable<DailyCheckin> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<DateTime>? day,
    Expression<bool>? avoided,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (day != null) 'day': day,
      if (avoided != null) 'avoided': avoided,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  DailyCheckinsCompanion copyWith(
      {Value<int>? id,
      Value<int>? entryId,
      Value<DateTime>? day,
      Value<bool>? avoided,
      Value<DateTime>? answeredAt}) {
    return DailyCheckinsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      day: day ?? this.day,
      avoided: avoided ?? this.avoided,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (avoided.present) {
      map['avoided'] = Variable<bool>(avoided.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCheckinsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('day: $day, ')
          ..write('avoided: $avoided, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

class $DailyUsageSummaryTable extends DailyUsageSummary
    with TableInfo<$DailyUsageSummaryTable, DailyUsageSummaryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyUsageSummaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
      'day', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _foregroundSecondsMeta =
      const VerificationMeta('foregroundSeconds');
  @override
  late final GeneratedColumn<int> foregroundSeconds = GeneratedColumn<int>(
      'foreground_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _launchCountMeta =
      const VerificationMeta('launchCount');
  @override
  late final GeneratedColumn<int> launchCount = GeneratedColumn<int>(
      'launch_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _aggregatedAtMeta =
      const VerificationMeta('aggregatedAt');
  @override
  late final GeneratedColumn<DateTime> aggregatedAt = GeneratedColumn<DateTime>(
      'aggregated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, packageName, day, foregroundSeconds, launchCount, aggregatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_usage_summary';
  @override
  VerificationContext validateIntegrity(
      Insertable<DailyUsageSummaryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('foreground_seconds')) {
      context.handle(
          _foregroundSecondsMeta,
          foregroundSeconds.isAcceptableOrUnknown(
              data['foreground_seconds']!, _foregroundSecondsMeta));
    } else if (isInserting) {
      context.missing(_foregroundSecondsMeta);
    }
    if (data.containsKey('launch_count')) {
      context.handle(
          _launchCountMeta,
          launchCount.isAcceptableOrUnknown(
              data['launch_count']!, _launchCountMeta));
    }
    if (data.containsKey('aggregated_at')) {
      context.handle(
          _aggregatedAtMeta,
          aggregatedAt.isAcceptableOrUnknown(
              data['aggregated_at']!, _aggregatedAtMeta));
    } else if (isInserting) {
      context.missing(_aggregatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {packageName, day},
      ];
  @override
  DailyUsageSummaryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyUsageSummaryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      foregroundSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}foreground_seconds'])!,
      launchCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}launch_count'])!,
      aggregatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}aggregated_at'])!,
    );
  }

  @override
  $DailyUsageSummaryTable createAlias(String alias) {
    return $DailyUsageSummaryTable(attachedDatabase, alias);
  }
}

class DailyUsageSummaryData extends DataClass
    implements Insertable<DailyUsageSummaryData> {
  final int id;
  final String packageName;
  final DateTime day;
  final int foregroundSeconds;
  final int launchCount;
  final DateTime aggregatedAt;
  const DailyUsageSummaryData(
      {required this.id,
      required this.packageName,
      required this.day,
      required this.foregroundSeconds,
      required this.launchCount,
      required this.aggregatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package_name'] = Variable<String>(packageName);
    map['day'] = Variable<DateTime>(day);
    map['foreground_seconds'] = Variable<int>(foregroundSeconds);
    map['launch_count'] = Variable<int>(launchCount);
    map['aggregated_at'] = Variable<DateTime>(aggregatedAt);
    return map;
  }

  DailyUsageSummaryCompanion toCompanion(bool nullToAbsent) {
    return DailyUsageSummaryCompanion(
      id: Value(id),
      packageName: Value(packageName),
      day: Value(day),
      foregroundSeconds: Value(foregroundSeconds),
      launchCount: Value(launchCount),
      aggregatedAt: Value(aggregatedAt),
    );
  }

  factory DailyUsageSummaryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyUsageSummaryData(
      id: serializer.fromJson<int>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      day: serializer.fromJson<DateTime>(json['day']),
      foregroundSeconds: serializer.fromJson<int>(json['foregroundSeconds']),
      launchCount: serializer.fromJson<int>(json['launchCount']),
      aggregatedAt: serializer.fromJson<DateTime>(json['aggregatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packageName': serializer.toJson<String>(packageName),
      'day': serializer.toJson<DateTime>(day),
      'foregroundSeconds': serializer.toJson<int>(foregroundSeconds),
      'launchCount': serializer.toJson<int>(launchCount),
      'aggregatedAt': serializer.toJson<DateTime>(aggregatedAt),
    };
  }

  DailyUsageSummaryData copyWith(
          {int? id,
          String? packageName,
          DateTime? day,
          int? foregroundSeconds,
          int? launchCount,
          DateTime? aggregatedAt}) =>
      DailyUsageSummaryData(
        id: id ?? this.id,
        packageName: packageName ?? this.packageName,
        day: day ?? this.day,
        foregroundSeconds: foregroundSeconds ?? this.foregroundSeconds,
        launchCount: launchCount ?? this.launchCount,
        aggregatedAt: aggregatedAt ?? this.aggregatedAt,
      );
  DailyUsageSummaryData copyWithCompanion(DailyUsageSummaryCompanion data) {
    return DailyUsageSummaryData(
      id: data.id.present ? data.id.value : this.id,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      day: data.day.present ? data.day.value : this.day,
      foregroundSeconds: data.foregroundSeconds.present
          ? data.foregroundSeconds.value
          : this.foregroundSeconds,
      launchCount:
          data.launchCount.present ? data.launchCount.value : this.launchCount,
      aggregatedAt: data.aggregatedAt.present
          ? data.aggregatedAt.value
          : this.aggregatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageSummaryData(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('day: $day, ')
          ..write('foregroundSeconds: $foregroundSeconds, ')
          ..write('launchCount: $launchCount, ')
          ..write('aggregatedAt: $aggregatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, packageName, day, foregroundSeconds, launchCount, aggregatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyUsageSummaryData &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.day == this.day &&
          other.foregroundSeconds == this.foregroundSeconds &&
          other.launchCount == this.launchCount &&
          other.aggregatedAt == this.aggregatedAt);
}

class DailyUsageSummaryCompanion
    extends UpdateCompanion<DailyUsageSummaryData> {
  final Value<int> id;
  final Value<String> packageName;
  final Value<DateTime> day;
  final Value<int> foregroundSeconds;
  final Value<int> launchCount;
  final Value<DateTime> aggregatedAt;
  const DailyUsageSummaryCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.day = const Value.absent(),
    this.foregroundSeconds = const Value.absent(),
    this.launchCount = const Value.absent(),
    this.aggregatedAt = const Value.absent(),
  });
  DailyUsageSummaryCompanion.insert({
    this.id = const Value.absent(),
    required String packageName,
    required DateTime day,
    required int foregroundSeconds,
    this.launchCount = const Value.absent(),
    required DateTime aggregatedAt,
  })  : packageName = Value(packageName),
        day = Value(day),
        foregroundSeconds = Value(foregroundSeconds),
        aggregatedAt = Value(aggregatedAt);
  static Insertable<DailyUsageSummaryData> custom({
    Expression<int>? id,
    Expression<String>? packageName,
    Expression<DateTime>? day,
    Expression<int>? foregroundSeconds,
    Expression<int>? launchCount,
    Expression<DateTime>? aggregatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (day != null) 'day': day,
      if (foregroundSeconds != null) 'foreground_seconds': foregroundSeconds,
      if (launchCount != null) 'launch_count': launchCount,
      if (aggregatedAt != null) 'aggregated_at': aggregatedAt,
    });
  }

  DailyUsageSummaryCompanion copyWith(
      {Value<int>? id,
      Value<String>? packageName,
      Value<DateTime>? day,
      Value<int>? foregroundSeconds,
      Value<int>? launchCount,
      Value<DateTime>? aggregatedAt}) {
    return DailyUsageSummaryCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      day: day ?? this.day,
      foregroundSeconds: foregroundSeconds ?? this.foregroundSeconds,
      launchCount: launchCount ?? this.launchCount,
      aggregatedAt: aggregatedAt ?? this.aggregatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (foregroundSeconds.present) {
      map['foreground_seconds'] = Variable<int>(foregroundSeconds.value);
    }
    if (launchCount.present) {
      map['launch_count'] = Variable<int>(launchCount.value);
    }
    if (aggregatedAt.present) {
      map['aggregated_at'] = Variable<DateTime>(aggregatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageSummaryCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('day: $day, ')
          ..write('foregroundSeconds: $foregroundSeconds, ')
          ..write('launchCount: $launchCount, ')
          ..write('aggregatedAt: $aggregatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BlockListTable blockList = $BlockListTable(this);
  late final $DailyStreakTable dailyStreak = $DailyStreakTable(this);
  late final $PauseEventsTable pauseEvents = $PauseEventsTable(this);
  late final $DailyCheckinsTable dailyCheckins = $DailyCheckinsTable(this);
  late final $DailyUsageSummaryTable dailyUsageSummary =
      $DailyUsageSummaryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [blockList, dailyStreak, pauseEvents, dailyCheckins, dailyUsageSummary];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('block_list',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_streak', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('block_list',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('pause_events', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('block_list',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('daily_checkins', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$BlockListTableCreateCompanionBuilder = BlockListCompanion Function({
  Value<int> id,
  required int kind,
  Value<String?> packageName,
  required String displayName,
  Value<String> reasonNote,
  Value<int> streakBreakThresholdMinutes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> blockMode,
  Value<int?> scheduleStartMinutes,
  Value<int?> scheduleEndMinutes,
  Value<int?> scheduleWeekdayMask,
});
typedef $$BlockListTableUpdateCompanionBuilder = BlockListCompanion Function({
  Value<int> id,
  Value<int> kind,
  Value<String?> packageName,
  Value<String> displayName,
  Value<String> reasonNote,
  Value<int> streakBreakThresholdMinutes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> blockMode,
  Value<int?> scheduleStartMinutes,
  Value<int?> scheduleEndMinutes,
  Value<int?> scheduleWeekdayMask,
});

final class $$BlockListTableReferences
    extends BaseReferences<_$AppDatabase, $BlockListTable, BlockListData> {
  $$BlockListTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DailyStreakTable, List<DailyStreakData>>
      _dailyStreakRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.dailyStreak,
          aliasName:
              $_aliasNameGenerator(db.blockList.id, db.dailyStreak.entryId));

  $$DailyStreakTableProcessedTableManager get dailyStreakRefs {
    final manager = $$DailyStreakTableTableManager($_db, $_db.dailyStreak)
        .filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyStreakRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PauseEventsTable, List<PauseEvent>>
      _pauseEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.pauseEvents,
          aliasName:
              $_aliasNameGenerator(db.blockList.id, db.pauseEvents.entryId));

  $$PauseEventsTableProcessedTableManager get pauseEventsRefs {
    final manager = $$PauseEventsTableTableManager($_db, $_db.pauseEvents)
        .filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pauseEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DailyCheckinsTable, List<DailyCheckin>>
      _dailyCheckinsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.dailyCheckins,
              aliasName: $_aliasNameGenerator(
                  db.blockList.id, db.dailyCheckins.entryId));

  $$DailyCheckinsTableProcessedTableManager get dailyCheckinsRefs {
    final manager = $$DailyCheckinsTableTableManager($_db, $_db.dailyCheckins)
        .filter((f) => f.entryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyCheckinsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BlockListTableFilterComposer
    extends Composer<_$AppDatabase, $BlockListTable> {
  $$BlockListTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonNote => $composableBuilder(
      column: $table.reasonNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streakBreakThresholdMinutes => $composableBuilder(
      column: $table.streakBreakThresholdMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockMode => $composableBuilder(
      column: $table.blockMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduleStartMinutes => $composableBuilder(
      column: $table.scheduleStartMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduleEndMinutes => $composableBuilder(
      column: $table.scheduleEndMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduleWeekdayMask => $composableBuilder(
      column: $table.scheduleWeekdayMask,
      builder: (column) => ColumnFilters(column));

  Expression<bool> dailyStreakRefs(
      Expression<bool> Function($$DailyStreakTableFilterComposer f) f) {
    final $$DailyStreakTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyStreak,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyStreakTableFilterComposer(
              $db: $db,
              $table: $db.dailyStreak,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pauseEventsRefs(
      Expression<bool> Function($$PauseEventsTableFilterComposer f) f) {
    final $$PauseEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pauseEvents,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PauseEventsTableFilterComposer(
              $db: $db,
              $table: $db.pauseEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> dailyCheckinsRefs(
      Expression<bool> Function($$DailyCheckinsTableFilterComposer f) f) {
    final $$DailyCheckinsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyCheckins,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyCheckinsTableFilterComposer(
              $db: $db,
              $table: $db.dailyCheckins,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlockListTableOrderingComposer
    extends Composer<_$AppDatabase, $BlockListTable> {
  $$BlockListTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonNote => $composableBuilder(
      column: $table.reasonNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streakBreakThresholdMinutes => $composableBuilder(
      column: $table.streakBreakThresholdMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockMode => $composableBuilder(
      column: $table.blockMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduleStartMinutes => $composableBuilder(
      column: $table.scheduleStartMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduleEndMinutes => $composableBuilder(
      column: $table.scheduleEndMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduleWeekdayMask => $composableBuilder(
      column: $table.scheduleWeekdayMask,
      builder: (column) => ColumnOrderings(column));
}

class $$BlockListTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlockListTable> {
  $$BlockListTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get reasonNote => $composableBuilder(
      column: $table.reasonNote, builder: (column) => column);

  GeneratedColumn<int> get streakBreakThresholdMinutes => $composableBuilder(
      column: $table.streakBreakThresholdMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get blockMode =>
      $composableBuilder(column: $table.blockMode, builder: (column) => column);

  GeneratedColumn<int> get scheduleStartMinutes => $composableBuilder(
      column: $table.scheduleStartMinutes, builder: (column) => column);

  GeneratedColumn<int> get scheduleEndMinutes => $composableBuilder(
      column: $table.scheduleEndMinutes, builder: (column) => column);

  GeneratedColumn<int> get scheduleWeekdayMask => $composableBuilder(
      column: $table.scheduleWeekdayMask, builder: (column) => column);

  Expression<T> dailyStreakRefs<T extends Object>(
      Expression<T> Function($$DailyStreakTableAnnotationComposer a) f) {
    final $$DailyStreakTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyStreak,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyStreakTableAnnotationComposer(
              $db: $db,
              $table: $db.dailyStreak,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pauseEventsRefs<T extends Object>(
      Expression<T> Function($$PauseEventsTableAnnotationComposer a) f) {
    final $$PauseEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.pauseEvents,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PauseEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.pauseEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> dailyCheckinsRefs<T extends Object>(
      Expression<T> Function($$DailyCheckinsTableAnnotationComposer a) f) {
    final $$DailyCheckinsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.dailyCheckins,
        getReferencedColumn: (t) => t.entryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DailyCheckinsTableAnnotationComposer(
              $db: $db,
              $table: $db.dailyCheckins,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BlockListTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BlockListTable,
    BlockListData,
    $$BlockListTableFilterComposer,
    $$BlockListTableOrderingComposer,
    $$BlockListTableAnnotationComposer,
    $$BlockListTableCreateCompanionBuilder,
    $$BlockListTableUpdateCompanionBuilder,
    (BlockListData, $$BlockListTableReferences),
    BlockListData,
    PrefetchHooks Function(
        {bool dailyStreakRefs, bool pauseEventsRefs, bool dailyCheckinsRefs})> {
  $$BlockListTableTableManager(_$AppDatabase db, $BlockListTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockListTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockListTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockListTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> kind = const Value.absent(),
            Value<String?> packageName = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> reasonNote = const Value.absent(),
            Value<int> streakBreakThresholdMinutes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> blockMode = const Value.absent(),
            Value<int?> scheduleStartMinutes = const Value.absent(),
            Value<int?> scheduleEndMinutes = const Value.absent(),
            Value<int?> scheduleWeekdayMask = const Value.absent(),
          }) =>
              BlockListCompanion(
            id: id,
            kind: kind,
            packageName: packageName,
            displayName: displayName,
            reasonNote: reasonNote,
            streakBreakThresholdMinutes: streakBreakThresholdMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            blockMode: blockMode,
            scheduleStartMinutes: scheduleStartMinutes,
            scheduleEndMinutes: scheduleEndMinutes,
            scheduleWeekdayMask: scheduleWeekdayMask,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int kind,
            Value<String?> packageName = const Value.absent(),
            required String displayName,
            Value<String> reasonNote = const Value.absent(),
            Value<int> streakBreakThresholdMinutes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> blockMode = const Value.absent(),
            Value<int?> scheduleStartMinutes = const Value.absent(),
            Value<int?> scheduleEndMinutes = const Value.absent(),
            Value<int?> scheduleWeekdayMask = const Value.absent(),
          }) =>
              BlockListCompanion.insert(
            id: id,
            kind: kind,
            packageName: packageName,
            displayName: displayName,
            reasonNote: reasonNote,
            streakBreakThresholdMinutes: streakBreakThresholdMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            blockMode: blockMode,
            scheduleStartMinutes: scheduleStartMinutes,
            scheduleEndMinutes: scheduleEndMinutes,
            scheduleWeekdayMask: scheduleWeekdayMask,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BlockListTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {dailyStreakRefs = false,
              pauseEventsRefs = false,
              dailyCheckinsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dailyStreakRefs) db.dailyStreak,
                if (pauseEventsRefs) db.pauseEvents,
                if (dailyCheckinsRefs) db.dailyCheckins
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyStreakRefs)
                    await $_getPrefetchedData<BlockListData, $BlockListTable,
                            DailyStreakData>(
                        currentTable: table,
                        referencedTable: $$BlockListTableReferences
                            ._dailyStreakRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlockListTableReferences(db, table, p0)
                                .dailyStreakRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.entryId == item.id),
                        typedResults: items),
                  if (pauseEventsRefs)
                    await $_getPrefetchedData<BlockListData, $BlockListTable,
                            PauseEvent>(
                        currentTable: table,
                        referencedTable: $$BlockListTableReferences
                            ._pauseEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlockListTableReferences(db, table, p0)
                                .pauseEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.entryId == item.id),
                        typedResults: items),
                  if (dailyCheckinsRefs)
                    await $_getPrefetchedData<BlockListData, $BlockListTable,
                            DailyCheckin>(
                        currentTable: table,
                        referencedTable: $$BlockListTableReferences
                            ._dailyCheckinsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BlockListTableReferences(db, table, p0)
                                .dailyCheckinsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.entryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BlockListTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BlockListTable,
    BlockListData,
    $$BlockListTableFilterComposer,
    $$BlockListTableOrderingComposer,
    $$BlockListTableAnnotationComposer,
    $$BlockListTableCreateCompanionBuilder,
    $$BlockListTableUpdateCompanionBuilder,
    (BlockListData, $$BlockListTableReferences),
    BlockListData,
    PrefetchHooks Function(
        {bool dailyStreakRefs, bool pauseEventsRefs, bool dailyCheckinsRefs})>;
typedef $$DailyStreakTableCreateCompanionBuilder = DailyStreakCompanion
    Function({
  Value<int> id,
  required int entryId,
  required DateTime day,
  required int status,
  required int source,
  Value<int> usageMinutesObserved,
  required DateTime evaluatedAt,
});
typedef $$DailyStreakTableUpdateCompanionBuilder = DailyStreakCompanion
    Function({
  Value<int> id,
  Value<int> entryId,
  Value<DateTime> day,
  Value<int> status,
  Value<int> source,
  Value<int> usageMinutesObserved,
  Value<DateTime> evaluatedAt,
});

final class $$DailyStreakTableReferences
    extends BaseReferences<_$AppDatabase, $DailyStreakTable, DailyStreakData> {
  $$DailyStreakTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BlockListTable _entryIdTable(_$AppDatabase db) =>
      db.blockList.createAlias(
          $_aliasNameGenerator(db.dailyStreak.entryId, db.blockList.id));

  $$BlockListTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$BlockListTableTableManager($_db, $_db.blockList)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DailyStreakTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStreakTable> {
  $$DailyStreakTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageMinutesObserved => $composableBuilder(
      column: $table.usageMinutesObserved,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get evaluatedAt => $composableBuilder(
      column: $table.evaluatedAt, builder: (column) => ColumnFilters(column));

  $$BlockListTableFilterComposer get entryId {
    final $$BlockListTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableFilterComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyStreakTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStreakTable> {
  $$DailyStreakTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageMinutesObserved => $composableBuilder(
      column: $table.usageMinutesObserved,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get evaluatedAt => $composableBuilder(
      column: $table.evaluatedAt, builder: (column) => ColumnOrderings(column));

  $$BlockListTableOrderingComposer get entryId {
    final $$BlockListTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableOrderingComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyStreakTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStreakTable> {
  $$DailyStreakTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get usageMinutesObserved => $composableBuilder(
      column: $table.usageMinutesObserved, builder: (column) => column);

  GeneratedColumn<DateTime> get evaluatedAt => $composableBuilder(
      column: $table.evaluatedAt, builder: (column) => column);

  $$BlockListTableAnnotationComposer get entryId {
    final $$BlockListTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableAnnotationComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyStreakTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyStreakTable,
    DailyStreakData,
    $$DailyStreakTableFilterComposer,
    $$DailyStreakTableOrderingComposer,
    $$DailyStreakTableAnnotationComposer,
    $$DailyStreakTableCreateCompanionBuilder,
    $$DailyStreakTableUpdateCompanionBuilder,
    (DailyStreakData, $$DailyStreakTableReferences),
    DailyStreakData,
    PrefetchHooks Function({bool entryId})> {
  $$DailyStreakTableTableManager(_$AppDatabase db, $DailyStreakTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStreakTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStreakTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStreakTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> entryId = const Value.absent(),
            Value<DateTime> day = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<int> usageMinutesObserved = const Value.absent(),
            Value<DateTime> evaluatedAt = const Value.absent(),
          }) =>
              DailyStreakCompanion(
            id: id,
            entryId: entryId,
            day: day,
            status: status,
            source: source,
            usageMinutesObserved: usageMinutesObserved,
            evaluatedAt: evaluatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int entryId,
            required DateTime day,
            required int status,
            required int source,
            Value<int> usageMinutesObserved = const Value.absent(),
            required DateTime evaluatedAt,
          }) =>
              DailyStreakCompanion.insert(
            id: id,
            entryId: entryId,
            day: day,
            status: status,
            source: source,
            usageMinutesObserved: usageMinutesObserved,
            evaluatedAt: evaluatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DailyStreakTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (entryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.entryId,
                    referencedTable:
                        $$DailyStreakTableReferences._entryIdTable(db),
                    referencedColumn:
                        $$DailyStreakTableReferences._entryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DailyStreakTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyStreakTable,
    DailyStreakData,
    $$DailyStreakTableFilterComposer,
    $$DailyStreakTableOrderingComposer,
    $$DailyStreakTableAnnotationComposer,
    $$DailyStreakTableCreateCompanionBuilder,
    $$DailyStreakTableUpdateCompanionBuilder,
    (DailyStreakData, $$DailyStreakTableReferences),
    DailyStreakData,
    PrefetchHooks Function({bool entryId})>;
typedef $$PauseEventsTableCreateCompanionBuilder = PauseEventsCompanion
    Function({
  Value<int> id,
  required int entryId,
  required String packageName,
  required DateTime triggeredAt,
  Value<int?> cooldownChosenSeconds,
  required int outcome,
});
typedef $$PauseEventsTableUpdateCompanionBuilder = PauseEventsCompanion
    Function({
  Value<int> id,
  Value<int> entryId,
  Value<String> packageName,
  Value<DateTime> triggeredAt,
  Value<int?> cooldownChosenSeconds,
  Value<int> outcome,
});

final class $$PauseEventsTableReferences
    extends BaseReferences<_$AppDatabase, $PauseEventsTable, PauseEvent> {
  $$PauseEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BlockListTable _entryIdTable(_$AppDatabase db) =>
      db.blockList.createAlias(
          $_aliasNameGenerator(db.pauseEvents.entryId, db.blockList.id));

  $$BlockListTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$BlockListTableTableManager($_db, $_db.blockList)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PauseEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PauseEventsTable> {
  $$PauseEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get triggeredAt => $composableBuilder(
      column: $table.triggeredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cooldownChosenSeconds => $composableBuilder(
      column: $table.cooldownChosenSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnFilters(column));

  $$BlockListTableFilterComposer get entryId {
    final $$BlockListTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableFilterComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PauseEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PauseEventsTable> {
  $$PauseEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get triggeredAt => $composableBuilder(
      column: $table.triggeredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cooldownChosenSeconds => $composableBuilder(
      column: $table.cooldownChosenSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  $$BlockListTableOrderingComposer get entryId {
    final $$BlockListTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableOrderingComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PauseEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PauseEventsTable> {
  $$PauseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => column);

  GeneratedColumn<DateTime> get triggeredAt => $composableBuilder(
      column: $table.triggeredAt, builder: (column) => column);

  GeneratedColumn<int> get cooldownChosenSeconds => $composableBuilder(
      column: $table.cooldownChosenSeconds, builder: (column) => column);

  GeneratedColumn<int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  $$BlockListTableAnnotationComposer get entryId {
    final $$BlockListTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableAnnotationComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PauseEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PauseEventsTable,
    PauseEvent,
    $$PauseEventsTableFilterComposer,
    $$PauseEventsTableOrderingComposer,
    $$PauseEventsTableAnnotationComposer,
    $$PauseEventsTableCreateCompanionBuilder,
    $$PauseEventsTableUpdateCompanionBuilder,
    (PauseEvent, $$PauseEventsTableReferences),
    PauseEvent,
    PrefetchHooks Function({bool entryId})> {
  $$PauseEventsTableTableManager(_$AppDatabase db, $PauseEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PauseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PauseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PauseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> entryId = const Value.absent(),
            Value<String> packageName = const Value.absent(),
            Value<DateTime> triggeredAt = const Value.absent(),
            Value<int?> cooldownChosenSeconds = const Value.absent(),
            Value<int> outcome = const Value.absent(),
          }) =>
              PauseEventsCompanion(
            id: id,
            entryId: entryId,
            packageName: packageName,
            triggeredAt: triggeredAt,
            cooldownChosenSeconds: cooldownChosenSeconds,
            outcome: outcome,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int entryId,
            required String packageName,
            required DateTime triggeredAt,
            Value<int?> cooldownChosenSeconds = const Value.absent(),
            required int outcome,
          }) =>
              PauseEventsCompanion.insert(
            id: id,
            entryId: entryId,
            packageName: packageName,
            triggeredAt: triggeredAt,
            cooldownChosenSeconds: cooldownChosenSeconds,
            outcome: outcome,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PauseEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (entryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.entryId,
                    referencedTable:
                        $$PauseEventsTableReferences._entryIdTable(db),
                    referencedColumn:
                        $$PauseEventsTableReferences._entryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PauseEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PauseEventsTable,
    PauseEvent,
    $$PauseEventsTableFilterComposer,
    $$PauseEventsTableOrderingComposer,
    $$PauseEventsTableAnnotationComposer,
    $$PauseEventsTableCreateCompanionBuilder,
    $$PauseEventsTableUpdateCompanionBuilder,
    (PauseEvent, $$PauseEventsTableReferences),
    PauseEvent,
    PrefetchHooks Function({bool entryId})>;
typedef $$DailyCheckinsTableCreateCompanionBuilder = DailyCheckinsCompanion
    Function({
  Value<int> id,
  required int entryId,
  required DateTime day,
  required bool avoided,
  required DateTime answeredAt,
});
typedef $$DailyCheckinsTableUpdateCompanionBuilder = DailyCheckinsCompanion
    Function({
  Value<int> id,
  Value<int> entryId,
  Value<DateTime> day,
  Value<bool> avoided,
  Value<DateTime> answeredAt,
});

final class $$DailyCheckinsTableReferences
    extends BaseReferences<_$AppDatabase, $DailyCheckinsTable, DailyCheckin> {
  $$DailyCheckinsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BlockListTable _entryIdTable(_$AppDatabase db) =>
      db.blockList.createAlias(
          $_aliasNameGenerator(db.dailyCheckins.entryId, db.blockList.id));

  $$BlockListTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<int>('entry_id')!;

    final manager = $$BlockListTableTableManager($_db, $_db.blockList)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DailyCheckinsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get avoided => $composableBuilder(
      column: $table.avoided, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnFilters(column));

  $$BlockListTableFilterComposer get entryId {
    final $$BlockListTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableFilterComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyCheckinsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get avoided => $composableBuilder(
      column: $table.avoided, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => ColumnOrderings(column));

  $$BlockListTableOrderingComposer get entryId {
    final $$BlockListTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableOrderingComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyCheckinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCheckinsTable> {
  $$DailyCheckinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<bool> get avoided =>
      $composableBuilder(column: $table.avoided, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
      column: $table.answeredAt, builder: (column) => column);

  $$BlockListTableAnnotationComposer get entryId {
    final $$BlockListTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.entryId,
        referencedTable: $db.blockList,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BlockListTableAnnotationComposer(
              $db: $db,
              $table: $db.blockList,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DailyCheckinsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyCheckinsTable,
    DailyCheckin,
    $$DailyCheckinsTableFilterComposer,
    $$DailyCheckinsTableOrderingComposer,
    $$DailyCheckinsTableAnnotationComposer,
    $$DailyCheckinsTableCreateCompanionBuilder,
    $$DailyCheckinsTableUpdateCompanionBuilder,
    (DailyCheckin, $$DailyCheckinsTableReferences),
    DailyCheckin,
    PrefetchHooks Function({bool entryId})> {
  $$DailyCheckinsTableTableManager(_$AppDatabase db, $DailyCheckinsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCheckinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyCheckinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyCheckinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> entryId = const Value.absent(),
            Value<DateTime> day = const Value.absent(),
            Value<bool> avoided = const Value.absent(),
            Value<DateTime> answeredAt = const Value.absent(),
          }) =>
              DailyCheckinsCompanion(
            id: id,
            entryId: entryId,
            day: day,
            avoided: avoided,
            answeredAt: answeredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int entryId,
            required DateTime day,
            required bool avoided,
            required DateTime answeredAt,
          }) =>
              DailyCheckinsCompanion.insert(
            id: id,
            entryId: entryId,
            day: day,
            avoided: avoided,
            answeredAt: answeredAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DailyCheckinsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (entryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.entryId,
                    referencedTable:
                        $$DailyCheckinsTableReferences._entryIdTable(db),
                    referencedColumn:
                        $$DailyCheckinsTableReferences._entryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DailyCheckinsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyCheckinsTable,
    DailyCheckin,
    $$DailyCheckinsTableFilterComposer,
    $$DailyCheckinsTableOrderingComposer,
    $$DailyCheckinsTableAnnotationComposer,
    $$DailyCheckinsTableCreateCompanionBuilder,
    $$DailyCheckinsTableUpdateCompanionBuilder,
    (DailyCheckin, $$DailyCheckinsTableReferences),
    DailyCheckin,
    PrefetchHooks Function({bool entryId})>;
typedef $$DailyUsageSummaryTableCreateCompanionBuilder
    = DailyUsageSummaryCompanion Function({
  Value<int> id,
  required String packageName,
  required DateTime day,
  required int foregroundSeconds,
  Value<int> launchCount,
  required DateTime aggregatedAt,
});
typedef $$DailyUsageSummaryTableUpdateCompanionBuilder
    = DailyUsageSummaryCompanion Function({
  Value<int> id,
  Value<String> packageName,
  Value<DateTime> day,
  Value<int> foregroundSeconds,
  Value<int> launchCount,
  Value<DateTime> aggregatedAt,
});

class $$DailyUsageSummaryTableFilterComposer
    extends Composer<_$AppDatabase, $DailyUsageSummaryTable> {
  $$DailyUsageSummaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get foregroundSeconds => $composableBuilder(
      column: $table.foregroundSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get aggregatedAt => $composableBuilder(
      column: $table.aggregatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyUsageSummaryTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyUsageSummaryTable> {
  $$DailyUsageSummaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get foregroundSeconds => $composableBuilder(
      column: $table.foregroundSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get aggregatedAt => $composableBuilder(
      column: $table.aggregatedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$DailyUsageSummaryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyUsageSummaryTable> {
  $$DailyUsageSummaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get foregroundSeconds => $composableBuilder(
      column: $table.foregroundSeconds, builder: (column) => column);

  GeneratedColumn<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => column);

  GeneratedColumn<DateTime> get aggregatedAt => $composableBuilder(
      column: $table.aggregatedAt, builder: (column) => column);
}

class $$DailyUsageSummaryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyUsageSummaryTable,
    DailyUsageSummaryData,
    $$DailyUsageSummaryTableFilterComposer,
    $$DailyUsageSummaryTableOrderingComposer,
    $$DailyUsageSummaryTableAnnotationComposer,
    $$DailyUsageSummaryTableCreateCompanionBuilder,
    $$DailyUsageSummaryTableUpdateCompanionBuilder,
    (
      DailyUsageSummaryData,
      BaseReferences<_$AppDatabase, $DailyUsageSummaryTable,
          DailyUsageSummaryData>
    ),
    DailyUsageSummaryData,
    PrefetchHooks Function()> {
  $$DailyUsageSummaryTableTableManager(
      _$AppDatabase db, $DailyUsageSummaryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyUsageSummaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyUsageSummaryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyUsageSummaryTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> packageName = const Value.absent(),
            Value<DateTime> day = const Value.absent(),
            Value<int> foregroundSeconds = const Value.absent(),
            Value<int> launchCount = const Value.absent(),
            Value<DateTime> aggregatedAt = const Value.absent(),
          }) =>
              DailyUsageSummaryCompanion(
            id: id,
            packageName: packageName,
            day: day,
            foregroundSeconds: foregroundSeconds,
            launchCount: launchCount,
            aggregatedAt: aggregatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String packageName,
            required DateTime day,
            required int foregroundSeconds,
            Value<int> launchCount = const Value.absent(),
            required DateTime aggregatedAt,
          }) =>
              DailyUsageSummaryCompanion.insert(
            id: id,
            packageName: packageName,
            day: day,
            foregroundSeconds: foregroundSeconds,
            launchCount: launchCount,
            aggregatedAt: aggregatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyUsageSummaryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyUsageSummaryTable,
    DailyUsageSummaryData,
    $$DailyUsageSummaryTableFilterComposer,
    $$DailyUsageSummaryTableOrderingComposer,
    $$DailyUsageSummaryTableAnnotationComposer,
    $$DailyUsageSummaryTableCreateCompanionBuilder,
    $$DailyUsageSummaryTableUpdateCompanionBuilder,
    (
      DailyUsageSummaryData,
      BaseReferences<_$AppDatabase, $DailyUsageSummaryTable,
          DailyUsageSummaryData>
    ),
    DailyUsageSummaryData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BlockListTableTableManager get blockList =>
      $$BlockListTableTableManager(_db, _db.blockList);
  $$DailyStreakTableTableManager get dailyStreak =>
      $$DailyStreakTableTableManager(_db, _db.dailyStreak);
  $$PauseEventsTableTableManager get pauseEvents =>
      $$PauseEventsTableTableManager(_db, _db.pauseEvents);
  $$DailyCheckinsTableTableManager get dailyCheckins =>
      $$DailyCheckinsTableTableManager(_db, _db.dailyCheckins);
  $$DailyUsageSummaryTableTableManager get dailyUsageSummary =>
      $$DailyUsageSummaryTableTableManager(_db, _db.dailyUsageSummary);
}
