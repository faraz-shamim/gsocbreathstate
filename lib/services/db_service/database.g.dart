                                         

part of 'database.dart';

                             
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resonanceFrequencyMeta =
      const VerificationMeta('resonanceFrequency');
  @override
  late final GeneratedColumn<double> resonanceFrequency =
      GeneratedColumn<double>(
        'resonance_frequency',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dateOfBirth,
    age,
    sex,
    heightCm,
    notes,
    resonanceFrequency,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Patient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('resonance_frequency')) {
      context.handle(
        _resonanceFrequencyMeta,
        resonanceFrequency.isAcceptableOrUnknown(
          data['resonance_frequency']!,
          _resonanceFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      ),
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      resonanceFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}resonance_frequency'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final int id;
  final String name;
  final String? dateOfBirth;
  final int? age;
  final String? sex;
  final double? heightCm;
  final String? notes;
  final double? resonanceFrequency;
  final String createdAt;
  final String updatedAt;
  const Patient({
    required this.id,
    required this.name,
    this.dateOfBirth,
    this.age,
    this.sex,
    this.heightCm,
    this.notes,
    this.resonanceFrequency,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || resonanceFrequency != null) {
      map['resonance_frequency'] = Variable<double>(resonanceFrequency);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      name: Value(name),
      dateOfBirth:
          dateOfBirth == null && nullToAbsent
              ? const Value.absent()
              : Value(dateOfBirth),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      heightCm:
          heightCm == null && nullToAbsent
              ? const Value.absent()
              : Value(heightCm),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      resonanceFrequency:
          resonanceFrequency == null && nullToAbsent
              ? const Value.absent()
              : Value(resonanceFrequency),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dateOfBirth: serializer.fromJson<String?>(json['dateOfBirth']),
      age: serializer.fromJson<int?>(json['age']),
      sex: serializer.fromJson<String?>(json['sex']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      notes: serializer.fromJson<String?>(json['notes']),
      resonanceFrequency: serializer.fromJson<double?>(
        json['resonanceFrequency'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dateOfBirth': serializer.toJson<String?>(dateOfBirth),
      'age': serializer.toJson<int?>(age),
      'sex': serializer.toJson<String?>(sex),
      'heightCm': serializer.toJson<double?>(heightCm),
      'notes': serializer.toJson<String?>(notes),
      'resonanceFrequency': serializer.toJson<double?>(resonanceFrequency),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Patient copyWith({
    int? id,
    String? name,
    Value<String?> dateOfBirth = const Value.absent(),
    Value<int?> age = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<double?> resonanceFrequency = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => Patient(
    id: id ?? this.id,
    name: name ?? this.name,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    age: age.present ? age.value : this.age,
    sex: sex.present ? sex.value : this.sex,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    notes: notes.present ? notes.value : this.notes,
    resonanceFrequency:
        resonanceFrequency.present
            ? resonanceFrequency.value
            : this.resonanceFrequency,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      age: data.age.present ? data.age.value : this.age,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      notes: data.notes.present ? data.notes.value : this.notes,
      resonanceFrequency:
          data.resonanceFrequency.present
              ? data.resonanceFrequency.value
              : this.resonanceFrequency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('age: $age, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('notes: $notes, ')
          ..write('resonanceFrequency: $resonanceFrequency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dateOfBirth,
    age,
    sex,
    heightCm,
    notes,
    resonanceFrequency,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.name == this.name &&
          other.dateOfBirth == this.dateOfBirth &&
          other.age == this.age &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.notes == this.notes &&
          other.resonanceFrequency == this.resonanceFrequency &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> dateOfBirth;
  final Value<int?> age;
  final Value<String?> sex;
  final Value<double?> heightCm;
  final Value<String?> notes;
  final Value<double?> resonanceFrequency;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.age = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.notes = const Value.absent(),
    this.resonanceFrequency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PatientsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.dateOfBirth = const Value.absent(),
    this.age = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.notes = const Value.absent(),
    this.resonanceFrequency = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Patient> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? dateOfBirth,
    Expression<int>? age,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<String>? notes,
    Expression<double>? resonanceFrequency,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (age != null) 'age': age,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (notes != null) 'notes': notes,
      if (resonanceFrequency != null) 'resonance_frequency': resonanceFrequency,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PatientsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? dateOfBirth,
    Value<int?>? age,
    Value<String?>? sex,
    Value<double?>? heightCm,
    Value<String?>? notes,
    Value<double?>? resonanceFrequency,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return PatientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      notes: notes ?? this.notes,
      resonanceFrequency: resonanceFrequency ?? this.resonanceFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (resonanceFrequency.present) {
      map['resonance_frequency'] = Variable<double>(resonanceFrequency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('age: $age, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('notes: $notes, ')
          ..write('resonanceFrequency: $resonanceFrequency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<String> endedAt = GeneratedColumn<String>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    sessionType,
    startedAt,
    endedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      sessionType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_type'],
          )!,
      startedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}started_at'],
          )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final int patientId;
  final String sessionType;
  final String startedAt;
  final String? endedAt;
  final String? notes;
  const Session({
    required this.id,
    required this.patientId,
    required this.sessionType,
    required this.startedAt,
    this.endedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['session_type'] = Variable<String>(sessionType);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<String>(endedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      sessionType: Value(sessionType),
      startedAt: Value(startedAt),
      endedAt:
          endedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(endedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      endedAt: serializer.fromJson<String?>(json['endedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'sessionType': serializer.toJson<String>(sessionType),
      'startedAt': serializer.toJson<String>(startedAt),
      'endedAt': serializer.toJson<String?>(endedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Session copyWith({
    int? id,
    int? patientId,
    String? sessionType,
    String? startedAt,
    Value<String?> endedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    sessionType: sessionType ?? this.sessionType,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, patientId, sessionType, startedAt, endedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.sessionType == this.sessionType &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.notes == this.notes);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<String> sessionType;
  final Value<String> startedAt;
  final Value<String?> endedAt;
  final Value<String?> notes;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    required String sessionType,
    required String startedAt,
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
  }) : patientId = Value(patientId),
       sessionType = Value(sessionType),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<String>? sessionType,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (sessionType != null) 'session_type': sessionType,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (notes != null) 'notes': notes,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? patientId,
    Value<String>? sessionType,
    Value<String>? startedAt,
    Value<String?>? endedAt,
    Value<String?>? notes,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      sessionType: sessionType ?? this.sessionType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(endedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $BreathRateEntriesTable extends BreathRateEntries
    with TableInfo<$BreathRateEntriesTable, BreathRateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreathRateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<int> rate = GeneratedColumn<int>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('microphone'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    patientId,
    timestamp,
    rate,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'breath_rate_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreathRateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreathRateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreathRateEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}session_id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}timestamp'],
          )!,
      rate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}rate'],
          )!,
      source:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}source'],
          )!,
    );
  }

  @override
  $BreathRateEntriesTable createAlias(String alias) {
    return $BreathRateEntriesTable(attachedDatabase, alias);
  }
}

class BreathRateEntry extends DataClass implements Insertable<BreathRateEntry> {
  final int id;
  final int sessionId;
  final int patientId;
  final String timestamp;
  final int rate;
  final String source;
  const BreathRateEntry({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.timestamp,
    required this.rate,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['patient_id'] = Variable<int>(patientId);
    map['timestamp'] = Variable<String>(timestamp);
    map['rate'] = Variable<int>(rate);
    map['source'] = Variable<String>(source);
    return map;
  }

  BreathRateEntriesCompanion toCompanion(bool nullToAbsent) {
    return BreathRateEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      patientId: Value(patientId),
      timestamp: Value(timestamp),
      rate: Value(rate),
      source: Value(source),
    );
  }

  factory BreathRateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreathRateEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      patientId: serializer.fromJson<int>(json['patientId']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      rate: serializer.fromJson<int>(json['rate']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'patientId': serializer.toJson<int>(patientId),
      'timestamp': serializer.toJson<String>(timestamp),
      'rate': serializer.toJson<int>(rate),
      'source': serializer.toJson<String>(source),
    };
  }

  BreathRateEntry copyWith({
    int? id,
    int? sessionId,
    int? patientId,
    String? timestamp,
    int? rate,
    String? source,
  }) => BreathRateEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    patientId: patientId ?? this.patientId,
    timestamp: timestamp ?? this.timestamp,
    rate: rate ?? this.rate,
    source: source ?? this.source,
  );
  BreathRateEntry copyWithCompanion(BreathRateEntriesCompanion data) {
    return BreathRateEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rate: data.rate.present ? data.rate.value : this.rate,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreathRateEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rate: $rate, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, patientId, timestamp, rate, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreathRateEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.patientId == this.patientId &&
          other.timestamp == this.timestamp &&
          other.rate == this.rate &&
          other.source == this.source);
}

class BreathRateEntriesCompanion extends UpdateCompanion<BreathRateEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> patientId;
  final Value<String> timestamp;
  final Value<int> rate;
  final Value<String> source;
  const BreathRateEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rate = const Value.absent(),
    this.source = const Value.absent(),
  });
  BreathRateEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int patientId,
    required String timestamp,
    required int rate,
    this.source = const Value.absent(),
  }) : sessionId = Value(sessionId),
       patientId = Value(patientId),
       timestamp = Value(timestamp),
       rate = Value(rate);
  static Insertable<BreathRateEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? patientId,
    Expression<String>? timestamp,
    Expression<int>? rate,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (patientId != null) 'patient_id': patientId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rate != null) 'rate': rate,
      if (source != null) 'source': source,
    });
  }

  BreathRateEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? patientId,
    Value<String>? timestamp,
    Value<int>? rate,
    Value<String>? source,
  }) {
    return BreathRateEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      rate: rate ?? this.rate,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rate.present) {
      map['rate'] = Variable<int>(rate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreathRateEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rate: $rate, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $HeartRateEntriesTable extends HeartRateEntries
    with TableInfo<$HeartRateEntriesTable, HeartRateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeartRateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<int> rate = GeneratedColumn<int>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    patientId,
    timestamp,
    rate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heart_rate_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeartRateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeartRateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeartRateEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}session_id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}timestamp'],
          )!,
      rate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}rate'],
          )!,
    );
  }

  @override
  $HeartRateEntriesTable createAlias(String alias) {
    return $HeartRateEntriesTable(attachedDatabase, alias);
  }
}

class HeartRateEntry extends DataClass implements Insertable<HeartRateEntry> {
  final int id;
  final int sessionId;
  final int patientId;
  final String timestamp;
  final int rate;
  const HeartRateEntry({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.timestamp,
    required this.rate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['patient_id'] = Variable<int>(patientId);
    map['timestamp'] = Variable<String>(timestamp);
    map['rate'] = Variable<int>(rate);
    return map;
  }

  HeartRateEntriesCompanion toCompanion(bool nullToAbsent) {
    return HeartRateEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      patientId: Value(patientId),
      timestamp: Value(timestamp),
      rate: Value(rate),
    );
  }

  factory HeartRateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeartRateEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      patientId: serializer.fromJson<int>(json['patientId']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      rate: serializer.fromJson<int>(json['rate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'patientId': serializer.toJson<int>(patientId),
      'timestamp': serializer.toJson<String>(timestamp),
      'rate': serializer.toJson<int>(rate),
    };
  }

  HeartRateEntry copyWith({
    int? id,
    int? sessionId,
    int? patientId,
    String? timestamp,
    int? rate,
  }) => HeartRateEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    patientId: patientId ?? this.patientId,
    timestamp: timestamp ?? this.timestamp,
    rate: rate ?? this.rate,
  );
  HeartRateEntry copyWithCompanion(HeartRateEntriesCompanion data) {
    return HeartRateEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rate: data.rate.present ? data.rate.value : this.rate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeartRateEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rate: $rate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, patientId, timestamp, rate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeartRateEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.patientId == this.patientId &&
          other.timestamp == this.timestamp &&
          other.rate == this.rate);
}

class HeartRateEntriesCompanion extends UpdateCompanion<HeartRateEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> patientId;
  final Value<String> timestamp;
  final Value<int> rate;
  const HeartRateEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rate = const Value.absent(),
  });
  HeartRateEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int patientId,
    required String timestamp,
    required int rate,
  }) : sessionId = Value(sessionId),
       patientId = Value(patientId),
       timestamp = Value(timestamp),
       rate = Value(rate);
  static Insertable<HeartRateEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? patientId,
    Expression<String>? timestamp,
    Expression<int>? rate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (patientId != null) 'patient_id': patientId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rate != null) 'rate': rate,
    });
  }

  HeartRateEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? patientId,
    Value<String>? timestamp,
    Value<int>? rate,
  }) {
    return HeartRateEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      rate: rate ?? this.rate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rate.present) {
      map['rate'] = Variable<int>(rate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeartRateEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rate: $rate')
          ..write(')'))
        .toString();
  }
}

class $EcgSampleEntriesTable extends EcgSampleEntries
    with TableInfo<$EcgSampleEntriesTable, EcgSampleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcgSampleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampUsMeta = const VerificationMeta(
    'timestampUs',
  );
  @override
  late final GeneratedColumn<int> timestampUs = GeneratedColumn<int>(
    'timestamp_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedUsMeta = const VerificationMeta(
    'elapsedUs',
  );
  @override
  late final GeneratedColumn<int> elapsedUs = GeneratedColumn<int>(
    'elapsed_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleIndexMeta = const VerificationMeta(
    'sampleIndex',
  );
  @override
  late final GeneratedColumn<int> sampleIndex = GeneratedColumn<int>(
    'sample_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ecgUvMeta = const VerificationMeta('ecgUv');
  @override
  late final GeneratedColumn<double> ecgUv = GeneratedColumn<double>(
    'ecg_uv',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    patientId,
    timestampMs,
    timestampUs,
    elapsedMs,
    elapsedUs,
    sampleIndex,
    ecgUv,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ecg_sample_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EcgSampleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('timestamp_us')) {
      context.handle(
        _timestampUsMeta,
        timestampUs.isAcceptableOrUnknown(
          data['timestamp_us']!,
          _timestampUsMeta,
        ),
      );
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('elapsed_us')) {
      context.handle(
        _elapsedUsMeta,
        elapsedUs.isAcceptableOrUnknown(data['elapsed_us']!, _elapsedUsMeta),
      );
    }
    if (data.containsKey('sample_index')) {
      context.handle(
        _sampleIndexMeta,
        sampleIndex.isAcceptableOrUnknown(
          data['sample_index']!,
          _sampleIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleIndexMeta);
    }
    if (data.containsKey('ecg_uv')) {
      context.handle(
        _ecgUvMeta,
        ecgUv.isAcceptableOrUnknown(data['ecg_uv']!, _ecgUvMeta),
      );
    } else if (isInserting) {
      context.missing(_ecgUvMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EcgSampleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EcgSampleEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}session_id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      timestampMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}timestamp_ms'],
          )!,
      timestampUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_us'],
      ),
      elapsedMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}elapsed_ms'],
          )!,
      elapsedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_us'],
      ),
      sampleIndex:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sample_index'],
          )!,
      ecgUv:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}ecg_uv'],
          )!,
    );
  }

  @override
  $EcgSampleEntriesTable createAlias(String alias) {
    return $EcgSampleEntriesTable(attachedDatabase, alias);
  }
}

class EcgSampleEntry extends DataClass implements Insertable<EcgSampleEntry> {
  final int id;
  final int sessionId;
  final int patientId;
  final int timestampMs;
  final int? timestampUs;
  final int elapsedMs;
  final int? elapsedUs;
  final int sampleIndex;
  final double ecgUv;
  const EcgSampleEntry({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.timestampMs,
    this.timestampUs,
    required this.elapsedMs,
    this.elapsedUs,
    required this.sampleIndex,
    required this.ecgUv,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['patient_id'] = Variable<int>(patientId);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    if (!nullToAbsent || timestampUs != null) {
      map['timestamp_us'] = Variable<int>(timestampUs);
    }
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    if (!nullToAbsent || elapsedUs != null) {
      map['elapsed_us'] = Variable<int>(elapsedUs);
    }
    map['sample_index'] = Variable<int>(sampleIndex);
    map['ecg_uv'] = Variable<double>(ecgUv);
    return map;
  }

  EcgSampleEntriesCompanion toCompanion(bool nullToAbsent) {
    return EcgSampleEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      patientId: Value(patientId),
      timestampMs: Value(timestampMs),
      timestampUs:
          timestampUs == null && nullToAbsent
              ? const Value.absent()
              : Value(timestampUs),
      elapsedMs: Value(elapsedMs),
      elapsedUs:
          elapsedUs == null && nullToAbsent
              ? const Value.absent()
              : Value(elapsedUs),
      sampleIndex: Value(sampleIndex),
      ecgUv: Value(ecgUv),
    );
  }

  factory EcgSampleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EcgSampleEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      patientId: serializer.fromJson<int>(json['patientId']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      timestampUs: serializer.fromJson<int?>(json['timestampUs']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      elapsedUs: serializer.fromJson<int?>(json['elapsedUs']),
      sampleIndex: serializer.fromJson<int>(json['sampleIndex']),
      ecgUv: serializer.fromJson<double>(json['ecgUv']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'patientId': serializer.toJson<int>(patientId),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'timestampUs': serializer.toJson<int?>(timestampUs),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'elapsedUs': serializer.toJson<int?>(elapsedUs),
      'sampleIndex': serializer.toJson<int>(sampleIndex),
      'ecgUv': serializer.toJson<double>(ecgUv),
    };
  }

  EcgSampleEntry copyWith({
    int? id,
    int? sessionId,
    int? patientId,
    int? timestampMs,
    Value<int?> timestampUs = const Value.absent(),
    int? elapsedMs,
    Value<int?> elapsedUs = const Value.absent(),
    int? sampleIndex,
    double? ecgUv,
  }) => EcgSampleEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    patientId: patientId ?? this.patientId,
    timestampMs: timestampMs ?? this.timestampMs,
    timestampUs: timestampUs.present ? timestampUs.value : this.timestampUs,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    elapsedUs: elapsedUs.present ? elapsedUs.value : this.elapsedUs,
    sampleIndex: sampleIndex ?? this.sampleIndex,
    ecgUv: ecgUv ?? this.ecgUv,
  );
  EcgSampleEntry copyWithCompanion(EcgSampleEntriesCompanion data) {
    return EcgSampleEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      timestampMs:
          data.timestampMs.present ? data.timestampMs.value : this.timestampMs,
      timestampUs:
          data.timestampUs.present ? data.timestampUs.value : this.timestampUs,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      elapsedUs: data.elapsedUs.present ? data.elapsedUs.value : this.elapsedUs,
      sampleIndex:
          data.sampleIndex.present ? data.sampleIndex.value : this.sampleIndex,
      ecgUv: data.ecgUv.present ? data.ecgUv.value : this.ecgUv,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EcgSampleEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('timestampUs: $timestampUs, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('elapsedUs: $elapsedUs, ')
          ..write('sampleIndex: $sampleIndex, ')
          ..write('ecgUv: $ecgUv')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    patientId,
    timestampMs,
    timestampUs,
    elapsedMs,
    elapsedUs,
    sampleIndex,
    ecgUv,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EcgSampleEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.patientId == this.patientId &&
          other.timestampMs == this.timestampMs &&
          other.timestampUs == this.timestampUs &&
          other.elapsedMs == this.elapsedMs &&
          other.elapsedUs == this.elapsedUs &&
          other.sampleIndex == this.sampleIndex &&
          other.ecgUv == this.ecgUv);
}

class EcgSampleEntriesCompanion extends UpdateCompanion<EcgSampleEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> patientId;
  final Value<int> timestampMs;
  final Value<int?> timestampUs;
  final Value<int> elapsedMs;
  final Value<int?> elapsedUs;
  final Value<int> sampleIndex;
  final Value<double> ecgUv;
  const EcgSampleEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.timestampUs = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.elapsedUs = const Value.absent(),
    this.sampleIndex = const Value.absent(),
    this.ecgUv = const Value.absent(),
  });
  EcgSampleEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int patientId,
    required int timestampMs,
    this.timestampUs = const Value.absent(),
    required int elapsedMs,
    this.elapsedUs = const Value.absent(),
    required int sampleIndex,
    required double ecgUv,
  }) : sessionId = Value(sessionId),
       patientId = Value(patientId),
       timestampMs = Value(timestampMs),
       elapsedMs = Value(elapsedMs),
       sampleIndex = Value(sampleIndex),
       ecgUv = Value(ecgUv);
  static Insertable<EcgSampleEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? patientId,
    Expression<int>? timestampMs,
    Expression<int>? timestampUs,
    Expression<int>? elapsedMs,
    Expression<int>? elapsedUs,
    Expression<int>? sampleIndex,
    Expression<double>? ecgUv,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (patientId != null) 'patient_id': patientId,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (timestampUs != null) 'timestamp_us': timestampUs,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (elapsedUs != null) 'elapsed_us': elapsedUs,
      if (sampleIndex != null) 'sample_index': sampleIndex,
      if (ecgUv != null) 'ecg_uv': ecgUv,
    });
  }

  EcgSampleEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? patientId,
    Value<int>? timestampMs,
    Value<int?>? timestampUs,
    Value<int>? elapsedMs,
    Value<int?>? elapsedUs,
    Value<int>? sampleIndex,
    Value<double>? ecgUv,
  }) {
    return EcgSampleEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      timestampMs: timestampMs ?? this.timestampMs,
      timestampUs: timestampUs ?? this.timestampUs,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      elapsedUs: elapsedUs ?? this.elapsedUs,
      sampleIndex: sampleIndex ?? this.sampleIndex,
      ecgUv: ecgUv ?? this.ecgUv,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (timestampUs.present) {
      map['timestamp_us'] = Variable<int>(timestampUs.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (elapsedUs.present) {
      map['elapsed_us'] = Variable<int>(elapsedUs.value);
    }
    if (sampleIndex.present) {
      map['sample_index'] = Variable<int>(sampleIndex.value);
    }
    if (ecgUv.present) {
      map['ecg_uv'] = Variable<double>(ecgUv.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcgSampleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('timestampUs: $timestampUs, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('elapsedUs: $elapsedUs, ')
          ..write('sampleIndex: $sampleIndex, ')
          ..write('ecgUv: $ecgUv')
          ..write(')'))
        .toString();
  }
}

class $HrvEntriesTable extends HrvEntries
    with TableInfo<$HrvEntriesTable, HrvEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HrvEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meanNnMeta = const VerificationMeta('meanNn');
  @override
  late final GeneratedColumn<double> meanNn = GeneratedColumn<double>(
    'mean_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnnMeta = const VerificationMeta('sdnn');
  @override
  late final GeneratedColumn<double> sdnn = GeneratedColumn<double>(
    'sdnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdMeta = const VerificationMeta('rmssd');
  @override
  late final GeneratedColumn<double> rmssd = GeneratedColumn<double>(
    'rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdsdMeta = const VerificationMeta('sdsd');
  @override
  late final GeneratedColumn<double> sdsd = GeneratedColumn<double>(
    'sdsd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cvnnMeta = const VerificationMeta('cvnn');
  @override
  late final GeneratedColumn<double> cvnn = GeneratedColumn<double>(
    'cvnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cvsdMeta = const VerificationMeta('cvsd');
  @override
  late final GeneratedColumn<double> cvsd = GeneratedColumn<double>(
    'cvsd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medianNnMeta = const VerificationMeta(
    'medianNn',
  );
  @override
  late final GeneratedColumn<double> medianNn = GeneratedColumn<double>(
    'median_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _madNnMeta = const VerificationMeta('madNn');
  @override
  late final GeneratedColumn<double> madNn = GeneratedColumn<double>(
    'mad_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mcvnnMeta = const VerificationMeta('mcvnn');
  @override
  late final GeneratedColumn<double> mcvnn = GeneratedColumn<double>(
    'mcvnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iqrnnMeta = const VerificationMeta('iqrnn');
  @override
  late final GeneratedColumn<double> iqrnn = GeneratedColumn<double>(
    'iqrnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdrmssdMeta = const VerificationMeta(
    'sdrmssd',
  );
  @override
  late final GeneratedColumn<double> sdrmssd = GeneratedColumn<double>(
    'sdrmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prc20nnMeta = const VerificationMeta(
    'prc20nn',
  );
  @override
  late final GeneratedColumn<double> prc20nn = GeneratedColumn<double>(
    'prc20nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prc80nnMeta = const VerificationMeta(
    'prc80nn',
  );
  @override
  late final GeneratedColumn<double> prc80nn = GeneratedColumn<double>(
    'prc80nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pnn50Meta = const VerificationMeta('pnn50');
  @override
  late final GeneratedColumn<double> pnn50 = GeneratedColumn<double>(
    'pnn50',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pnn20Meta = const VerificationMeta('pnn20');
  @override
  late final GeneratedColumn<double> pnn20 = GeneratedColumn<double>(
    'pnn20',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minNnMeta = const VerificationMeta('minNn');
  @override
  late final GeneratedColumn<double> minNn = GeneratedColumn<double>(
    'min_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxNnMeta = const VerificationMeta('maxNn');
  @override
  late final GeneratedColumn<double> maxNn = GeneratedColumn<double>(
    'max_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _htiMeta = const VerificationMeta('hti');
  @override
  late final GeneratedColumn<double> hti = GeneratedColumn<double>(
    'hti',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tinnMeta = const VerificationMeta('tinn');
  @override
  late final GeneratedColumn<double> tinn = GeneratedColumn<double>(
    'tinn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdann1Meta = const VerificationMeta('sdann1');
  @override
  late final GeneratedColumn<double> sdann1 = GeneratedColumn<double>(
    'sdann1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdann2Meta = const VerificationMeta('sdann2');
  @override
  late final GeneratedColumn<double> sdann2 = GeneratedColumn<double>(
    'sdann2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdann5Meta = const VerificationMeta('sdann5');
  @override
  late final GeneratedColumn<double> sdann5 = GeneratedColumn<double>(
    'sdann5',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnni1Meta = const VerificationMeta('sdnni1');
  @override
  late final GeneratedColumn<double> sdnni1 = GeneratedColumn<double>(
    'sdnni1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnni2Meta = const VerificationMeta('sdnni2');
  @override
  late final GeneratedColumn<double> sdnni2 = GeneratedColumn<double>(
    'sdnni2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnni5Meta = const VerificationMeta('sdnni5');
  @override
  late final GeneratedColumn<double> sdnni5 = GeneratedColumn<double>(
    'sdnni5',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    patientId,
    timestamp,
    meanNn,
    sdnn,
    rmssd,
    sdsd,
    cvnn,
    cvsd,
    medianNn,
    madNn,
    mcvnn,
    iqrnn,
    sdrmssd,
    prc20nn,
    prc80nn,
    pnn50,
    pnn20,
    minNn,
    maxNn,
    hti,
    tinn,
    sdann1,
    sdann2,
    sdann5,
    sdnni1,
    sdnni2,
    sdnni5,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hrv_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HrvEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('mean_nn')) {
      context.handle(
        _meanNnMeta,
        meanNn.isAcceptableOrUnknown(data['mean_nn']!, _meanNnMeta),
      );
    }
    if (data.containsKey('sdnn')) {
      context.handle(
        _sdnnMeta,
        sdnn.isAcceptableOrUnknown(data['sdnn']!, _sdnnMeta),
      );
    }
    if (data.containsKey('rmssd')) {
      context.handle(
        _rmssdMeta,
        rmssd.isAcceptableOrUnknown(data['rmssd']!, _rmssdMeta),
      );
    }
    if (data.containsKey('sdsd')) {
      context.handle(
        _sdsdMeta,
        sdsd.isAcceptableOrUnknown(data['sdsd']!, _sdsdMeta),
      );
    }
    if (data.containsKey('cvnn')) {
      context.handle(
        _cvnnMeta,
        cvnn.isAcceptableOrUnknown(data['cvnn']!, _cvnnMeta),
      );
    }
    if (data.containsKey('cvsd')) {
      context.handle(
        _cvsdMeta,
        cvsd.isAcceptableOrUnknown(data['cvsd']!, _cvsdMeta),
      );
    }
    if (data.containsKey('median_nn')) {
      context.handle(
        _medianNnMeta,
        medianNn.isAcceptableOrUnknown(data['median_nn']!, _medianNnMeta),
      );
    }
    if (data.containsKey('mad_nn')) {
      context.handle(
        _madNnMeta,
        madNn.isAcceptableOrUnknown(data['mad_nn']!, _madNnMeta),
      );
    }
    if (data.containsKey('mcvnn')) {
      context.handle(
        _mcvnnMeta,
        mcvnn.isAcceptableOrUnknown(data['mcvnn']!, _mcvnnMeta),
      );
    }
    if (data.containsKey('iqrnn')) {
      context.handle(
        _iqrnnMeta,
        iqrnn.isAcceptableOrUnknown(data['iqrnn']!, _iqrnnMeta),
      );
    }
    if (data.containsKey('sdrmssd')) {
      context.handle(
        _sdrmssdMeta,
        sdrmssd.isAcceptableOrUnknown(data['sdrmssd']!, _sdrmssdMeta),
      );
    }
    if (data.containsKey('prc20nn')) {
      context.handle(
        _prc20nnMeta,
        prc20nn.isAcceptableOrUnknown(data['prc20nn']!, _prc20nnMeta),
      );
    }
    if (data.containsKey('prc80nn')) {
      context.handle(
        _prc80nnMeta,
        prc80nn.isAcceptableOrUnknown(data['prc80nn']!, _prc80nnMeta),
      );
    }
    if (data.containsKey('pnn50')) {
      context.handle(
        _pnn50Meta,
        pnn50.isAcceptableOrUnknown(data['pnn50']!, _pnn50Meta),
      );
    }
    if (data.containsKey('pnn20')) {
      context.handle(
        _pnn20Meta,
        pnn20.isAcceptableOrUnknown(data['pnn20']!, _pnn20Meta),
      );
    }
    if (data.containsKey('min_nn')) {
      context.handle(
        _minNnMeta,
        minNn.isAcceptableOrUnknown(data['min_nn']!, _minNnMeta),
      );
    }
    if (data.containsKey('max_nn')) {
      context.handle(
        _maxNnMeta,
        maxNn.isAcceptableOrUnknown(data['max_nn']!, _maxNnMeta),
      );
    }
    if (data.containsKey('hti')) {
      context.handle(
        _htiMeta,
        hti.isAcceptableOrUnknown(data['hti']!, _htiMeta),
      );
    }
    if (data.containsKey('tinn')) {
      context.handle(
        _tinnMeta,
        tinn.isAcceptableOrUnknown(data['tinn']!, _tinnMeta),
      );
    }
    if (data.containsKey('sdann1')) {
      context.handle(
        _sdann1Meta,
        sdann1.isAcceptableOrUnknown(data['sdann1']!, _sdann1Meta),
      );
    }
    if (data.containsKey('sdann2')) {
      context.handle(
        _sdann2Meta,
        sdann2.isAcceptableOrUnknown(data['sdann2']!, _sdann2Meta),
      );
    }
    if (data.containsKey('sdann5')) {
      context.handle(
        _sdann5Meta,
        sdann5.isAcceptableOrUnknown(data['sdann5']!, _sdann5Meta),
      );
    }
    if (data.containsKey('sdnni1')) {
      context.handle(
        _sdnni1Meta,
        sdnni1.isAcceptableOrUnknown(data['sdnni1']!, _sdnni1Meta),
      );
    }
    if (data.containsKey('sdnni2')) {
      context.handle(
        _sdnni2Meta,
        sdnni2.isAcceptableOrUnknown(data['sdnni2']!, _sdnni2Meta),
      );
    }
    if (data.containsKey('sdnni5')) {
      context.handle(
        _sdnni5Meta,
        sdnni5.isAcceptableOrUnknown(data['sdnni5']!, _sdnni5Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HrvEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HrvEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sessionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}session_id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}timestamp'],
          )!,
      meanNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean_nn'],
      ),
      sdnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnn'],
      ),
      rmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd'],
      ),
      sdsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdsd'],
      ),
      cvnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cvnn'],
      ),
      cvsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cvsd'],
      ),
      medianNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}median_nn'],
      ),
      madNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mad_nn'],
      ),
      mcvnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mcvnn'],
      ),
      iqrnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iqrnn'],
      ),
      sdrmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdrmssd'],
      ),
      prc20nn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prc20nn'],
      ),
      prc80nn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prc80nn'],
      ),
      pnn50: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pnn50'],
      ),
      pnn20: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pnn20'],
      ),
      minNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_nn'],
      ),
      maxNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_nn'],
      ),
      hti: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hti'],
      ),
      tinn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tinn'],
      ),
      sdann1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdann1'],
      ),
      sdann2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdann2'],
      ),
      sdann5: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdann5'],
      ),
      sdnni1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnni1'],
      ),
      sdnni2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnni2'],
      ),
      sdnni5: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnni5'],
      ),
    );
  }

  @override
  $HrvEntriesTable createAlias(String alias) {
    return $HrvEntriesTable(attachedDatabase, alias);
  }
}

class HrvEntry extends DataClass implements Insertable<HrvEntry> {
  final int id;
  final int sessionId;
  final int patientId;
  final String timestamp;
  final double? meanNn;
  final double? sdnn;
  final double? rmssd;
  final double? sdsd;
  final double? cvnn;
  final double? cvsd;
  final double? medianNn;
  final double? madNn;
  final double? mcvnn;
  final double? iqrnn;
  final double? sdrmssd;
  final double? prc20nn;
  final double? prc80nn;
  final double? pnn50;
  final double? pnn20;
  final double? minNn;
  final double? maxNn;
  final double? hti;
  final double? tinn;
  final double? sdann1;
  final double? sdann2;
  final double? sdann5;
  final double? sdnni1;
  final double? sdnni2;
  final double? sdnni5;
  const HrvEntry({
    required this.id,
    required this.sessionId,
    required this.patientId,
    required this.timestamp,
    this.meanNn,
    this.sdnn,
    this.rmssd,
    this.sdsd,
    this.cvnn,
    this.cvsd,
    this.medianNn,
    this.madNn,
    this.mcvnn,
    this.iqrnn,
    this.sdrmssd,
    this.prc20nn,
    this.prc80nn,
    this.pnn50,
    this.pnn20,
    this.minNn,
    this.maxNn,
    this.hti,
    this.tinn,
    this.sdann1,
    this.sdann2,
    this.sdann5,
    this.sdnni1,
    this.sdnni2,
    this.sdnni5,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['patient_id'] = Variable<int>(patientId);
    map['timestamp'] = Variable<String>(timestamp);
    if (!nullToAbsent || meanNn != null) {
      map['mean_nn'] = Variable<double>(meanNn);
    }
    if (!nullToAbsent || sdnn != null) {
      map['sdnn'] = Variable<double>(sdnn);
    }
    if (!nullToAbsent || rmssd != null) {
      map['rmssd'] = Variable<double>(rmssd);
    }
    if (!nullToAbsent || sdsd != null) {
      map['sdsd'] = Variable<double>(sdsd);
    }
    if (!nullToAbsent || cvnn != null) {
      map['cvnn'] = Variable<double>(cvnn);
    }
    if (!nullToAbsent || cvsd != null) {
      map['cvsd'] = Variable<double>(cvsd);
    }
    if (!nullToAbsent || medianNn != null) {
      map['median_nn'] = Variable<double>(medianNn);
    }
    if (!nullToAbsent || madNn != null) {
      map['mad_nn'] = Variable<double>(madNn);
    }
    if (!nullToAbsent || mcvnn != null) {
      map['mcvnn'] = Variable<double>(mcvnn);
    }
    if (!nullToAbsent || iqrnn != null) {
      map['iqrnn'] = Variable<double>(iqrnn);
    }
    if (!nullToAbsent || sdrmssd != null) {
      map['sdrmssd'] = Variable<double>(sdrmssd);
    }
    if (!nullToAbsent || prc20nn != null) {
      map['prc20nn'] = Variable<double>(prc20nn);
    }
    if (!nullToAbsent || prc80nn != null) {
      map['prc80nn'] = Variable<double>(prc80nn);
    }
    if (!nullToAbsent || pnn50 != null) {
      map['pnn50'] = Variable<double>(pnn50);
    }
    if (!nullToAbsent || pnn20 != null) {
      map['pnn20'] = Variable<double>(pnn20);
    }
    if (!nullToAbsent || minNn != null) {
      map['min_nn'] = Variable<double>(minNn);
    }
    if (!nullToAbsent || maxNn != null) {
      map['max_nn'] = Variable<double>(maxNn);
    }
    if (!nullToAbsent || hti != null) {
      map['hti'] = Variable<double>(hti);
    }
    if (!nullToAbsent || tinn != null) {
      map['tinn'] = Variable<double>(tinn);
    }
    if (!nullToAbsent || sdann1 != null) {
      map['sdann1'] = Variable<double>(sdann1);
    }
    if (!nullToAbsent || sdann2 != null) {
      map['sdann2'] = Variable<double>(sdann2);
    }
    if (!nullToAbsent || sdann5 != null) {
      map['sdann5'] = Variable<double>(sdann5);
    }
    if (!nullToAbsent || sdnni1 != null) {
      map['sdnni1'] = Variable<double>(sdnni1);
    }
    if (!nullToAbsent || sdnni2 != null) {
      map['sdnni2'] = Variable<double>(sdnni2);
    }
    if (!nullToAbsent || sdnni5 != null) {
      map['sdnni5'] = Variable<double>(sdnni5);
    }
    return map;
  }

  HrvEntriesCompanion toCompanion(bool nullToAbsent) {
    return HrvEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      patientId: Value(patientId),
      timestamp: Value(timestamp),
      meanNn:
          meanNn == null && nullToAbsent ? const Value.absent() : Value(meanNn),
      sdnn: sdnn == null && nullToAbsent ? const Value.absent() : Value(sdnn),
      rmssd:
          rmssd == null && nullToAbsent ? const Value.absent() : Value(rmssd),
      sdsd: sdsd == null && nullToAbsent ? const Value.absent() : Value(sdsd),
      cvnn: cvnn == null && nullToAbsent ? const Value.absent() : Value(cvnn),
      cvsd: cvsd == null && nullToAbsent ? const Value.absent() : Value(cvsd),
      medianNn:
          medianNn == null && nullToAbsent
              ? const Value.absent()
              : Value(medianNn),
      madNn:
          madNn == null && nullToAbsent ? const Value.absent() : Value(madNn),
      mcvnn:
          mcvnn == null && nullToAbsent ? const Value.absent() : Value(mcvnn),
      iqrnn:
          iqrnn == null && nullToAbsent ? const Value.absent() : Value(iqrnn),
      sdrmssd:
          sdrmssd == null && nullToAbsent
              ? const Value.absent()
              : Value(sdrmssd),
      prc20nn:
          prc20nn == null && nullToAbsent
              ? const Value.absent()
              : Value(prc20nn),
      prc80nn:
          prc80nn == null && nullToAbsent
              ? const Value.absent()
              : Value(prc80nn),
      pnn50:
          pnn50 == null && nullToAbsent ? const Value.absent() : Value(pnn50),
      pnn20:
          pnn20 == null && nullToAbsent ? const Value.absent() : Value(pnn20),
      minNn:
          minNn == null && nullToAbsent ? const Value.absent() : Value(minNn),
      maxNn:
          maxNn == null && nullToAbsent ? const Value.absent() : Value(maxNn),
      hti: hti == null && nullToAbsent ? const Value.absent() : Value(hti),
      tinn: tinn == null && nullToAbsent ? const Value.absent() : Value(tinn),
      sdann1:
          sdann1 == null && nullToAbsent ? const Value.absent() : Value(sdann1),
      sdann2:
          sdann2 == null && nullToAbsent ? const Value.absent() : Value(sdann2),
      sdann5:
          sdann5 == null && nullToAbsent ? const Value.absent() : Value(sdann5),
      sdnni1:
          sdnni1 == null && nullToAbsent ? const Value.absent() : Value(sdnni1),
      sdnni2:
          sdnni2 == null && nullToAbsent ? const Value.absent() : Value(sdnni2),
      sdnni5:
          sdnni5 == null && nullToAbsent ? const Value.absent() : Value(sdnni5),
    );
  }

  factory HrvEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HrvEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      patientId: serializer.fromJson<int>(json['patientId']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      meanNn: serializer.fromJson<double?>(json['meanNn']),
      sdnn: serializer.fromJson<double?>(json['sdnn']),
      rmssd: serializer.fromJson<double?>(json['rmssd']),
      sdsd: serializer.fromJson<double?>(json['sdsd']),
      cvnn: serializer.fromJson<double?>(json['cvnn']),
      cvsd: serializer.fromJson<double?>(json['cvsd']),
      medianNn: serializer.fromJson<double?>(json['medianNn']),
      madNn: serializer.fromJson<double?>(json['madNn']),
      mcvnn: serializer.fromJson<double?>(json['mcvnn']),
      iqrnn: serializer.fromJson<double?>(json['iqrnn']),
      sdrmssd: serializer.fromJson<double?>(json['sdrmssd']),
      prc20nn: serializer.fromJson<double?>(json['prc20nn']),
      prc80nn: serializer.fromJson<double?>(json['prc80nn']),
      pnn50: serializer.fromJson<double?>(json['pnn50']),
      pnn20: serializer.fromJson<double?>(json['pnn20']),
      minNn: serializer.fromJson<double?>(json['minNn']),
      maxNn: serializer.fromJson<double?>(json['maxNn']),
      hti: serializer.fromJson<double?>(json['hti']),
      tinn: serializer.fromJson<double?>(json['tinn']),
      sdann1: serializer.fromJson<double?>(json['sdann1']),
      sdann2: serializer.fromJson<double?>(json['sdann2']),
      sdann5: serializer.fromJson<double?>(json['sdann5']),
      sdnni1: serializer.fromJson<double?>(json['sdnni1']),
      sdnni2: serializer.fromJson<double?>(json['sdnni2']),
      sdnni5: serializer.fromJson<double?>(json['sdnni5']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'patientId': serializer.toJson<int>(patientId),
      'timestamp': serializer.toJson<String>(timestamp),
      'meanNn': serializer.toJson<double?>(meanNn),
      'sdnn': serializer.toJson<double?>(sdnn),
      'rmssd': serializer.toJson<double?>(rmssd),
      'sdsd': serializer.toJson<double?>(sdsd),
      'cvnn': serializer.toJson<double?>(cvnn),
      'cvsd': serializer.toJson<double?>(cvsd),
      'medianNn': serializer.toJson<double?>(medianNn),
      'madNn': serializer.toJson<double?>(madNn),
      'mcvnn': serializer.toJson<double?>(mcvnn),
      'iqrnn': serializer.toJson<double?>(iqrnn),
      'sdrmssd': serializer.toJson<double?>(sdrmssd),
      'prc20nn': serializer.toJson<double?>(prc20nn),
      'prc80nn': serializer.toJson<double?>(prc80nn),
      'pnn50': serializer.toJson<double?>(pnn50),
      'pnn20': serializer.toJson<double?>(pnn20),
      'minNn': serializer.toJson<double?>(minNn),
      'maxNn': serializer.toJson<double?>(maxNn),
      'hti': serializer.toJson<double?>(hti),
      'tinn': serializer.toJson<double?>(tinn),
      'sdann1': serializer.toJson<double?>(sdann1),
      'sdann2': serializer.toJson<double?>(sdann2),
      'sdann5': serializer.toJson<double?>(sdann5),
      'sdnni1': serializer.toJson<double?>(sdnni1),
      'sdnni2': serializer.toJson<double?>(sdnni2),
      'sdnni5': serializer.toJson<double?>(sdnni5),
    };
  }

  HrvEntry copyWith({
    int? id,
    int? sessionId,
    int? patientId,
    String? timestamp,
    Value<double?> meanNn = const Value.absent(),
    Value<double?> sdnn = const Value.absent(),
    Value<double?> rmssd = const Value.absent(),
    Value<double?> sdsd = const Value.absent(),
    Value<double?> cvnn = const Value.absent(),
    Value<double?> cvsd = const Value.absent(),
    Value<double?> medianNn = const Value.absent(),
    Value<double?> madNn = const Value.absent(),
    Value<double?> mcvnn = const Value.absent(),
    Value<double?> iqrnn = const Value.absent(),
    Value<double?> sdrmssd = const Value.absent(),
    Value<double?> prc20nn = const Value.absent(),
    Value<double?> prc80nn = const Value.absent(),
    Value<double?> pnn50 = const Value.absent(),
    Value<double?> pnn20 = const Value.absent(),
    Value<double?> minNn = const Value.absent(),
    Value<double?> maxNn = const Value.absent(),
    Value<double?> hti = const Value.absent(),
    Value<double?> tinn = const Value.absent(),
    Value<double?> sdann1 = const Value.absent(),
    Value<double?> sdann2 = const Value.absent(),
    Value<double?> sdann5 = const Value.absent(),
    Value<double?> sdnni1 = const Value.absent(),
    Value<double?> sdnni2 = const Value.absent(),
    Value<double?> sdnni5 = const Value.absent(),
  }) => HrvEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    patientId: patientId ?? this.patientId,
    timestamp: timestamp ?? this.timestamp,
    meanNn: meanNn.present ? meanNn.value : this.meanNn,
    sdnn: sdnn.present ? sdnn.value : this.sdnn,
    rmssd: rmssd.present ? rmssd.value : this.rmssd,
    sdsd: sdsd.present ? sdsd.value : this.sdsd,
    cvnn: cvnn.present ? cvnn.value : this.cvnn,
    cvsd: cvsd.present ? cvsd.value : this.cvsd,
    medianNn: medianNn.present ? medianNn.value : this.medianNn,
    madNn: madNn.present ? madNn.value : this.madNn,
    mcvnn: mcvnn.present ? mcvnn.value : this.mcvnn,
    iqrnn: iqrnn.present ? iqrnn.value : this.iqrnn,
    sdrmssd: sdrmssd.present ? sdrmssd.value : this.sdrmssd,
    prc20nn: prc20nn.present ? prc20nn.value : this.prc20nn,
    prc80nn: prc80nn.present ? prc80nn.value : this.prc80nn,
    pnn50: pnn50.present ? pnn50.value : this.pnn50,
    pnn20: pnn20.present ? pnn20.value : this.pnn20,
    minNn: minNn.present ? minNn.value : this.minNn,
    maxNn: maxNn.present ? maxNn.value : this.maxNn,
    hti: hti.present ? hti.value : this.hti,
    tinn: tinn.present ? tinn.value : this.tinn,
    sdann1: sdann1.present ? sdann1.value : this.sdann1,
    sdann2: sdann2.present ? sdann2.value : this.sdann2,
    sdann5: sdann5.present ? sdann5.value : this.sdann5,
    sdnni1: sdnni1.present ? sdnni1.value : this.sdnni1,
    sdnni2: sdnni2.present ? sdnni2.value : this.sdnni2,
    sdnni5: sdnni5.present ? sdnni5.value : this.sdnni5,
  );
  HrvEntry copyWithCompanion(HrvEntriesCompanion data) {
    return HrvEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      meanNn: data.meanNn.present ? data.meanNn.value : this.meanNn,
      sdnn: data.sdnn.present ? data.sdnn.value : this.sdnn,
      rmssd: data.rmssd.present ? data.rmssd.value : this.rmssd,
      sdsd: data.sdsd.present ? data.sdsd.value : this.sdsd,
      cvnn: data.cvnn.present ? data.cvnn.value : this.cvnn,
      cvsd: data.cvsd.present ? data.cvsd.value : this.cvsd,
      medianNn: data.medianNn.present ? data.medianNn.value : this.medianNn,
      madNn: data.madNn.present ? data.madNn.value : this.madNn,
      mcvnn: data.mcvnn.present ? data.mcvnn.value : this.mcvnn,
      iqrnn: data.iqrnn.present ? data.iqrnn.value : this.iqrnn,
      sdrmssd: data.sdrmssd.present ? data.sdrmssd.value : this.sdrmssd,
      prc20nn: data.prc20nn.present ? data.prc20nn.value : this.prc20nn,
      prc80nn: data.prc80nn.present ? data.prc80nn.value : this.prc80nn,
      pnn50: data.pnn50.present ? data.pnn50.value : this.pnn50,
      pnn20: data.pnn20.present ? data.pnn20.value : this.pnn20,
      minNn: data.minNn.present ? data.minNn.value : this.minNn,
      maxNn: data.maxNn.present ? data.maxNn.value : this.maxNn,
      hti: data.hti.present ? data.hti.value : this.hti,
      tinn: data.tinn.present ? data.tinn.value : this.tinn,
      sdann1: data.sdann1.present ? data.sdann1.value : this.sdann1,
      sdann2: data.sdann2.present ? data.sdann2.value : this.sdann2,
      sdann5: data.sdann5.present ? data.sdann5.value : this.sdann5,
      sdnni1: data.sdnni1.present ? data.sdnni1.value : this.sdnni1,
      sdnni2: data.sdnni2.present ? data.sdnni2.value : this.sdnni2,
      sdnni5: data.sdnni5.present ? data.sdnni5.value : this.sdnni5,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HrvEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('meanNn: $meanNn, ')
          ..write('sdnn: $sdnn, ')
          ..write('rmssd: $rmssd, ')
          ..write('sdsd: $sdsd, ')
          ..write('cvnn: $cvnn, ')
          ..write('cvsd: $cvsd, ')
          ..write('medianNn: $medianNn, ')
          ..write('madNn: $madNn, ')
          ..write('mcvnn: $mcvnn, ')
          ..write('iqrnn: $iqrnn, ')
          ..write('sdrmssd: $sdrmssd, ')
          ..write('prc20nn: $prc20nn, ')
          ..write('prc80nn: $prc80nn, ')
          ..write('pnn50: $pnn50, ')
          ..write('pnn20: $pnn20, ')
          ..write('minNn: $minNn, ')
          ..write('maxNn: $maxNn, ')
          ..write('hti: $hti, ')
          ..write('tinn: $tinn, ')
          ..write('sdann1: $sdann1, ')
          ..write('sdann2: $sdann2, ')
          ..write('sdann5: $sdann5, ')
          ..write('sdnni1: $sdnni1, ')
          ..write('sdnni2: $sdnni2, ')
          ..write('sdnni5: $sdnni5')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sessionId,
    patientId,
    timestamp,
    meanNn,
    sdnn,
    rmssd,
    sdsd,
    cvnn,
    cvsd,
    medianNn,
    madNn,
    mcvnn,
    iqrnn,
    sdrmssd,
    prc20nn,
    prc80nn,
    pnn50,
    pnn20,
    minNn,
    maxNn,
    hti,
    tinn,
    sdann1,
    sdann2,
    sdann5,
    sdnni1,
    sdnni2,
    sdnni5,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HrvEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.patientId == this.patientId &&
          other.timestamp == this.timestamp &&
          other.meanNn == this.meanNn &&
          other.sdnn == this.sdnn &&
          other.rmssd == this.rmssd &&
          other.sdsd == this.sdsd &&
          other.cvnn == this.cvnn &&
          other.cvsd == this.cvsd &&
          other.medianNn == this.medianNn &&
          other.madNn == this.madNn &&
          other.mcvnn == this.mcvnn &&
          other.iqrnn == this.iqrnn &&
          other.sdrmssd == this.sdrmssd &&
          other.prc20nn == this.prc20nn &&
          other.prc80nn == this.prc80nn &&
          other.pnn50 == this.pnn50 &&
          other.pnn20 == this.pnn20 &&
          other.minNn == this.minNn &&
          other.maxNn == this.maxNn &&
          other.hti == this.hti &&
          other.tinn == this.tinn &&
          other.sdann1 == this.sdann1 &&
          other.sdann2 == this.sdann2 &&
          other.sdann5 == this.sdann5 &&
          other.sdnni1 == this.sdnni1 &&
          other.sdnni2 == this.sdnni2 &&
          other.sdnni5 == this.sdnni5);
}

class HrvEntriesCompanion extends UpdateCompanion<HrvEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> patientId;
  final Value<String> timestamp;
  final Value<double?> meanNn;
  final Value<double?> sdnn;
  final Value<double?> rmssd;
  final Value<double?> sdsd;
  final Value<double?> cvnn;
  final Value<double?> cvsd;
  final Value<double?> medianNn;
  final Value<double?> madNn;
  final Value<double?> mcvnn;
  final Value<double?> iqrnn;
  final Value<double?> sdrmssd;
  final Value<double?> prc20nn;
  final Value<double?> prc80nn;
  final Value<double?> pnn50;
  final Value<double?> pnn20;
  final Value<double?> minNn;
  final Value<double?> maxNn;
  final Value<double?> hti;
  final Value<double?> tinn;
  final Value<double?> sdann1;
  final Value<double?> sdann2;
  final Value<double?> sdann5;
  final Value<double?> sdnni1;
  final Value<double?> sdnni2;
  final Value<double?> sdnni5;
  const HrvEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.meanNn = const Value.absent(),
    this.sdnn = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.sdsd = const Value.absent(),
    this.cvnn = const Value.absent(),
    this.cvsd = const Value.absent(),
    this.medianNn = const Value.absent(),
    this.madNn = const Value.absent(),
    this.mcvnn = const Value.absent(),
    this.iqrnn = const Value.absent(),
    this.sdrmssd = const Value.absent(),
    this.prc20nn = const Value.absent(),
    this.prc80nn = const Value.absent(),
    this.pnn50 = const Value.absent(),
    this.pnn20 = const Value.absent(),
    this.minNn = const Value.absent(),
    this.maxNn = const Value.absent(),
    this.hti = const Value.absent(),
    this.tinn = const Value.absent(),
    this.sdann1 = const Value.absent(),
    this.sdann2 = const Value.absent(),
    this.sdann5 = const Value.absent(),
    this.sdnni1 = const Value.absent(),
    this.sdnni2 = const Value.absent(),
    this.sdnni5 = const Value.absent(),
  });
  HrvEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int patientId,
    required String timestamp,
    this.meanNn = const Value.absent(),
    this.sdnn = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.sdsd = const Value.absent(),
    this.cvnn = const Value.absent(),
    this.cvsd = const Value.absent(),
    this.medianNn = const Value.absent(),
    this.madNn = const Value.absent(),
    this.mcvnn = const Value.absent(),
    this.iqrnn = const Value.absent(),
    this.sdrmssd = const Value.absent(),
    this.prc20nn = const Value.absent(),
    this.prc80nn = const Value.absent(),
    this.pnn50 = const Value.absent(),
    this.pnn20 = const Value.absent(),
    this.minNn = const Value.absent(),
    this.maxNn = const Value.absent(),
    this.hti = const Value.absent(),
    this.tinn = const Value.absent(),
    this.sdann1 = const Value.absent(),
    this.sdann2 = const Value.absent(),
    this.sdann5 = const Value.absent(),
    this.sdnni1 = const Value.absent(),
    this.sdnni2 = const Value.absent(),
    this.sdnni5 = const Value.absent(),
  }) : sessionId = Value(sessionId),
       patientId = Value(patientId),
       timestamp = Value(timestamp);
  static Insertable<HrvEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? patientId,
    Expression<String>? timestamp,
    Expression<double>? meanNn,
    Expression<double>? sdnn,
    Expression<double>? rmssd,
    Expression<double>? sdsd,
    Expression<double>? cvnn,
    Expression<double>? cvsd,
    Expression<double>? medianNn,
    Expression<double>? madNn,
    Expression<double>? mcvnn,
    Expression<double>? iqrnn,
    Expression<double>? sdrmssd,
    Expression<double>? prc20nn,
    Expression<double>? prc80nn,
    Expression<double>? pnn50,
    Expression<double>? pnn20,
    Expression<double>? minNn,
    Expression<double>? maxNn,
    Expression<double>? hti,
    Expression<double>? tinn,
    Expression<double>? sdann1,
    Expression<double>? sdann2,
    Expression<double>? sdann5,
    Expression<double>? sdnni1,
    Expression<double>? sdnni2,
    Expression<double>? sdnni5,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (patientId != null) 'patient_id': patientId,
      if (timestamp != null) 'timestamp': timestamp,
      if (meanNn != null) 'mean_nn': meanNn,
      if (sdnn != null) 'sdnn': sdnn,
      if (rmssd != null) 'rmssd': rmssd,
      if (sdsd != null) 'sdsd': sdsd,
      if (cvnn != null) 'cvnn': cvnn,
      if (cvsd != null) 'cvsd': cvsd,
      if (medianNn != null) 'median_nn': medianNn,
      if (madNn != null) 'mad_nn': madNn,
      if (mcvnn != null) 'mcvnn': mcvnn,
      if (iqrnn != null) 'iqrnn': iqrnn,
      if (sdrmssd != null) 'sdrmssd': sdrmssd,
      if (prc20nn != null) 'prc20nn': prc20nn,
      if (prc80nn != null) 'prc80nn': prc80nn,
      if (pnn50 != null) 'pnn50': pnn50,
      if (pnn20 != null) 'pnn20': pnn20,
      if (minNn != null) 'min_nn': minNn,
      if (maxNn != null) 'max_nn': maxNn,
      if (hti != null) 'hti': hti,
      if (tinn != null) 'tinn': tinn,
      if (sdann1 != null) 'sdann1': sdann1,
      if (sdann2 != null) 'sdann2': sdann2,
      if (sdann5 != null) 'sdann5': sdann5,
      if (sdnni1 != null) 'sdnni1': sdnni1,
      if (sdnni2 != null) 'sdnni2': sdnni2,
      if (sdnni5 != null) 'sdnni5': sdnni5,
    });
  }

  HrvEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? patientId,
    Value<String>? timestamp,
    Value<double?>? meanNn,
    Value<double?>? sdnn,
    Value<double?>? rmssd,
    Value<double?>? sdsd,
    Value<double?>? cvnn,
    Value<double?>? cvsd,
    Value<double?>? medianNn,
    Value<double?>? madNn,
    Value<double?>? mcvnn,
    Value<double?>? iqrnn,
    Value<double?>? sdrmssd,
    Value<double?>? prc20nn,
    Value<double?>? prc80nn,
    Value<double?>? pnn50,
    Value<double?>? pnn20,
    Value<double?>? minNn,
    Value<double?>? maxNn,
    Value<double?>? hti,
    Value<double?>? tinn,
    Value<double?>? sdann1,
    Value<double?>? sdann2,
    Value<double?>? sdann5,
    Value<double?>? sdnni1,
    Value<double?>? sdnni2,
    Value<double?>? sdnni5,
  }) {
    return HrvEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      meanNn: meanNn ?? this.meanNn,
      sdnn: sdnn ?? this.sdnn,
      rmssd: rmssd ?? this.rmssd,
      sdsd: sdsd ?? this.sdsd,
      cvnn: cvnn ?? this.cvnn,
      cvsd: cvsd ?? this.cvsd,
      medianNn: medianNn ?? this.medianNn,
      madNn: madNn ?? this.madNn,
      mcvnn: mcvnn ?? this.mcvnn,
      iqrnn: iqrnn ?? this.iqrnn,
      sdrmssd: sdrmssd ?? this.sdrmssd,
      prc20nn: prc20nn ?? this.prc20nn,
      prc80nn: prc80nn ?? this.prc80nn,
      pnn50: pnn50 ?? this.pnn50,
      pnn20: pnn20 ?? this.pnn20,
      minNn: minNn ?? this.minNn,
      maxNn: maxNn ?? this.maxNn,
      hti: hti ?? this.hti,
      tinn: tinn ?? this.tinn,
      sdann1: sdann1 ?? this.sdann1,
      sdann2: sdann2 ?? this.sdann2,
      sdann5: sdann5 ?? this.sdann5,
      sdnni1: sdnni1 ?? this.sdnni1,
      sdnni2: sdnni2 ?? this.sdnni2,
      sdnni5: sdnni5 ?? this.sdnni5,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (meanNn.present) {
      map['mean_nn'] = Variable<double>(meanNn.value);
    }
    if (sdnn.present) {
      map['sdnn'] = Variable<double>(sdnn.value);
    }
    if (rmssd.present) {
      map['rmssd'] = Variable<double>(rmssd.value);
    }
    if (sdsd.present) {
      map['sdsd'] = Variable<double>(sdsd.value);
    }
    if (cvnn.present) {
      map['cvnn'] = Variable<double>(cvnn.value);
    }
    if (cvsd.present) {
      map['cvsd'] = Variable<double>(cvsd.value);
    }
    if (medianNn.present) {
      map['median_nn'] = Variable<double>(medianNn.value);
    }
    if (madNn.present) {
      map['mad_nn'] = Variable<double>(madNn.value);
    }
    if (mcvnn.present) {
      map['mcvnn'] = Variable<double>(mcvnn.value);
    }
    if (iqrnn.present) {
      map['iqrnn'] = Variable<double>(iqrnn.value);
    }
    if (sdrmssd.present) {
      map['sdrmssd'] = Variable<double>(sdrmssd.value);
    }
    if (prc20nn.present) {
      map['prc20nn'] = Variable<double>(prc20nn.value);
    }
    if (prc80nn.present) {
      map['prc80nn'] = Variable<double>(prc80nn.value);
    }
    if (pnn50.present) {
      map['pnn50'] = Variable<double>(pnn50.value);
    }
    if (pnn20.present) {
      map['pnn20'] = Variable<double>(pnn20.value);
    }
    if (minNn.present) {
      map['min_nn'] = Variable<double>(minNn.value);
    }
    if (maxNn.present) {
      map['max_nn'] = Variable<double>(maxNn.value);
    }
    if (hti.present) {
      map['hti'] = Variable<double>(hti.value);
    }
    if (tinn.present) {
      map['tinn'] = Variable<double>(tinn.value);
    }
    if (sdann1.present) {
      map['sdann1'] = Variable<double>(sdann1.value);
    }
    if (sdann2.present) {
      map['sdann2'] = Variable<double>(sdann2.value);
    }
    if (sdann5.present) {
      map['sdann5'] = Variable<double>(sdann5.value);
    }
    if (sdnni1.present) {
      map['sdnni1'] = Variable<double>(sdnni1.value);
    }
    if (sdnni2.present) {
      map['sdnni2'] = Variable<double>(sdnni2.value);
    }
    if (sdnni5.present) {
      map['sdnni5'] = Variable<double>(sdnni5.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HrvEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('patientId: $patientId, ')
          ..write('timestamp: $timestamp, ')
          ..write('meanNn: $meanNn, ')
          ..write('sdnn: $sdnn, ')
          ..write('rmssd: $rmssd, ')
          ..write('sdsd: $sdsd, ')
          ..write('cvnn: $cvnn, ')
          ..write('cvsd: $cvsd, ')
          ..write('medianNn: $medianNn, ')
          ..write('madNn: $madNn, ')
          ..write('mcvnn: $mcvnn, ')
          ..write('iqrnn: $iqrnn, ')
          ..write('sdrmssd: $sdrmssd, ')
          ..write('prc20nn: $prc20nn, ')
          ..write('prc80nn: $prc80nn, ')
          ..write('pnn50: $pnn50, ')
          ..write('pnn20: $pnn20, ')
          ..write('minNn: $minNn, ')
          ..write('maxNn: $maxNn, ')
          ..write('hti: $hti, ')
          ..write('tinn: $tinn, ')
          ..write('sdann1: $sdann1, ')
          ..write('sdann2: $sdann2, ')
          ..write('sdann5: $sdann5, ')
          ..write('sdnni1: $sdnni1, ')
          ..write('sdnni2: $sdnni2, ')
          ..write('sdnni5: $sdnni5')
          ..write(')'))
        .toString();
  }
}

class $PsychometricEntriesTable extends PsychometricEntries
    with TableInfo<$PsychometricEntriesTable, PsychometricEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PsychometricEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scaleTypeMeta = const VerificationMeta(
    'scaleType',
  );
  @override
  late final GeneratedColumn<String> scaleType = GeneratedColumn<String>(
    'scale_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityLevelMeta = const VerificationMeta(
    'severityLevel',
  );
  @override
  late final GeneratedColumn<String> severityLevel = GeneratedColumn<String>(
    'severity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responsesJsonMeta = const VerificationMeta(
    'responsesJson',
  );
  @override
  late final GeneratedColumn<String> responsesJson = GeneratedColumn<String>(
    'responses_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _administeredAtMeta = const VerificationMeta(
    'administeredAt',
  );
  @override
  late final GeneratedColumn<String> administeredAt = GeneratedColumn<String>(
    'administered_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _administeredByMeta = const VerificationMeta(
    'administeredBy',
  );
  @override
  late final GeneratedColumn<String> administeredBy = GeneratedColumn<String>(
    'administered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiresReviewMeta = const VerificationMeta(
    'requiresReview',
  );
  @override
  late final GeneratedColumn<bool> requiresReview = GeneratedColumn<bool>(
    'requires_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    scaleType,
    totalScore,
    severityLevel,
    responsesJson,
    administeredAt,
    administeredBy,
    requiresReview,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'psychometric_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PsychometricEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('scale_type')) {
      context.handle(
        _scaleTypeMeta,
        scaleType.isAcceptableOrUnknown(data['scale_type']!, _scaleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_scaleTypeMeta);
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_totalScoreMeta);
    }
    if (data.containsKey('severity_level')) {
      context.handle(
        _severityLevelMeta,
        severityLevel.isAcceptableOrUnknown(
          data['severity_level']!,
          _severityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_severityLevelMeta);
    }
    if (data.containsKey('responses_json')) {
      context.handle(
        _responsesJsonMeta,
        responsesJson.isAcceptableOrUnknown(
          data['responses_json']!,
          _responsesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responsesJsonMeta);
    }
    if (data.containsKey('administered_at')) {
      context.handle(
        _administeredAtMeta,
        administeredAt.isAcceptableOrUnknown(
          data['administered_at']!,
          _administeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_administeredAtMeta);
    }
    if (data.containsKey('administered_by')) {
      context.handle(
        _administeredByMeta,
        administeredBy.isAcceptableOrUnknown(
          data['administered_by']!,
          _administeredByMeta,
        ),
      );
    }
    if (data.containsKey('requires_review')) {
      context.handle(
        _requiresReviewMeta,
        requiresReview.isAcceptableOrUnknown(
          data['requires_review']!,
          _requiresReviewMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PsychometricEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PsychometricEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      scaleType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}scale_type'],
          )!,
      totalScore:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total_score'],
          )!,
      severityLevel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}severity_level'],
          )!,
      responsesJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}responses_json'],
          )!,
      administeredAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}administered_at'],
          )!,
      administeredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}administered_by'],
      ),
      requiresReview:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}requires_review'],
          )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $PsychometricEntriesTable createAlias(String alias) {
    return $PsychometricEntriesTable(attachedDatabase, alias);
  }
}

class PsychometricEntry extends DataClass
    implements Insertable<PsychometricEntry> {
  final int id;
  final int patientId;
  final String scaleType;
  final int totalScore;
  final String severityLevel;
  final String responsesJson;
  final String administeredAt;
  final String? administeredBy;
  final bool requiresReview;
  final String? notes;
  const PsychometricEntry({
    required this.id,
    required this.patientId,
    required this.scaleType,
    required this.totalScore,
    required this.severityLevel,
    required this.responsesJson,
    required this.administeredAt,
    this.administeredBy,
    required this.requiresReview,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['scale_type'] = Variable<String>(scaleType);
    map['total_score'] = Variable<int>(totalScore);
    map['severity_level'] = Variable<String>(severityLevel);
    map['responses_json'] = Variable<String>(responsesJson);
    map['administered_at'] = Variable<String>(administeredAt);
    if (!nullToAbsent || administeredBy != null) {
      map['administered_by'] = Variable<String>(administeredBy);
    }
    map['requires_review'] = Variable<bool>(requiresReview);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  PsychometricEntriesCompanion toCompanion(bool nullToAbsent) {
    return PsychometricEntriesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      scaleType: Value(scaleType),
      totalScore: Value(totalScore),
      severityLevel: Value(severityLevel),
      responsesJson: Value(responsesJson),
      administeredAt: Value(administeredAt),
      administeredBy:
          administeredBy == null && nullToAbsent
              ? const Value.absent()
              : Value(administeredBy),
      requiresReview: Value(requiresReview),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory PsychometricEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PsychometricEntry(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      scaleType: serializer.fromJson<String>(json['scaleType']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      severityLevel: serializer.fromJson<String>(json['severityLevel']),
      responsesJson: serializer.fromJson<String>(json['responsesJson']),
      administeredAt: serializer.fromJson<String>(json['administeredAt']),
      administeredBy: serializer.fromJson<String?>(json['administeredBy']),
      requiresReview: serializer.fromJson<bool>(json['requiresReview']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'scaleType': serializer.toJson<String>(scaleType),
      'totalScore': serializer.toJson<int>(totalScore),
      'severityLevel': serializer.toJson<String>(severityLevel),
      'responsesJson': serializer.toJson<String>(responsesJson),
      'administeredAt': serializer.toJson<String>(administeredAt),
      'administeredBy': serializer.toJson<String?>(administeredBy),
      'requiresReview': serializer.toJson<bool>(requiresReview),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  PsychometricEntry copyWith({
    int? id,
    int? patientId,
    String? scaleType,
    int? totalScore,
    String? severityLevel,
    String? responsesJson,
    String? administeredAt,
    Value<String?> administeredBy = const Value.absent(),
    bool? requiresReview,
    Value<String?> notes = const Value.absent(),
  }) => PsychometricEntry(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    scaleType: scaleType ?? this.scaleType,
    totalScore: totalScore ?? this.totalScore,
    severityLevel: severityLevel ?? this.severityLevel,
    responsesJson: responsesJson ?? this.responsesJson,
    administeredAt: administeredAt ?? this.administeredAt,
    administeredBy:
        administeredBy.present ? administeredBy.value : this.administeredBy,
    requiresReview: requiresReview ?? this.requiresReview,
    notes: notes.present ? notes.value : this.notes,
  );
  PsychometricEntry copyWithCompanion(PsychometricEntriesCompanion data) {
    return PsychometricEntry(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      scaleType: data.scaleType.present ? data.scaleType.value : this.scaleType,
      totalScore:
          data.totalScore.present ? data.totalScore.value : this.totalScore,
      severityLevel:
          data.severityLevel.present
              ? data.severityLevel.value
              : this.severityLevel,
      responsesJson:
          data.responsesJson.present
              ? data.responsesJson.value
              : this.responsesJson,
      administeredAt:
          data.administeredAt.present
              ? data.administeredAt.value
              : this.administeredAt,
      administeredBy:
          data.administeredBy.present
              ? data.administeredBy.value
              : this.administeredBy,
      requiresReview:
          data.requiresReview.present
              ? data.requiresReview.value
              : this.requiresReview,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PsychometricEntry(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('scaleType: $scaleType, ')
          ..write('totalScore: $totalScore, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('responsesJson: $responsesJson, ')
          ..write('administeredAt: $administeredAt, ')
          ..write('administeredBy: $administeredBy, ')
          ..write('requiresReview: $requiresReview, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    scaleType,
    totalScore,
    severityLevel,
    responsesJson,
    administeredAt,
    administeredBy,
    requiresReview,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PsychometricEntry &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.scaleType == this.scaleType &&
          other.totalScore == this.totalScore &&
          other.severityLevel == this.severityLevel &&
          other.responsesJson == this.responsesJson &&
          other.administeredAt == this.administeredAt &&
          other.administeredBy == this.administeredBy &&
          other.requiresReview == this.requiresReview &&
          other.notes == this.notes);
}

class PsychometricEntriesCompanion extends UpdateCompanion<PsychometricEntry> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<String> scaleType;
  final Value<int> totalScore;
  final Value<String> severityLevel;
  final Value<String> responsesJson;
  final Value<String> administeredAt;
  final Value<String?> administeredBy;
  final Value<bool> requiresReview;
  final Value<String?> notes;
  const PsychometricEntriesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.scaleType = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.severityLevel = const Value.absent(),
    this.responsesJson = const Value.absent(),
    this.administeredAt = const Value.absent(),
    this.administeredBy = const Value.absent(),
    this.requiresReview = const Value.absent(),
    this.notes = const Value.absent(),
  });
  PsychometricEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    required String scaleType,
    required int totalScore,
    required String severityLevel,
    required String responsesJson,
    required String administeredAt,
    this.administeredBy = const Value.absent(),
    this.requiresReview = const Value.absent(),
    this.notes = const Value.absent(),
  }) : patientId = Value(patientId),
       scaleType = Value(scaleType),
       totalScore = Value(totalScore),
       severityLevel = Value(severityLevel),
       responsesJson = Value(responsesJson),
       administeredAt = Value(administeredAt);
  static Insertable<PsychometricEntry> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<String>? scaleType,
    Expression<int>? totalScore,
    Expression<String>? severityLevel,
    Expression<String>? responsesJson,
    Expression<String>? administeredAt,
    Expression<String>? administeredBy,
    Expression<bool>? requiresReview,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (scaleType != null) 'scale_type': scaleType,
      if (totalScore != null) 'total_score': totalScore,
      if (severityLevel != null) 'severity_level': severityLevel,
      if (responsesJson != null) 'responses_json': responsesJson,
      if (administeredAt != null) 'administered_at': administeredAt,
      if (administeredBy != null) 'administered_by': administeredBy,
      if (requiresReview != null) 'requires_review': requiresReview,
      if (notes != null) 'notes': notes,
    });
  }

  PsychometricEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? patientId,
    Value<String>? scaleType,
    Value<int>? totalScore,
    Value<String>? severityLevel,
    Value<String>? responsesJson,
    Value<String>? administeredAt,
    Value<String?>? administeredBy,
    Value<bool>? requiresReview,
    Value<String?>? notes,
  }) {
    return PsychometricEntriesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      scaleType: scaleType ?? this.scaleType,
      totalScore: totalScore ?? this.totalScore,
      severityLevel: severityLevel ?? this.severityLevel,
      responsesJson: responsesJson ?? this.responsesJson,
      administeredAt: administeredAt ?? this.administeredAt,
      administeredBy: administeredBy ?? this.administeredBy,
      requiresReview: requiresReview ?? this.requiresReview,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (scaleType.present) {
      map['scale_type'] = Variable<String>(scaleType.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (severityLevel.present) {
      map['severity_level'] = Variable<String>(severityLevel.value);
    }
    if (responsesJson.present) {
      map['responses_json'] = Variable<String>(responsesJson.value);
    }
    if (administeredAt.present) {
      map['administered_at'] = Variable<String>(administeredAt.value);
    }
    if (administeredBy.present) {
      map['administered_by'] = Variable<String>(administeredBy.value);
    }
    if (requiresReview.present) {
      map['requires_review'] = Variable<bool>(requiresReview.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PsychometricEntriesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('scaleType: $scaleType, ')
          ..write('totalScore: $totalScore, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('responsesJson: $responsesJson, ')
          ..write('administeredAt: $administeredAt, ')
          ..write('administeredBy: $administeredBy, ')
          ..write('requiresReview: $requiresReview, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SessionSummariesTable extends SessionSummaries
    with TableInfo<$SessionSummariesTable, SessionSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recording'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<String> endedAt = GeneratedColumn<String>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _breathRateMeta = const VerificationMeta(
    'breathRate',
  );
  @override
  late final GeneratedColumn<int> breathRate = GeneratedColumn<int>(
    'breath_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breathSourceMeta = const VerificationMeta(
    'breathSource',
  );
  @override
  late final GeneratedColumn<String> breathSource = GeneratedColumn<String>(
    'breath_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHeartRateMeta = const VerificationMeta(
    'avgHeartRate',
  );
  @override
  late final GeneratedColumn<double> avgHeartRate = GeneratedColumn<double>(
    'avg_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minHeartRateMeta = const VerificationMeta(
    'minHeartRate',
  );
  @override
  late final GeneratedColumn<int> minHeartRate = GeneratedColumn<int>(
    'min_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHeartRateMeta = const VerificationMeta(
    'maxHeartRate',
  );
  @override
  late final GeneratedColumn<int> maxHeartRate = GeneratedColumn<int>(
    'max_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdMeta = const VerificationMeta('rmssd');
  @override
  late final GeneratedColumn<double> rmssd = GeneratedColumn<double>(
    'rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sdnnMeta = const VerificationMeta('sdnn');
  @override
  late final GeneratedColumn<double> sdnn = GeneratedColumn<double>(
    'sdnn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meanNnMeta = const VerificationMeta('meanNn');
  @override
  late final GeneratedColumn<double> meanNn = GeneratedColumn<double>(
    'mean_nn',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pnn50Meta = const VerificationMeta('pnn50');
  @override
  late final GeneratedColumn<double> pnn50 = GeneratedColumn<double>(
    'pnn50',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrReadingsJsonMeta = const VerificationMeta(
    'hrReadingsJson',
  );
  @override
  late final GeneratedColumn<String> hrReadingsJson = GeneratedColumn<String>(
    'hr_readings_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extendedMetricsJsonMeta =
      const VerificationMeta('extendedMetricsJson');
  @override
  late final GeneratedColumn<String> extendedMetricsJson =
      GeneratedColumn<String>(
        'extended_metrics_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    sessionType,
    startedAt,
    endedAt,
    durationSeconds,
    breathRate,
    breathSource,
    avgHeartRate,
    minHeartRate,
    maxHeartRate,
    rmssd,
    sdnn,
    meanNn,
    pnn50,
    hrReadingsJson,
    extendedMetricsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSummary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('breath_rate')) {
      context.handle(
        _breathRateMeta,
        breathRate.isAcceptableOrUnknown(data['breath_rate']!, _breathRateMeta),
      );
    }
    if (data.containsKey('breath_source')) {
      context.handle(
        _breathSourceMeta,
        breathSource.isAcceptableOrUnknown(
          data['breath_source']!,
          _breathSourceMeta,
        ),
      );
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
        _avgHeartRateMeta,
        avgHeartRate.isAcceptableOrUnknown(
          data['avg_heart_rate']!,
          _avgHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('min_heart_rate')) {
      context.handle(
        _minHeartRateMeta,
        minHeartRate.isAcceptableOrUnknown(
          data['min_heart_rate']!,
          _minHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
        _maxHeartRateMeta,
        maxHeartRate.isAcceptableOrUnknown(
          data['max_heart_rate']!,
          _maxHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('rmssd')) {
      context.handle(
        _rmssdMeta,
        rmssd.isAcceptableOrUnknown(data['rmssd']!, _rmssdMeta),
      );
    }
    if (data.containsKey('sdnn')) {
      context.handle(
        _sdnnMeta,
        sdnn.isAcceptableOrUnknown(data['sdnn']!, _sdnnMeta),
      );
    }
    if (data.containsKey('mean_nn')) {
      context.handle(
        _meanNnMeta,
        meanNn.isAcceptableOrUnknown(data['mean_nn']!, _meanNnMeta),
      );
    }
    if (data.containsKey('pnn50')) {
      context.handle(
        _pnn50Meta,
        pnn50.isAcceptableOrUnknown(data['pnn50']!, _pnn50Meta),
      );
    }
    if (data.containsKey('hr_readings_json')) {
      context.handle(
        _hrReadingsJsonMeta,
        hrReadingsJson.isAcceptableOrUnknown(
          data['hr_readings_json']!,
          _hrReadingsJsonMeta,
        ),
      );
    }
    if (data.containsKey('extended_metrics_json')) {
      context.handle(
        _extendedMetricsJsonMeta,
        extendedMetricsJson.isAcceptableOrUnknown(
          data['extended_metrics_json']!,
          _extendedMetricsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSummary(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      sessionType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_type'],
          )!,
      startedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}started_at'],
          )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}duration_seconds'],
          )!,
      breathRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}breath_rate'],
      ),
      breathSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breath_source'],
      ),
      avgHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_heart_rate'],
      ),
      minHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_heart_rate'],
      ),
      maxHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_heart_rate'],
      ),
      rmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd'],
      ),
      sdnn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sdnn'],
      ),
      meanNn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean_nn'],
      ),
      pnn50: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pnn50'],
      ),
      hrReadingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hr_readings_json'],
      ),
      extendedMetricsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extended_metrics_json'],
      ),
    );
  }

  @override
  $SessionSummariesTable createAlias(String alias) {
    return $SessionSummariesTable(attachedDatabase, alias);
  }
}

class SessionSummary extends DataClass implements Insertable<SessionSummary> {
  final int id;
  final int patientId;
  final String sessionType;
  final String startedAt;
  final String? endedAt;
  final int durationSeconds;
  final int? breathRate;
  final String? breathSource;
  final double? avgHeartRate;
  final int? minHeartRate;
  final int? maxHeartRate;
  final double? rmssd;
  final double? sdnn;
  final double? meanNn;
  final double? pnn50;
  final String? hrReadingsJson;
  final String? extendedMetricsJson;
  const SessionSummary({
    required this.id,
    required this.patientId,
    required this.sessionType,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    this.breathRate,
    this.breathSource,
    this.avgHeartRate,
    this.minHeartRate,
    this.maxHeartRate,
    this.rmssd,
    this.sdnn,
    this.meanNn,
    this.pnn50,
    this.hrReadingsJson,
    this.extendedMetricsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['session_type'] = Variable<String>(sessionType);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<String>(endedAt);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || breathRate != null) {
      map['breath_rate'] = Variable<int>(breathRate);
    }
    if (!nullToAbsent || breathSource != null) {
      map['breath_source'] = Variable<String>(breathSource);
    }
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate);
    }
    if (!nullToAbsent || minHeartRate != null) {
      map['min_heart_rate'] = Variable<int>(minHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate);
    }
    if (!nullToAbsent || rmssd != null) {
      map['rmssd'] = Variable<double>(rmssd);
    }
    if (!nullToAbsent || sdnn != null) {
      map['sdnn'] = Variable<double>(sdnn);
    }
    if (!nullToAbsent || meanNn != null) {
      map['mean_nn'] = Variable<double>(meanNn);
    }
    if (!nullToAbsent || pnn50 != null) {
      map['pnn50'] = Variable<double>(pnn50);
    }
    if (!nullToAbsent || hrReadingsJson != null) {
      map['hr_readings_json'] = Variable<String>(hrReadingsJson);
    }
    if (!nullToAbsent || extendedMetricsJson != null) {
      map['extended_metrics_json'] = Variable<String>(extendedMetricsJson);
    }
    return map;
  }

  SessionSummariesCompanion toCompanion(bool nullToAbsent) {
    return SessionSummariesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      sessionType: Value(sessionType),
      startedAt: Value(startedAt),
      endedAt:
          endedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(endedAt),
      durationSeconds: Value(durationSeconds),
      breathRate:
          breathRate == null && nullToAbsent
              ? const Value.absent()
              : Value(breathRate),
      breathSource:
          breathSource == null && nullToAbsent
              ? const Value.absent()
              : Value(breathSource),
      avgHeartRate:
          avgHeartRate == null && nullToAbsent
              ? const Value.absent()
              : Value(avgHeartRate),
      minHeartRate:
          minHeartRate == null && nullToAbsent
              ? const Value.absent()
              : Value(minHeartRate),
      maxHeartRate:
          maxHeartRate == null && nullToAbsent
              ? const Value.absent()
              : Value(maxHeartRate),
      rmssd:
          rmssd == null && nullToAbsent ? const Value.absent() : Value(rmssd),
      sdnn: sdnn == null && nullToAbsent ? const Value.absent() : Value(sdnn),
      meanNn:
          meanNn == null && nullToAbsent ? const Value.absent() : Value(meanNn),
      pnn50:
          pnn50 == null && nullToAbsent ? const Value.absent() : Value(pnn50),
      hrReadingsJson:
          hrReadingsJson == null && nullToAbsent
              ? const Value.absent()
              : Value(hrReadingsJson),
      extendedMetricsJson:
          extendedMetricsJson == null && nullToAbsent
              ? const Value.absent()
              : Value(extendedMetricsJson),
    );
  }

  factory SessionSummary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSummary(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      endedAt: serializer.fromJson<String?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      breathRate: serializer.fromJson<int?>(json['breathRate']),
      breathSource: serializer.fromJson<String?>(json['breathSource']),
      avgHeartRate: serializer.fromJson<double?>(json['avgHeartRate']),
      minHeartRate: serializer.fromJson<int?>(json['minHeartRate']),
      maxHeartRate: serializer.fromJson<int?>(json['maxHeartRate']),
      rmssd: serializer.fromJson<double?>(json['rmssd']),
      sdnn: serializer.fromJson<double?>(json['sdnn']),
      meanNn: serializer.fromJson<double?>(json['meanNn']),
      pnn50: serializer.fromJson<double?>(json['pnn50']),
      hrReadingsJson: serializer.fromJson<String?>(json['hrReadingsJson']),
      extendedMetricsJson: serializer.fromJson<String?>(
        json['extendedMetricsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'sessionType': serializer.toJson<String>(sessionType),
      'startedAt': serializer.toJson<String>(startedAt),
      'endedAt': serializer.toJson<String?>(endedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'breathRate': serializer.toJson<int?>(breathRate),
      'breathSource': serializer.toJson<String?>(breathSource),
      'avgHeartRate': serializer.toJson<double?>(avgHeartRate),
      'minHeartRate': serializer.toJson<int?>(minHeartRate),
      'maxHeartRate': serializer.toJson<int?>(maxHeartRate),
      'rmssd': serializer.toJson<double?>(rmssd),
      'sdnn': serializer.toJson<double?>(sdnn),
      'meanNn': serializer.toJson<double?>(meanNn),
      'pnn50': serializer.toJson<double?>(pnn50),
      'hrReadingsJson': serializer.toJson<String?>(hrReadingsJson),
      'extendedMetricsJson': serializer.toJson<String?>(extendedMetricsJson),
    };
  }

  SessionSummary copyWith({
    int? id,
    int? patientId,
    String? sessionType,
    String? startedAt,
    Value<String?> endedAt = const Value.absent(),
    int? durationSeconds,
    Value<int?> breathRate = const Value.absent(),
    Value<String?> breathSource = const Value.absent(),
    Value<double?> avgHeartRate = const Value.absent(),
    Value<int?> minHeartRate = const Value.absent(),
    Value<int?> maxHeartRate = const Value.absent(),
    Value<double?> rmssd = const Value.absent(),
    Value<double?> sdnn = const Value.absent(),
    Value<double?> meanNn = const Value.absent(),
    Value<double?> pnn50 = const Value.absent(),
    Value<String?> hrReadingsJson = const Value.absent(),
    Value<String?> extendedMetricsJson = const Value.absent(),
  }) => SessionSummary(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    sessionType: sessionType ?? this.sessionType,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    breathRate: breathRate.present ? breathRate.value : this.breathRate,
    breathSource: breathSource.present ? breathSource.value : this.breathSource,
    avgHeartRate: avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
    minHeartRate: minHeartRate.present ? minHeartRate.value : this.minHeartRate,
    maxHeartRate: maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
    rmssd: rmssd.present ? rmssd.value : this.rmssd,
    sdnn: sdnn.present ? sdnn.value : this.sdnn,
    meanNn: meanNn.present ? meanNn.value : this.meanNn,
    pnn50: pnn50.present ? pnn50.value : this.pnn50,
    hrReadingsJson:
        hrReadingsJson.present ? hrReadingsJson.value : this.hrReadingsJson,
    extendedMetricsJson:
        extendedMetricsJson.present
            ? extendedMetricsJson.value
            : this.extendedMetricsJson,
  );
  SessionSummary copyWithCompanion(SessionSummariesCompanion data) {
    return SessionSummary(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds:
          data.durationSeconds.present
              ? data.durationSeconds.value
              : this.durationSeconds,
      breathRate:
          data.breathRate.present ? data.breathRate.value : this.breathRate,
      breathSource:
          data.breathSource.present
              ? data.breathSource.value
              : this.breathSource,
      avgHeartRate:
          data.avgHeartRate.present
              ? data.avgHeartRate.value
              : this.avgHeartRate,
      minHeartRate:
          data.minHeartRate.present
              ? data.minHeartRate.value
              : this.minHeartRate,
      maxHeartRate:
          data.maxHeartRate.present
              ? data.maxHeartRate.value
              : this.maxHeartRate,
      rmssd: data.rmssd.present ? data.rmssd.value : this.rmssd,
      sdnn: data.sdnn.present ? data.sdnn.value : this.sdnn,
      meanNn: data.meanNn.present ? data.meanNn.value : this.meanNn,
      pnn50: data.pnn50.present ? data.pnn50.value : this.pnn50,
      hrReadingsJson:
          data.hrReadingsJson.present
              ? data.hrReadingsJson.value
              : this.hrReadingsJson,
      extendedMetricsJson:
          data.extendedMetricsJson.present
              ? data.extendedMetricsJson.value
              : this.extendedMetricsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSummary(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('breathRate: $breathRate, ')
          ..write('breathSource: $breathSource, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('minHeartRate: $minHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('rmssd: $rmssd, ')
          ..write('sdnn: $sdnn, ')
          ..write('meanNn: $meanNn, ')
          ..write('pnn50: $pnn50, ')
          ..write('hrReadingsJson: $hrReadingsJson, ')
          ..write('extendedMetricsJson: $extendedMetricsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    sessionType,
    startedAt,
    endedAt,
    durationSeconds,
    breathRate,
    breathSource,
    avgHeartRate,
    minHeartRate,
    maxHeartRate,
    rmssd,
    sdnn,
    meanNn,
    pnn50,
    hrReadingsJson,
    extendedMetricsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSummary &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.sessionType == this.sessionType &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.breathRate == this.breathRate &&
          other.breathSource == this.breathSource &&
          other.avgHeartRate == this.avgHeartRate &&
          other.minHeartRate == this.minHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.rmssd == this.rmssd &&
          other.sdnn == this.sdnn &&
          other.meanNn == this.meanNn &&
          other.pnn50 == this.pnn50 &&
          other.hrReadingsJson == this.hrReadingsJson &&
          other.extendedMetricsJson == this.extendedMetricsJson);
}

class SessionSummariesCompanion extends UpdateCompanion<SessionSummary> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<String> sessionType;
  final Value<String> startedAt;
  final Value<String?> endedAt;
  final Value<int> durationSeconds;
  final Value<int?> breathRate;
  final Value<String?> breathSource;
  final Value<double?> avgHeartRate;
  final Value<int?> minHeartRate;
  final Value<int?> maxHeartRate;
  final Value<double?> rmssd;
  final Value<double?> sdnn;
  final Value<double?> meanNn;
  final Value<double?> pnn50;
  final Value<String?> hrReadingsJson;
  final Value<String?> extendedMetricsJson;
  const SessionSummariesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.breathRate = const Value.absent(),
    this.breathSource = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.minHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.sdnn = const Value.absent(),
    this.meanNn = const Value.absent(),
    this.pnn50 = const Value.absent(),
    this.hrReadingsJson = const Value.absent(),
    this.extendedMetricsJson = const Value.absent(),
  });
  SessionSummariesCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    this.sessionType = const Value.absent(),
    required String startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.breathRate = const Value.absent(),
    this.breathSource = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.minHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.sdnn = const Value.absent(),
    this.meanNn = const Value.absent(),
    this.pnn50 = const Value.absent(),
    this.hrReadingsJson = const Value.absent(),
    this.extendedMetricsJson = const Value.absent(),
  }) : patientId = Value(patientId),
       startedAt = Value(startedAt);
  static Insertable<SessionSummary> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<String>? sessionType,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<int>? durationSeconds,
    Expression<int>? breathRate,
    Expression<String>? breathSource,
    Expression<double>? avgHeartRate,
    Expression<int>? minHeartRate,
    Expression<int>? maxHeartRate,
    Expression<double>? rmssd,
    Expression<double>? sdnn,
    Expression<double>? meanNn,
    Expression<double>? pnn50,
    Expression<String>? hrReadingsJson,
    Expression<String>? extendedMetricsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (sessionType != null) 'session_type': sessionType,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (breathRate != null) 'breath_rate': breathRate,
      if (breathSource != null) 'breath_source': breathSource,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (minHeartRate != null) 'min_heart_rate': minHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (rmssd != null) 'rmssd': rmssd,
      if (sdnn != null) 'sdnn': sdnn,
      if (meanNn != null) 'mean_nn': meanNn,
      if (pnn50 != null) 'pnn50': pnn50,
      if (hrReadingsJson != null) 'hr_readings_json': hrReadingsJson,
      if (extendedMetricsJson != null)
        'extended_metrics_json': extendedMetricsJson,
    });
  }

  SessionSummariesCompanion copyWith({
    Value<int>? id,
    Value<int>? patientId,
    Value<String>? sessionType,
    Value<String>? startedAt,
    Value<String?>? endedAt,
    Value<int>? durationSeconds,
    Value<int?>? breathRate,
    Value<String?>? breathSource,
    Value<double?>? avgHeartRate,
    Value<int?>? minHeartRate,
    Value<int?>? maxHeartRate,
    Value<double?>? rmssd,
    Value<double?>? sdnn,
    Value<double?>? meanNn,
    Value<double?>? pnn50,
    Value<String?>? hrReadingsJson,
    Value<String?>? extendedMetricsJson,
  }) {
    return SessionSummariesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      sessionType: sessionType ?? this.sessionType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      breathRate: breathRate ?? this.breathRate,
      breathSource: breathSource ?? this.breathSource,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      rmssd: rmssd ?? this.rmssd,
      sdnn: sdnn ?? this.sdnn,
      meanNn: meanNn ?? this.meanNn,
      pnn50: pnn50 ?? this.pnn50,
      hrReadingsJson: hrReadingsJson ?? this.hrReadingsJson,
      extendedMetricsJson: extendedMetricsJson ?? this.extendedMetricsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (breathRate.present) {
      map['breath_rate'] = Variable<int>(breathRate.value);
    }
    if (breathSource.present) {
      map['breath_source'] = Variable<String>(breathSource.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate.value);
    }
    if (minHeartRate.present) {
      map['min_heart_rate'] = Variable<int>(minHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate.value);
    }
    if (rmssd.present) {
      map['rmssd'] = Variable<double>(rmssd.value);
    }
    if (sdnn.present) {
      map['sdnn'] = Variable<double>(sdnn.value);
    }
    if (meanNn.present) {
      map['mean_nn'] = Variable<double>(meanNn.value);
    }
    if (pnn50.present) {
      map['pnn50'] = Variable<double>(pnn50.value);
    }
    if (hrReadingsJson.present) {
      map['hr_readings_json'] = Variable<String>(hrReadingsJson.value);
    }
    if (extendedMetricsJson.present) {
      map['extended_metrics_json'] = Variable<String>(
        extendedMetricsJson.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSummariesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('breathRate: $breathRate, ')
          ..write('breathSource: $breathSource, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('minHeartRate: $minHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('rmssd: $rmssd, ')
          ..write('sdnn: $sdnn, ')
          ..write('meanNn: $meanNn, ')
          ..write('pnn50: $pnn50, ')
          ..write('hrReadingsJson: $hrReadingsJson, ')
          ..write('extendedMetricsJson: $extendedMetricsJson')
          ..write(')'))
        .toString();
  }
}

class $RfAssessmentRecordsTable extends RfAssessmentRecords
    with TableInfo<$RfAssessmentRecordsTable, RfAssessmentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RfAssessmentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES patients (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sessionSummaryIdMeta = const VerificationMeta(
    'sessionSummaryId',
  );
  @override
  late final GeneratedColumn<int> sessionSummaryId = GeneratedColumn<int>(
    'session_summary_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES session_summaries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _surfaceMeta = const VerificationMeta(
    'surface',
  );
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
    'surface',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<String> protocolVersion = GeneratedColumn<String>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<String> endedAt = GeneratedColumn<String>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<double> durationMs = GeneratedColumn<double>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedCyclesMeta = const VerificationMeta(
    'completedCycles',
  );
  @override
  late final GeneratedColumn<int> completedCycles = GeneratedColumn<int>(
    'completed_cycles',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rfBpmMeta = const VerificationMeta('rfBpm');
  @override
  late final GeneratedColumn<double> rfBpm = GeneratedColumn<double>(
    'rf_bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rfCenterElapsedMsMeta = const VerificationMeta(
    'rfCenterElapsedMs',
  );
  @override
  late final GeneratedColumn<double> rfCenterElapsedMs =
      GeneratedColumn<double>(
        'rf_center_elapsed_ms',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _peakToTroughAmplitudeMeta =
      const VerificationMeta('peakToTroughAmplitude');
  @override
  late final GeneratedColumn<double> peakToTroughAmplitude =
      GeneratedColumn<double>(
        'peak_to_trough_amplitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledBpmAtCenterMeta =
      const VerificationMeta('scheduledBpmAtCenter');
  @override
  late final GeneratedColumn<double> scheduledBpmAtCenter =
      GeneratedColumn<double>(
        'scheduled_bpm_at_center',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fittedRespirationBpmMeta =
      const VerificationMeta('fittedRespirationBpm');
  @override
  late final GeneratedColumn<double> fittedRespirationBpm =
      GeneratedColumn<double>(
        'fitted_respiration_bpm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _adherenceDeltaBpmMeta = const VerificationMeta(
    'adherenceDeltaBpm',
  );
  @override
  late final GeneratedColumn<double> adherenceDeltaBpm =
      GeneratedColumn<double>(
        'adherence_delta_bpm',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _respirationFitErrorMeta =
      const VerificationMeta('respirationFitError');
  @override
  late final GeneratedColumn<double> respirationFitError =
      GeneratedColumn<double>(
        'respiration_fit_error',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ectopicCorrectionsMeta =
      const VerificationMeta('ectopicCorrections');
  @override
  late final GeneratedColumn<int> ectopicCorrections = GeneratedColumn<int>(
    'ectopic_corrections',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityPassedMeta = const VerificationMeta(
    'qualityPassed',
  );
  @override
  late final GeneratedColumn<bool> qualityPassed = GeneratedColumn<bool>(
    'quality_passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quality_passed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _qualityFlagsJsonMeta = const VerificationMeta(
    'qualityFlagsJson',
  );
  @override
  late final GeneratedColumn<String> qualityFlagsJson = GeneratedColumn<String>(
    'quality_flags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedToPatientMeta = const VerificationMeta(
    'appliedToPatient',
  );
  @override
  late final GeneratedColumn<bool> appliedToPatient = GeneratedColumn<bool>(
    'applied_to_patient',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("applied_to_patient" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _estimateConfirmedMeta = const VerificationMeta(
    'estimateConfirmed',
  );
  @override
  late final GeneratedColumn<bool> estimateConfirmed = GeneratedColumn<bool>(
    'estimate_confirmed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("estimate_confirmed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _protocolJsonMeta = const VerificationMeta(
    'protocolJson',
  );
  @override
  late final GeneratedColumn<String> protocolJson = GeneratedColumn<String>(
    'protocol_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rrSamplesJsonMeta = const VerificationMeta(
    'rrSamplesJson',
  );
  @override
  late final GeneratedColumn<String> rrSamplesJson = GeneratedColumn<String>(
    'rr_samples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _respirationSamplesJsonMeta =
      const VerificationMeta('respirationSamplesJson');
  @override
  late final GeneratedColumn<String> respirationSamplesJson =
      GeneratedColumn<String>(
        'respiration_samples_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    sessionSummaryId,
    surface,
    protocolVersion,
    mode,
    status,
    startedAt,
    endedAt,
    durationMs,
    completedCycles,
    rfBpm,
    rfCenterElapsedMs,
    peakToTroughAmplitude,
    scheduledBpmAtCenter,
    fittedRespirationBpm,
    adherenceDeltaBpm,
    respirationFitError,
    ectopicCorrections,
    qualityPassed,
    qualityFlagsJson,
    appliedToPatient,
    estimateConfirmed,
    protocolJson,
    resultJson,
    rrSamplesJson,
    respirationSamplesJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rf_assessment_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RfAssessmentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('session_summary_id')) {
      context.handle(
        _sessionSummaryIdMeta,
        sessionSummaryId.isAcceptableOrUnknown(
          data['session_summary_id']!,
          _sessionSummaryIdMeta,
        ),
      );
    }
    if (data.containsKey('surface')) {
      context.handle(
        _surfaceMeta,
        surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta),
      );
    } else if (isInserting) {
      context.missing(_surfaceMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('completed_cycles')) {
      context.handle(
        _completedCyclesMeta,
        completedCycles.isAcceptableOrUnknown(
          data['completed_cycles']!,
          _completedCyclesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedCyclesMeta);
    }
    if (data.containsKey('rf_bpm')) {
      context.handle(
        _rfBpmMeta,
        rfBpm.isAcceptableOrUnknown(data['rf_bpm']!, _rfBpmMeta),
      );
    }
    if (data.containsKey('rf_center_elapsed_ms')) {
      context.handle(
        _rfCenterElapsedMsMeta,
        rfCenterElapsedMs.isAcceptableOrUnknown(
          data['rf_center_elapsed_ms']!,
          _rfCenterElapsedMsMeta,
        ),
      );
    }
    if (data.containsKey('peak_to_trough_amplitude')) {
      context.handle(
        _peakToTroughAmplitudeMeta,
        peakToTroughAmplitude.isAcceptableOrUnknown(
          data['peak_to_trough_amplitude']!,
          _peakToTroughAmplitudeMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_bpm_at_center')) {
      context.handle(
        _scheduledBpmAtCenterMeta,
        scheduledBpmAtCenter.isAcceptableOrUnknown(
          data['scheduled_bpm_at_center']!,
          _scheduledBpmAtCenterMeta,
        ),
      );
    }
    if (data.containsKey('fitted_respiration_bpm')) {
      context.handle(
        _fittedRespirationBpmMeta,
        fittedRespirationBpm.isAcceptableOrUnknown(
          data['fitted_respiration_bpm']!,
          _fittedRespirationBpmMeta,
        ),
      );
    }
    if (data.containsKey('adherence_delta_bpm')) {
      context.handle(
        _adherenceDeltaBpmMeta,
        adherenceDeltaBpm.isAcceptableOrUnknown(
          data['adherence_delta_bpm']!,
          _adherenceDeltaBpmMeta,
        ),
      );
    }
    if (data.containsKey('respiration_fit_error')) {
      context.handle(
        _respirationFitErrorMeta,
        respirationFitError.isAcceptableOrUnknown(
          data['respiration_fit_error']!,
          _respirationFitErrorMeta,
        ),
      );
    }
    if (data.containsKey('ectopic_corrections')) {
      context.handle(
        _ectopicCorrectionsMeta,
        ectopicCorrections.isAcceptableOrUnknown(
          data['ectopic_corrections']!,
          _ectopicCorrectionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ectopicCorrectionsMeta);
    }
    if (data.containsKey('quality_passed')) {
      context.handle(
        _qualityPassedMeta,
        qualityPassed.isAcceptableOrUnknown(
          data['quality_passed']!,
          _qualityPassedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityPassedMeta);
    }
    if (data.containsKey('quality_flags_json')) {
      context.handle(
        _qualityFlagsJsonMeta,
        qualityFlagsJson.isAcceptableOrUnknown(
          data['quality_flags_json']!,
          _qualityFlagsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityFlagsJsonMeta);
    }
    if (data.containsKey('applied_to_patient')) {
      context.handle(
        _appliedToPatientMeta,
        appliedToPatient.isAcceptableOrUnknown(
          data['applied_to_patient']!,
          _appliedToPatientMeta,
        ),
      );
    }
    if (data.containsKey('estimate_confirmed')) {
      context.handle(
        _estimateConfirmedMeta,
        estimateConfirmed.isAcceptableOrUnknown(
          data['estimate_confirmed']!,
          _estimateConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('protocol_json')) {
      context.handle(
        _protocolJsonMeta,
        protocolJson.isAcceptableOrUnknown(
          data['protocol_json']!,
          _protocolJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolJsonMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('rr_samples_json')) {
      context.handle(
        _rrSamplesJsonMeta,
        rrSamplesJson.isAcceptableOrUnknown(
          data['rr_samples_json']!,
          _rrSamplesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rrSamplesJsonMeta);
    }
    if (data.containsKey('respiration_samples_json')) {
      context.handle(
        _respirationSamplesJsonMeta,
        respirationSamplesJson.isAcceptableOrUnknown(
          data['respiration_samples_json']!,
          _respirationSamplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RfAssessmentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RfAssessmentRecord(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      patientId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}patient_id'],
          )!,
      sessionSummaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_summary_id'],
      ),
      surface:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}surface'],
          )!,
      protocolVersion:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}protocol_version'],
          )!,
      mode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mode'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      startedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}started_at'],
          )!,
      endedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}ended_at'],
          )!,
      durationMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}duration_ms'],
          )!,
      completedCycles:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}completed_cycles'],
          )!,
      rfBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rf_bpm'],
      ),
      rfCenterElapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rf_center_elapsed_ms'],
      ),
      peakToTroughAmplitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_to_trough_amplitude'],
      ),
      scheduledBpmAtCenter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scheduled_bpm_at_center'],
      ),
      fittedRespirationBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fitted_respiration_bpm'],
      ),
      adherenceDeltaBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adherence_delta_bpm'],
      ),
      respirationFitError: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}respiration_fit_error'],
      ),
      ectopicCorrections:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}ectopic_corrections'],
          )!,
      qualityPassed:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}quality_passed'],
          )!,
      qualityFlagsJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}quality_flags_json'],
          )!,
      appliedToPatient:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}applied_to_patient'],
          )!,
      estimateConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}estimate_confirmed'],
      ),
      protocolJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}protocol_json'],
          )!,
      resultJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}result_json'],
          )!,
      rrSamplesJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}rr_samples_json'],
          )!,
      respirationSamplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}respiration_samples_json'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $RfAssessmentRecordsTable createAlias(String alias) {
    return $RfAssessmentRecordsTable(attachedDatabase, alias);
  }
}

class RfAssessmentRecord extends DataClass
    implements Insertable<RfAssessmentRecord> {
  final int id;
  final int patientId;
  final int? sessionSummaryId;
  final String surface;
  final String protocolVersion;
  final String mode;
  final String status;
  final String startedAt;
  final String endedAt;
  final double durationMs;
  final int completedCycles;
  final double? rfBpm;
  final double? rfCenterElapsedMs;
  final double? peakToTroughAmplitude;
  final double? scheduledBpmAtCenter;
  final double? fittedRespirationBpm;
  final double? adherenceDeltaBpm;
  final double? respirationFitError;
  final int ectopicCorrections;
  final bool qualityPassed;
  final String qualityFlagsJson;
  final bool appliedToPatient;
  final bool? estimateConfirmed;
  final String protocolJson;
  final String resultJson;
  final String rrSamplesJson;
  final String? respirationSamplesJson;
  final String createdAt;
  const RfAssessmentRecord({
    required this.id,
    required this.patientId,
    this.sessionSummaryId,
    required this.surface,
    required this.protocolVersion,
    required this.mode,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.completedCycles,
    this.rfBpm,
    this.rfCenterElapsedMs,
    this.peakToTroughAmplitude,
    this.scheduledBpmAtCenter,
    this.fittedRespirationBpm,
    this.adherenceDeltaBpm,
    this.respirationFitError,
    required this.ectopicCorrections,
    required this.qualityPassed,
    required this.qualityFlagsJson,
    required this.appliedToPatient,
    this.estimateConfirmed,
    required this.protocolJson,
    required this.resultJson,
    required this.rrSamplesJson,
    this.respirationSamplesJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    if (!nullToAbsent || sessionSummaryId != null) {
      map['session_summary_id'] = Variable<int>(sessionSummaryId);
    }
    map['surface'] = Variable<String>(surface);
    map['protocol_version'] = Variable<String>(protocolVersion);
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<String>(startedAt);
    map['ended_at'] = Variable<String>(endedAt);
    map['duration_ms'] = Variable<double>(durationMs);
    map['completed_cycles'] = Variable<int>(completedCycles);
    if (!nullToAbsent || rfBpm != null) {
      map['rf_bpm'] = Variable<double>(rfBpm);
    }
    if (!nullToAbsent || rfCenterElapsedMs != null) {
      map['rf_center_elapsed_ms'] = Variable<double>(rfCenterElapsedMs);
    }
    if (!nullToAbsent || peakToTroughAmplitude != null) {
      map['peak_to_trough_amplitude'] = Variable<double>(peakToTroughAmplitude);
    }
    if (!nullToAbsent || scheduledBpmAtCenter != null) {
      map['scheduled_bpm_at_center'] = Variable<double>(scheduledBpmAtCenter);
    }
    if (!nullToAbsent || fittedRespirationBpm != null) {
      map['fitted_respiration_bpm'] = Variable<double>(fittedRespirationBpm);
    }
    if (!nullToAbsent || adherenceDeltaBpm != null) {
      map['adherence_delta_bpm'] = Variable<double>(adherenceDeltaBpm);
    }
    if (!nullToAbsent || respirationFitError != null) {
      map['respiration_fit_error'] = Variable<double>(respirationFitError);
    }
    map['ectopic_corrections'] = Variable<int>(ectopicCorrections);
    map['quality_passed'] = Variable<bool>(qualityPassed);
    map['quality_flags_json'] = Variable<String>(qualityFlagsJson);
    map['applied_to_patient'] = Variable<bool>(appliedToPatient);
    if (!nullToAbsent || estimateConfirmed != null) {
      map['estimate_confirmed'] = Variable<bool>(estimateConfirmed);
    }
    map['protocol_json'] = Variable<String>(protocolJson);
    map['result_json'] = Variable<String>(resultJson);
    map['rr_samples_json'] = Variable<String>(rrSamplesJson);
    if (!nullToAbsent || respirationSamplesJson != null) {
      map['respiration_samples_json'] = Variable<String>(
        respirationSamplesJson,
      );
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  RfAssessmentRecordsCompanion toCompanion(bool nullToAbsent) {
    return RfAssessmentRecordsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      sessionSummaryId:
          sessionSummaryId == null && nullToAbsent
              ? const Value.absent()
              : Value(sessionSummaryId),
      surface: Value(surface),
      protocolVersion: Value(protocolVersion),
      mode: Value(mode),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      durationMs: Value(durationMs),
      completedCycles: Value(completedCycles),
      rfBpm:
          rfBpm == null && nullToAbsent ? const Value.absent() : Value(rfBpm),
      rfCenterElapsedMs:
          rfCenterElapsedMs == null && nullToAbsent
              ? const Value.absent()
              : Value(rfCenterElapsedMs),
      peakToTroughAmplitude:
          peakToTroughAmplitude == null && nullToAbsent
              ? const Value.absent()
              : Value(peakToTroughAmplitude),
      scheduledBpmAtCenter:
          scheduledBpmAtCenter == null && nullToAbsent
              ? const Value.absent()
              : Value(scheduledBpmAtCenter),
      fittedRespirationBpm:
          fittedRespirationBpm == null && nullToAbsent
              ? const Value.absent()
              : Value(fittedRespirationBpm),
      adherenceDeltaBpm:
          adherenceDeltaBpm == null && nullToAbsent
              ? const Value.absent()
              : Value(adherenceDeltaBpm),
      respirationFitError:
          respirationFitError == null && nullToAbsent
              ? const Value.absent()
              : Value(respirationFitError),
      ectopicCorrections: Value(ectopicCorrections),
      qualityPassed: Value(qualityPassed),
      qualityFlagsJson: Value(qualityFlagsJson),
      appliedToPatient: Value(appliedToPatient),
      estimateConfirmed:
          estimateConfirmed == null && nullToAbsent
              ? const Value.absent()
              : Value(estimateConfirmed),
      protocolJson: Value(protocolJson),
      resultJson: Value(resultJson),
      rrSamplesJson: Value(rrSamplesJson),
      respirationSamplesJson:
          respirationSamplesJson == null && nullToAbsent
              ? const Value.absent()
              : Value(respirationSamplesJson),
      createdAt: Value(createdAt),
    );
  }

  factory RfAssessmentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RfAssessmentRecord(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      sessionSummaryId: serializer.fromJson<int?>(json['sessionSummaryId']),
      surface: serializer.fromJson<String>(json['surface']),
      protocolVersion: serializer.fromJson<String>(json['protocolVersion']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      endedAt: serializer.fromJson<String>(json['endedAt']),
      durationMs: serializer.fromJson<double>(json['durationMs']),
      completedCycles: serializer.fromJson<int>(json['completedCycles']),
      rfBpm: serializer.fromJson<double?>(json['rfBpm']),
      rfCenterElapsedMs: serializer.fromJson<double?>(
        json['rfCenterElapsedMs'],
      ),
      peakToTroughAmplitude: serializer.fromJson<double?>(
        json['peakToTroughAmplitude'],
      ),
      scheduledBpmAtCenter: serializer.fromJson<double?>(
        json['scheduledBpmAtCenter'],
      ),
      fittedRespirationBpm: serializer.fromJson<double?>(
        json['fittedRespirationBpm'],
      ),
      adherenceDeltaBpm: serializer.fromJson<double?>(
        json['adherenceDeltaBpm'],
      ),
      respirationFitError: serializer.fromJson<double?>(
        json['respirationFitError'],
      ),
      ectopicCorrections: serializer.fromJson<int>(json['ectopicCorrections']),
      qualityPassed: serializer.fromJson<bool>(json['qualityPassed']),
      qualityFlagsJson: serializer.fromJson<String>(json['qualityFlagsJson']),
      appliedToPatient: serializer.fromJson<bool>(json['appliedToPatient']),
      estimateConfirmed: serializer.fromJson<bool?>(json['estimateConfirmed']),
      protocolJson: serializer.fromJson<String>(json['protocolJson']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      rrSamplesJson: serializer.fromJson<String>(json['rrSamplesJson']),
      respirationSamplesJson: serializer.fromJson<String?>(
        json['respirationSamplesJson'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'sessionSummaryId': serializer.toJson<int?>(sessionSummaryId),
      'surface': serializer.toJson<String>(surface),
      'protocolVersion': serializer.toJson<String>(protocolVersion),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<String>(startedAt),
      'endedAt': serializer.toJson<String>(endedAt),
      'durationMs': serializer.toJson<double>(durationMs),
      'completedCycles': serializer.toJson<int>(completedCycles),
      'rfBpm': serializer.toJson<double?>(rfBpm),
      'rfCenterElapsedMs': serializer.toJson<double?>(rfCenterElapsedMs),
      'peakToTroughAmplitude': serializer.toJson<double?>(
        peakToTroughAmplitude,
      ),
      'scheduledBpmAtCenter': serializer.toJson<double?>(scheduledBpmAtCenter),
      'fittedRespirationBpm': serializer.toJson<double?>(fittedRespirationBpm),
      'adherenceDeltaBpm': serializer.toJson<double?>(adherenceDeltaBpm),
      'respirationFitError': serializer.toJson<double?>(respirationFitError),
      'ectopicCorrections': serializer.toJson<int>(ectopicCorrections),
      'qualityPassed': serializer.toJson<bool>(qualityPassed),
      'qualityFlagsJson': serializer.toJson<String>(qualityFlagsJson),
      'appliedToPatient': serializer.toJson<bool>(appliedToPatient),
      'estimateConfirmed': serializer.toJson<bool?>(estimateConfirmed),
      'protocolJson': serializer.toJson<String>(protocolJson),
      'resultJson': serializer.toJson<String>(resultJson),
      'rrSamplesJson': serializer.toJson<String>(rrSamplesJson),
      'respirationSamplesJson': serializer.toJson<String?>(
        respirationSamplesJson,
      ),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  RfAssessmentRecord copyWith({
    int? id,
    int? patientId,
    Value<int?> sessionSummaryId = const Value.absent(),
    String? surface,
    String? protocolVersion,
    String? mode,
    String? status,
    String? startedAt,
    String? endedAt,
    double? durationMs,
    int? completedCycles,
    Value<double?> rfBpm = const Value.absent(),
    Value<double?> rfCenterElapsedMs = const Value.absent(),
    Value<double?> peakToTroughAmplitude = const Value.absent(),
    Value<double?> scheduledBpmAtCenter = const Value.absent(),
    Value<double?> fittedRespirationBpm = const Value.absent(),
    Value<double?> adherenceDeltaBpm = const Value.absent(),
    Value<double?> respirationFitError = const Value.absent(),
    int? ectopicCorrections,
    bool? qualityPassed,
    String? qualityFlagsJson,
    bool? appliedToPatient,
    Value<bool?> estimateConfirmed = const Value.absent(),
    String? protocolJson,
    String? resultJson,
    String? rrSamplesJson,
    Value<String?> respirationSamplesJson = const Value.absent(),
    String? createdAt,
  }) => RfAssessmentRecord(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    sessionSummaryId:
        sessionSummaryId.present
            ? sessionSummaryId.value
            : this.sessionSummaryId,
    surface: surface ?? this.surface,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationMs: durationMs ?? this.durationMs,
    completedCycles: completedCycles ?? this.completedCycles,
    rfBpm: rfBpm.present ? rfBpm.value : this.rfBpm,
    rfCenterElapsedMs:
        rfCenterElapsedMs.present
            ? rfCenterElapsedMs.value
            : this.rfCenterElapsedMs,
    peakToTroughAmplitude:
        peakToTroughAmplitude.present
            ? peakToTroughAmplitude.value
            : this.peakToTroughAmplitude,
    scheduledBpmAtCenter:
        scheduledBpmAtCenter.present
            ? scheduledBpmAtCenter.value
            : this.scheduledBpmAtCenter,
    fittedRespirationBpm:
        fittedRespirationBpm.present
            ? fittedRespirationBpm.value
            : this.fittedRespirationBpm,
    adherenceDeltaBpm:
        adherenceDeltaBpm.present
            ? adherenceDeltaBpm.value
            : this.adherenceDeltaBpm,
    respirationFitError:
        respirationFitError.present
            ? respirationFitError.value
            : this.respirationFitError,
    ectopicCorrections: ectopicCorrections ?? this.ectopicCorrections,
    qualityPassed: qualityPassed ?? this.qualityPassed,
    qualityFlagsJson: qualityFlagsJson ?? this.qualityFlagsJson,
    appliedToPatient: appliedToPatient ?? this.appliedToPatient,
    estimateConfirmed:
        estimateConfirmed.present
            ? estimateConfirmed.value
            : this.estimateConfirmed,
    protocolJson: protocolJson ?? this.protocolJson,
    resultJson: resultJson ?? this.resultJson,
    rrSamplesJson: rrSamplesJson ?? this.rrSamplesJson,
    respirationSamplesJson:
        respirationSamplesJson.present
            ? respirationSamplesJson.value
            : this.respirationSamplesJson,
    createdAt: createdAt ?? this.createdAt,
  );
  RfAssessmentRecord copyWithCompanion(RfAssessmentRecordsCompanion data) {
    return RfAssessmentRecord(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      sessionSummaryId:
          data.sessionSummaryId.present
              ? data.sessionSummaryId.value
              : this.sessionSummaryId,
      surface: data.surface.present ? data.surface.value : this.surface,
      protocolVersion:
          data.protocolVersion.present
              ? data.protocolVersion.value
              : this.protocolVersion,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      completedCycles:
          data.completedCycles.present
              ? data.completedCycles.value
              : this.completedCycles,
      rfBpm: data.rfBpm.present ? data.rfBpm.value : this.rfBpm,
      rfCenterElapsedMs:
          data.rfCenterElapsedMs.present
              ? data.rfCenterElapsedMs.value
              : this.rfCenterElapsedMs,
      peakToTroughAmplitude:
          data.peakToTroughAmplitude.present
              ? data.peakToTroughAmplitude.value
              : this.peakToTroughAmplitude,
      scheduledBpmAtCenter:
          data.scheduledBpmAtCenter.present
              ? data.scheduledBpmAtCenter.value
              : this.scheduledBpmAtCenter,
      fittedRespirationBpm:
          data.fittedRespirationBpm.present
              ? data.fittedRespirationBpm.value
              : this.fittedRespirationBpm,
      adherenceDeltaBpm:
          data.adherenceDeltaBpm.present
              ? data.adherenceDeltaBpm.value
              : this.adherenceDeltaBpm,
      respirationFitError:
          data.respirationFitError.present
              ? data.respirationFitError.value
              : this.respirationFitError,
      ectopicCorrections:
          data.ectopicCorrections.present
              ? data.ectopicCorrections.value
              : this.ectopicCorrections,
      qualityPassed:
          data.qualityPassed.present
              ? data.qualityPassed.value
              : this.qualityPassed,
      qualityFlagsJson:
          data.qualityFlagsJson.present
              ? data.qualityFlagsJson.value
              : this.qualityFlagsJson,
      appliedToPatient:
          data.appliedToPatient.present
              ? data.appliedToPatient.value
              : this.appliedToPatient,
      estimateConfirmed:
          data.estimateConfirmed.present
              ? data.estimateConfirmed.value
              : this.estimateConfirmed,
      protocolJson:
          data.protocolJson.present
              ? data.protocolJson.value
              : this.protocolJson,
      resultJson:
          data.resultJson.present ? data.resultJson.value : this.resultJson,
      rrSamplesJson:
          data.rrSamplesJson.present
              ? data.rrSamplesJson.value
              : this.rrSamplesJson,
      respirationSamplesJson:
          data.respirationSamplesJson.present
              ? data.respirationSamplesJson.value
              : this.respirationSamplesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RfAssessmentRecord(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionSummaryId: $sessionSummaryId, ')
          ..write('surface: $surface, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('completedCycles: $completedCycles, ')
          ..write('rfBpm: $rfBpm, ')
          ..write('rfCenterElapsedMs: $rfCenterElapsedMs, ')
          ..write('peakToTroughAmplitude: $peakToTroughAmplitude, ')
          ..write('scheduledBpmAtCenter: $scheduledBpmAtCenter, ')
          ..write('fittedRespirationBpm: $fittedRespirationBpm, ')
          ..write('adherenceDeltaBpm: $adherenceDeltaBpm, ')
          ..write('respirationFitError: $respirationFitError, ')
          ..write('ectopicCorrections: $ectopicCorrections, ')
          ..write('qualityPassed: $qualityPassed, ')
          ..write('qualityFlagsJson: $qualityFlagsJson, ')
          ..write('appliedToPatient: $appliedToPatient, ')
          ..write('estimateConfirmed: $estimateConfirmed, ')
          ..write('protocolJson: $protocolJson, ')
          ..write('resultJson: $resultJson, ')
          ..write('rrSamplesJson: $rrSamplesJson, ')
          ..write('respirationSamplesJson: $respirationSamplesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    patientId,
    sessionSummaryId,
    surface,
    protocolVersion,
    mode,
    status,
    startedAt,
    endedAt,
    durationMs,
    completedCycles,
    rfBpm,
    rfCenterElapsedMs,
    peakToTroughAmplitude,
    scheduledBpmAtCenter,
    fittedRespirationBpm,
    adherenceDeltaBpm,
    respirationFitError,
    ectopicCorrections,
    qualityPassed,
    qualityFlagsJson,
    appliedToPatient,
    estimateConfirmed,
    protocolJson,
    resultJson,
    rrSamplesJson,
    respirationSamplesJson,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RfAssessmentRecord &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.sessionSummaryId == this.sessionSummaryId &&
          other.surface == this.surface &&
          other.protocolVersion == this.protocolVersion &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationMs == this.durationMs &&
          other.completedCycles == this.completedCycles &&
          other.rfBpm == this.rfBpm &&
          other.rfCenterElapsedMs == this.rfCenterElapsedMs &&
          other.peakToTroughAmplitude == this.peakToTroughAmplitude &&
          other.scheduledBpmAtCenter == this.scheduledBpmAtCenter &&
          other.fittedRespirationBpm == this.fittedRespirationBpm &&
          other.adherenceDeltaBpm == this.adherenceDeltaBpm &&
          other.respirationFitError == this.respirationFitError &&
          other.ectopicCorrections == this.ectopicCorrections &&
          other.qualityPassed == this.qualityPassed &&
          other.qualityFlagsJson == this.qualityFlagsJson &&
          other.appliedToPatient == this.appliedToPatient &&
          other.estimateConfirmed == this.estimateConfirmed &&
          other.protocolJson == this.protocolJson &&
          other.resultJson == this.resultJson &&
          other.rrSamplesJson == this.rrSamplesJson &&
          other.respirationSamplesJson == this.respirationSamplesJson &&
          other.createdAt == this.createdAt);
}

class RfAssessmentRecordsCompanion extends UpdateCompanion<RfAssessmentRecord> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<int?> sessionSummaryId;
  final Value<String> surface;
  final Value<String> protocolVersion;
  final Value<String> mode;
  final Value<String> status;
  final Value<String> startedAt;
  final Value<String> endedAt;
  final Value<double> durationMs;
  final Value<int> completedCycles;
  final Value<double?> rfBpm;
  final Value<double?> rfCenterElapsedMs;
  final Value<double?> peakToTroughAmplitude;
  final Value<double?> scheduledBpmAtCenter;
  final Value<double?> fittedRespirationBpm;
  final Value<double?> adherenceDeltaBpm;
  final Value<double?> respirationFitError;
  final Value<int> ectopicCorrections;
  final Value<bool> qualityPassed;
  final Value<String> qualityFlagsJson;
  final Value<bool> appliedToPatient;
  final Value<bool?> estimateConfirmed;
  final Value<String> protocolJson;
  final Value<String> resultJson;
  final Value<String> rrSamplesJson;
  final Value<String?> respirationSamplesJson;
  final Value<String> createdAt;
  const RfAssessmentRecordsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.sessionSummaryId = const Value.absent(),
    this.surface = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.completedCycles = const Value.absent(),
    this.rfBpm = const Value.absent(),
    this.rfCenterElapsedMs = const Value.absent(),
    this.peakToTroughAmplitude = const Value.absent(),
    this.scheduledBpmAtCenter = const Value.absent(),
    this.fittedRespirationBpm = const Value.absent(),
    this.adherenceDeltaBpm = const Value.absent(),
    this.respirationFitError = const Value.absent(),
    this.ectopicCorrections = const Value.absent(),
    this.qualityPassed = const Value.absent(),
    this.qualityFlagsJson = const Value.absent(),
    this.appliedToPatient = const Value.absent(),
    this.estimateConfirmed = const Value.absent(),
    this.protocolJson = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.rrSamplesJson = const Value.absent(),
    this.respirationSamplesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RfAssessmentRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    this.sessionSummaryId = const Value.absent(),
    required String surface,
    required String protocolVersion,
    required String mode,
    required String status,
    required String startedAt,
    required String endedAt,
    required double durationMs,
    required int completedCycles,
    this.rfBpm = const Value.absent(),
    this.rfCenterElapsedMs = const Value.absent(),
    this.peakToTroughAmplitude = const Value.absent(),
    this.scheduledBpmAtCenter = const Value.absent(),
    this.fittedRespirationBpm = const Value.absent(),
    this.adherenceDeltaBpm = const Value.absent(),
    this.respirationFitError = const Value.absent(),
    required int ectopicCorrections,
    required bool qualityPassed,
    required String qualityFlagsJson,
    this.appliedToPatient = const Value.absent(),
    this.estimateConfirmed = const Value.absent(),
    required String protocolJson,
    required String resultJson,
    required String rrSamplesJson,
    this.respirationSamplesJson = const Value.absent(),
    required String createdAt,
  }) : patientId = Value(patientId),
       surface = Value(surface),
       protocolVersion = Value(protocolVersion),
       mode = Value(mode),
       status = Value(status),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       durationMs = Value(durationMs),
       completedCycles = Value(completedCycles),
       ectopicCorrections = Value(ectopicCorrections),
       qualityPassed = Value(qualityPassed),
       qualityFlagsJson = Value(qualityFlagsJson),
       protocolJson = Value(protocolJson),
       resultJson = Value(resultJson),
       rrSamplesJson = Value(rrSamplesJson),
       createdAt = Value(createdAt);
  static Insertable<RfAssessmentRecord> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<int>? sessionSummaryId,
    Expression<String>? surface,
    Expression<String>? protocolVersion,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<double>? durationMs,
    Expression<int>? completedCycles,
    Expression<double>? rfBpm,
    Expression<double>? rfCenterElapsedMs,
    Expression<double>? peakToTroughAmplitude,
    Expression<double>? scheduledBpmAtCenter,
    Expression<double>? fittedRespirationBpm,
    Expression<double>? adherenceDeltaBpm,
    Expression<double>? respirationFitError,
    Expression<int>? ectopicCorrections,
    Expression<bool>? qualityPassed,
    Expression<String>? qualityFlagsJson,
    Expression<bool>? appliedToPatient,
    Expression<bool>? estimateConfirmed,
    Expression<String>? protocolJson,
    Expression<String>? resultJson,
    Expression<String>? rrSamplesJson,
    Expression<String>? respirationSamplesJson,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (sessionSummaryId != null) 'session_summary_id': sessionSummaryId,
      if (surface != null) 'surface': surface,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (completedCycles != null) 'completed_cycles': completedCycles,
      if (rfBpm != null) 'rf_bpm': rfBpm,
      if (rfCenterElapsedMs != null) 'rf_center_elapsed_ms': rfCenterElapsedMs,
      if (peakToTroughAmplitude != null)
        'peak_to_trough_amplitude': peakToTroughAmplitude,
      if (scheduledBpmAtCenter != null)
        'scheduled_bpm_at_center': scheduledBpmAtCenter,
      if (fittedRespirationBpm != null)
        'fitted_respiration_bpm': fittedRespirationBpm,
      if (adherenceDeltaBpm != null) 'adherence_delta_bpm': adherenceDeltaBpm,
      if (respirationFitError != null)
        'respiration_fit_error': respirationFitError,
      if (ectopicCorrections != null) 'ectopic_corrections': ectopicCorrections,
      if (qualityPassed != null) 'quality_passed': qualityPassed,
      if (qualityFlagsJson != null) 'quality_flags_json': qualityFlagsJson,
      if (appliedToPatient != null) 'applied_to_patient': appliedToPatient,
      if (estimateConfirmed != null) 'estimate_confirmed': estimateConfirmed,
      if (protocolJson != null) 'protocol_json': protocolJson,
      if (resultJson != null) 'result_json': resultJson,
      if (rrSamplesJson != null) 'rr_samples_json': rrSamplesJson,
      if (respirationSamplesJson != null)
        'respiration_samples_json': respirationSamplesJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RfAssessmentRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? patientId,
    Value<int?>? sessionSummaryId,
    Value<String>? surface,
    Value<String>? protocolVersion,
    Value<String>? mode,
    Value<String>? status,
    Value<String>? startedAt,
    Value<String>? endedAt,
    Value<double>? durationMs,
    Value<int>? completedCycles,
    Value<double?>? rfBpm,
    Value<double?>? rfCenterElapsedMs,
    Value<double?>? peakToTroughAmplitude,
    Value<double?>? scheduledBpmAtCenter,
    Value<double?>? fittedRespirationBpm,
    Value<double?>? adherenceDeltaBpm,
    Value<double?>? respirationFitError,
    Value<int>? ectopicCorrections,
    Value<bool>? qualityPassed,
    Value<String>? qualityFlagsJson,
    Value<bool>? appliedToPatient,
    Value<bool?>? estimateConfirmed,
    Value<String>? protocolJson,
    Value<String>? resultJson,
    Value<String>? rrSamplesJson,
    Value<String?>? respirationSamplesJson,
    Value<String>? createdAt,
  }) {
    return RfAssessmentRecordsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      sessionSummaryId: sessionSummaryId ?? this.sessionSummaryId,
      surface: surface ?? this.surface,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
      completedCycles: completedCycles ?? this.completedCycles,
      rfBpm: rfBpm ?? this.rfBpm,
      rfCenterElapsedMs: rfCenterElapsedMs ?? this.rfCenterElapsedMs,
      peakToTroughAmplitude:
          peakToTroughAmplitude ?? this.peakToTroughAmplitude,
      scheduledBpmAtCenter: scheduledBpmAtCenter ?? this.scheduledBpmAtCenter,
      fittedRespirationBpm: fittedRespirationBpm ?? this.fittedRespirationBpm,
      adherenceDeltaBpm: adherenceDeltaBpm ?? this.adherenceDeltaBpm,
      respirationFitError: respirationFitError ?? this.respirationFitError,
      ectopicCorrections: ectopicCorrections ?? this.ectopicCorrections,
      qualityPassed: qualityPassed ?? this.qualityPassed,
      qualityFlagsJson: qualityFlagsJson ?? this.qualityFlagsJson,
      appliedToPatient: appliedToPatient ?? this.appliedToPatient,
      estimateConfirmed: estimateConfirmed ?? this.estimateConfirmed,
      protocolJson: protocolJson ?? this.protocolJson,
      resultJson: resultJson ?? this.resultJson,
      rrSamplesJson: rrSamplesJson ?? this.rrSamplesJson,
      respirationSamplesJson:
          respirationSamplesJson ?? this.respirationSamplesJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (sessionSummaryId.present) {
      map['session_summary_id'] = Variable<int>(sessionSummaryId.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<String>(protocolVersion.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(endedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<double>(durationMs.value);
    }
    if (completedCycles.present) {
      map['completed_cycles'] = Variable<int>(completedCycles.value);
    }
    if (rfBpm.present) {
      map['rf_bpm'] = Variable<double>(rfBpm.value);
    }
    if (rfCenterElapsedMs.present) {
      map['rf_center_elapsed_ms'] = Variable<double>(rfCenterElapsedMs.value);
    }
    if (peakToTroughAmplitude.present) {
      map['peak_to_trough_amplitude'] = Variable<double>(
        peakToTroughAmplitude.value,
      );
    }
    if (scheduledBpmAtCenter.present) {
      map['scheduled_bpm_at_center'] = Variable<double>(
        scheduledBpmAtCenter.value,
      );
    }
    if (fittedRespirationBpm.present) {
      map['fitted_respiration_bpm'] = Variable<double>(
        fittedRespirationBpm.value,
      );
    }
    if (adherenceDeltaBpm.present) {
      map['adherence_delta_bpm'] = Variable<double>(adherenceDeltaBpm.value);
    }
    if (respirationFitError.present) {
      map['respiration_fit_error'] = Variable<double>(
        respirationFitError.value,
      );
    }
    if (ectopicCorrections.present) {
      map['ectopic_corrections'] = Variable<int>(ectopicCorrections.value);
    }
    if (qualityPassed.present) {
      map['quality_passed'] = Variable<bool>(qualityPassed.value);
    }
    if (qualityFlagsJson.present) {
      map['quality_flags_json'] = Variable<String>(qualityFlagsJson.value);
    }
    if (appliedToPatient.present) {
      map['applied_to_patient'] = Variable<bool>(appliedToPatient.value);
    }
    if (estimateConfirmed.present) {
      map['estimate_confirmed'] = Variable<bool>(estimateConfirmed.value);
    }
    if (protocolJson.present) {
      map['protocol_json'] = Variable<String>(protocolJson.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (rrSamplesJson.present) {
      map['rr_samples_json'] = Variable<String>(rrSamplesJson.value);
    }
    if (respirationSamplesJson.present) {
      map['respiration_samples_json'] = Variable<String>(
        respirationSamplesJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RfAssessmentRecordsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('sessionSummaryId: $sessionSummaryId, ')
          ..write('surface: $surface, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('completedCycles: $completedCycles, ')
          ..write('rfBpm: $rfBpm, ')
          ..write('rfCenterElapsedMs: $rfCenterElapsedMs, ')
          ..write('peakToTroughAmplitude: $peakToTroughAmplitude, ')
          ..write('scheduledBpmAtCenter: $scheduledBpmAtCenter, ')
          ..write('fittedRespirationBpm: $fittedRespirationBpm, ')
          ..write('adherenceDeltaBpm: $adherenceDeltaBpm, ')
          ..write('respirationFitError: $respirationFitError, ')
          ..write('ectopicCorrections: $ectopicCorrections, ')
          ..write('qualityPassed: $qualityPassed, ')
          ..write('qualityFlagsJson: $qualityFlagsJson, ')
          ..write('appliedToPatient: $appliedToPatient, ')
          ..write('estimateConfirmed: $estimateConfirmed, ')
          ..write('protocolJson: $protocolJson, ')
          ..write('resultJson: $resultJson, ')
          ..write('rrSamplesJson: $rrSamplesJson, ')
          ..write('respirationSamplesJson: $respirationSamplesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $BreathRateEntriesTable breathRateEntries =
      $BreathRateEntriesTable(this);
  late final $HeartRateEntriesTable heartRateEntries = $HeartRateEntriesTable(
    this,
  );
  late final $EcgSampleEntriesTable ecgSampleEntries = $EcgSampleEntriesTable(
    this,
  );
  late final $HrvEntriesTable hrvEntries = $HrvEntriesTable(this);
  late final $PsychometricEntriesTable psychometricEntries =
      $PsychometricEntriesTable(this);
  late final $SessionSummariesTable sessionSummaries = $SessionSummariesTable(
    this,
  );
  late final $RfAssessmentRecordsTable rfAssessmentRecords =
      $RfAssessmentRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    patients,
    sessions,
    breathRateEntries,
    heartRateEntries,
    ecgSampleEntries,
    hrvEntries,
    psychometricEntries,
    sessionSummaries,
    rfAssessmentRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('breath_rate_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('breath_rate_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('heart_rate_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('heart_rate_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ecg_sample_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ecg_sample_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hrv_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hrv_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('psychometric_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_summaries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'patients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rf_assessment_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_summaries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rf_assessment_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PatientsTableCreateCompanionBuilder =
    PatientsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> dateOfBirth,
      Value<int?> age,
      Value<String?> sex,
      Value<double?> heightCm,
      Value<String?> notes,
      Value<double?> resonanceFrequency,
      required String createdAt,
      required String updatedAt,
    });
typedef $$PatientsTableUpdateCompanionBuilder =
    PatientsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> dateOfBirth,
      Value<int?> age,
      Value<String?> sex,
      Value<double?> heightCm,
      Value<String?> notes,
      Value<double?> resonanceFrequency,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

final class $$PatientsTableReferences
    extends BaseReferences<_$AppDatabase, $PatientsTable, Patient> {
  $$PatientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.patients.id, db.sessions.patientId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BreathRateEntriesTable, List<BreathRateEntry>>
  _breathRateEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.breathRateEntries,
        aliasName: $_aliasNameGenerator(
          db.patients.id,
          db.breathRateEntries.patientId,
        ),
      );

  $$BreathRateEntriesTableProcessedTableManager get breathRateEntriesRefs {
    final manager = $$BreathRateEntriesTableTableManager(
      $_db,
      $_db.breathRateEntries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _breathRateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HeartRateEntriesTable, List<HeartRateEntry>>
  _heartRateEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.heartRateEntries,
    aliasName: $_aliasNameGenerator(
      db.patients.id,
      db.heartRateEntries.patientId,
    ),
  );

  $$HeartRateEntriesTableProcessedTableManager get heartRateEntriesRefs {
    final manager = $$HeartRateEntriesTableTableManager(
      $_db,
      $_db.heartRateEntries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _heartRateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EcgSampleEntriesTable, List<EcgSampleEntry>>
  _ecgSampleEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecgSampleEntries,
    aliasName: $_aliasNameGenerator(
      db.patients.id,
      db.ecgSampleEntries.patientId,
    ),
  );

  $$EcgSampleEntriesTableProcessedTableManager get ecgSampleEntriesRefs {
    final manager = $$EcgSampleEntriesTableTableManager(
      $_db,
      $_db.ecgSampleEntries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ecgSampleEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HrvEntriesTable, List<HrvEntry>>
  _hrvEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hrvEntries,
    aliasName: $_aliasNameGenerator(db.patients.id, db.hrvEntries.patientId),
  );

  $$HrvEntriesTableProcessedTableManager get hrvEntriesRefs {
    final manager = $$HrvEntriesTableTableManager(
      $_db,
      $_db.hrvEntries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_hrvEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PsychometricEntriesTable, List<PsychometricEntry>>
  _psychometricEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.psychometricEntries,
        aliasName: $_aliasNameGenerator(
          db.patients.id,
          db.psychometricEntries.patientId,
        ),
      );

  $$PsychometricEntriesTableProcessedTableManager get psychometricEntriesRefs {
    final manager = $$PsychometricEntriesTableTableManager(
      $_db,
      $_db.psychometricEntries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _psychometricEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionSummariesTable, List<SessionSummary>>
  _sessionSummariesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionSummaries,
    aliasName: $_aliasNameGenerator(
      db.patients.id,
      db.sessionSummaries.patientId,
    ),
  );

  $$SessionSummariesTableProcessedTableManager get sessionSummariesRefs {
    final manager = $$SessionSummariesTableTableManager(
      $_db,
      $_db.sessionSummaries,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionSummariesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RfAssessmentRecordsTable,
    List<RfAssessmentRecord>
  >
  _rfAssessmentRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rfAssessmentRecords,
        aliasName: $_aliasNameGenerator(
          db.patients.id,
          db.rfAssessmentRecords.patientId,
        ),
      );

  $$RfAssessmentRecordsTableProcessedTableManager get rfAssessmentRecordsRefs {
    final manager = $$RfAssessmentRecordsTableTableManager(
      $_db,
      $_db.rfAssessmentRecords,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rfAssessmentRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resonanceFrequency => $composableBuilder(
    column: $table.resonanceFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> breathRateEntriesRefs(
    Expression<bool> Function($$BreathRateEntriesTableFilterComposer f) f,
  ) {
    final $$BreathRateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.breathRateEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BreathRateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.breathRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> heartRateEntriesRefs(
    Expression<bool> Function($$HeartRateEntriesTableFilterComposer f) f,
  ) {
    final $$HeartRateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heartRateEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartRateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.heartRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ecgSampleEntriesRefs(
    Expression<bool> Function($$EcgSampleEntriesTableFilterComposer f) f,
  ) {
    final $$EcgSampleEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecgSampleEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcgSampleEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ecgSampleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hrvEntriesRefs(
    Expression<bool> Function($$HrvEntriesTableFilterComposer f) f,
  ) {
    final $$HrvEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvEntriesTableFilterComposer(
            $db: $db,
            $table: $db.hrvEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> psychometricEntriesRefs(
    Expression<bool> Function($$PsychometricEntriesTableFilterComposer f) f,
  ) {
    final $$PsychometricEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.psychometricEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PsychometricEntriesTableFilterComposer(
            $db: $db,
            $table: $db.psychometricEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionSummariesRefs(
    Expression<bool> Function($$SessionSummariesTableFilterComposer f) f,
  ) {
    final $$SessionSummariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSummaries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSummariesTableFilterComposer(
            $db: $db,
            $table: $db.sessionSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rfAssessmentRecordsRefs(
    Expression<bool> Function($$RfAssessmentRecordsTableFilterComposer f) f,
  ) {
    final $$RfAssessmentRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rfAssessmentRecords,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RfAssessmentRecordsTableFilterComposer(
            $db: $db,
            $table: $db.rfAssessmentRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resonanceFrequency => $composableBuilder(
    column: $table.resonanceFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get resonanceFrequency => $composableBuilder(
    column: $table.resonanceFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> breathRateEntriesRefs<T extends Object>(
    Expression<T> Function($$BreathRateEntriesTableAnnotationComposer a) f,
  ) {
    final $$BreathRateEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.breathRateEntries,
          getReferencedColumn: (t) => t.patientId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BreathRateEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.breathRateEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> heartRateEntriesRefs<T extends Object>(
    Expression<T> Function($$HeartRateEntriesTableAnnotationComposer a) f,
  ) {
    final $$HeartRateEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heartRateEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartRateEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.heartRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ecgSampleEntriesRefs<T extends Object>(
    Expression<T> Function($$EcgSampleEntriesTableAnnotationComposer a) f,
  ) {
    final $$EcgSampleEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecgSampleEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcgSampleEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ecgSampleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> hrvEntriesRefs<T extends Object>(
    Expression<T> Function($$HrvEntriesTableAnnotationComposer a) f,
  ) {
    final $$HrvEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvEntries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.hrvEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> psychometricEntriesRefs<T extends Object>(
    Expression<T> Function($$PsychometricEntriesTableAnnotationComposer a) f,
  ) {
    final $$PsychometricEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.psychometricEntries,
          getReferencedColumn: (t) => t.patientId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PsychometricEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.psychometricEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> sessionSummariesRefs<T extends Object>(
    Expression<T> Function($$SessionSummariesTableAnnotationComposer a) f,
  ) {
    final $$SessionSummariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSummaries,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSummariesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rfAssessmentRecordsRefs<T extends Object>(
    Expression<T> Function($$RfAssessmentRecordsTableAnnotationComposer a) f,
  ) {
    final $$RfAssessmentRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rfAssessmentRecords,
          getReferencedColumn: (t) => t.patientId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RfAssessmentRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.rfAssessmentRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PatientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatientsTable,
          Patient,
          $$PatientsTableFilterComposer,
          $$PatientsTableOrderingComposer,
          $$PatientsTableAnnotationComposer,
          $$PatientsTableCreateCompanionBuilder,
          $$PatientsTableUpdateCompanionBuilder,
          (Patient, $$PatientsTableReferences),
          Patient,
          PrefetchHooks Function({
            bool sessionsRefs,
            bool breathRateEntriesRefs,
            bool heartRateEntriesRefs,
            bool ecgSampleEntriesRefs,
            bool hrvEntriesRefs,
            bool psychometricEntriesRefs,
            bool sessionSummariesRefs,
            bool rfAssessmentRecordsRefs,
          })
        > {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> resonanceFrequency = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => PatientsCompanion(
                id: id,
                name: name,
                dateOfBirth: dateOfBirth,
                age: age,
                sex: sex,
                heightCm: heightCm,
                notes: notes,
                resonanceFrequency: resonanceFrequency,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> dateOfBirth = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<double?> resonanceFrequency = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => PatientsCompanion.insert(
                id: id,
                name: name,
                dateOfBirth: dateOfBirth,
                age: age,
                sex: sex,
                heightCm: heightCm,
                notes: notes,
                resonanceFrequency: resonanceFrequency,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PatientsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            sessionsRefs = false,
            breathRateEntriesRefs = false,
            heartRateEntriesRefs = false,
            ecgSampleEntriesRefs = false,
            hrvEntriesRefs = false,
            psychometricEntriesRefs = false,
            sessionSummariesRefs = false,
            rfAssessmentRecordsRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionsRefs) db.sessions,
                if (breathRateEntriesRefs) db.breathRateEntries,
                if (heartRateEntriesRefs) db.heartRateEntries,
                if (ecgSampleEntriesRefs) db.ecgSampleEntries,
                if (hrvEntriesRefs) db.hrvEntries,
                if (psychometricEntriesRefs) db.psychometricEntries,
                if (sessionSummariesRefs) db.sessionSummaries,
                if (rfAssessmentRecordsRefs) db.rfAssessmentRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<Patient, $PatientsTable, Session>(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (breathRateEntriesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      BreathRateEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._breathRateEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).breathRateEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (heartRateEntriesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      HeartRateEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._heartRateEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).heartRateEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (ecgSampleEntriesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      EcgSampleEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._ecgSampleEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).ecgSampleEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (hrvEntriesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      HrvEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._hrvEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).hrvEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (psychometricEntriesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      PsychometricEntry
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._psychometricEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).psychometricEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (sessionSummariesRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      SessionSummary
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._sessionSummariesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionSummariesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (rfAssessmentRecordsRefs)
                    await $_getPrefetchedData<
                      Patient,
                      $PatientsTable,
                      RfAssessmentRecord
                    >(
                      currentTable: table,
                      referencedTable: $$PatientsTableReferences
                          ._rfAssessmentRecordsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$PatientsTableReferences(
                                db,
                                table,
                                p0,
                              ).rfAssessmentRecordsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.patientId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PatientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatientsTable,
      Patient,
      $$PatientsTableFilterComposer,
      $$PatientsTableOrderingComposer,
      $$PatientsTableAnnotationComposer,
      $$PatientsTableCreateCompanionBuilder,
      $$PatientsTableUpdateCompanionBuilder,
      (Patient, $$PatientsTableReferences),
      Patient,
      PrefetchHooks Function({
        bool sessionsRefs,
        bool breathRateEntriesRefs,
        bool heartRateEntriesRefs,
        bool ecgSampleEntriesRefs,
        bool hrvEntriesRefs,
        bool psychometricEntriesRefs,
        bool sessionSummariesRefs,
        bool rfAssessmentRecordsRefs,
      })
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required int patientId,
      required String sessionType,
      required String startedAt,
      Value<String?> endedAt,
      Value<String?> notes,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<int> patientId,
      Value<String> sessionType,
      Value<String> startedAt,
      Value<String?> endedAt,
      Value<String?> notes,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PatientsTable _patientIdTable(_$AppDatabase db) => db.patients
      .createAlias($_aliasNameGenerator(db.sessions.patientId, db.patients.id));

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BreathRateEntriesTable, List<BreathRateEntry>>
  _breathRateEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.breathRateEntries,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.breathRateEntries.sessionId,
        ),
      );

  $$BreathRateEntriesTableProcessedTableManager get breathRateEntriesRefs {
    final manager = $$BreathRateEntriesTableTableManager(
      $_db,
      $_db.breathRateEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _breathRateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HeartRateEntriesTable, List<HeartRateEntry>>
  _heartRateEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.heartRateEntries,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.heartRateEntries.sessionId,
    ),
  );

  $$HeartRateEntriesTableProcessedTableManager get heartRateEntriesRefs {
    final manager = $$HeartRateEntriesTableTableManager(
      $_db,
      $_db.heartRateEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _heartRateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EcgSampleEntriesTable, List<EcgSampleEntry>>
  _ecgSampleEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ecgSampleEntries,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.ecgSampleEntries.sessionId,
    ),
  );

  $$EcgSampleEntriesTableProcessedTableManager get ecgSampleEntriesRefs {
    final manager = $$EcgSampleEntriesTableTableManager(
      $_db,
      $_db.ecgSampleEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ecgSampleEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HrvEntriesTable, List<HrvEntry>>
  _hrvEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hrvEntries,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.hrvEntries.sessionId),
  );

  $$HrvEntriesTableProcessedTableManager get hrvEntriesRefs {
    final manager = $$HrvEntriesTableTableManager(
      $_db,
      $_db.hrvEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_hrvEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> breathRateEntriesRefs(
    Expression<bool> Function($$BreathRateEntriesTableFilterComposer f) f,
  ) {
    final $$BreathRateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.breathRateEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BreathRateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.breathRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> heartRateEntriesRefs(
    Expression<bool> Function($$HeartRateEntriesTableFilterComposer f) f,
  ) {
    final $$HeartRateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heartRateEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartRateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.heartRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ecgSampleEntriesRefs(
    Expression<bool> Function($$EcgSampleEntriesTableFilterComposer f) f,
  ) {
    final $$EcgSampleEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecgSampleEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcgSampleEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ecgSampleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hrvEntriesRefs(
    Expression<bool> Function($$HrvEntriesTableFilterComposer f) f,
  ) {
    final $$HrvEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvEntriesTableFilterComposer(
            $db: $db,
            $table: $db.hrvEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> breathRateEntriesRefs<T extends Object>(
    Expression<T> Function($$BreathRateEntriesTableAnnotationComposer a) f,
  ) {
    final $$BreathRateEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.breathRateEntries,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BreathRateEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.breathRateEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> heartRateEntriesRefs<T extends Object>(
    Expression<T> Function($$HeartRateEntriesTableAnnotationComposer a) f,
  ) {
    final $$HeartRateEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.heartRateEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartRateEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.heartRateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ecgSampleEntriesRefs<T extends Object>(
    Expression<T> Function($$EcgSampleEntriesTableAnnotationComposer a) f,
  ) {
    final $$EcgSampleEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ecgSampleEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EcgSampleEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ecgSampleEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> hrvEntriesRefs<T extends Object>(
    Expression<T> Function($$HrvEntriesTableAnnotationComposer a) f,
  ) {
    final $$HrvEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.hrvEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool patientId,
            bool breathRateEntriesRefs,
            bool heartRateEntriesRefs,
            bool ecgSampleEntriesRefs,
            bool hrvEntriesRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int patientId,
                required String sessionType,
                required String startedAt,
                Value<String?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$SessionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            patientId = false,
            breathRateEntriesRefs = false,
            heartRateEntriesRefs = false,
            ecgSampleEntriesRefs = false,
            hrvEntriesRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (breathRateEntriesRefs) db.breathRateEntries,
                if (heartRateEntriesRefs) db.heartRateEntries,
                if (ecgSampleEntriesRefs) db.ecgSampleEntries,
                if (hrvEntriesRefs) db.hrvEntries,
              ],
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
                  dynamic
                >
              >(state) {
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$SessionsTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$SessionsTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (breathRateEntriesRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      BreathRateEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._breathRateEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).breathRateEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.sessionId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (heartRateEntriesRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      HeartRateEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._heartRateEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).heartRateEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.sessionId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (ecgSampleEntriesRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      EcgSampleEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._ecgSampleEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).ecgSampleEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.sessionId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (hrvEntriesRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      HrvEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._hrvEntriesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).hrvEntriesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.sessionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool patientId,
        bool breathRateEntriesRefs,
        bool heartRateEntriesRefs,
        bool ecgSampleEntriesRefs,
        bool hrvEntriesRefs,
      })
    >;
typedef $$BreathRateEntriesTableCreateCompanionBuilder =
    BreathRateEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int patientId,
      required String timestamp,
      required int rate,
      Value<String> source,
    });
typedef $$BreathRateEntriesTableUpdateCompanionBuilder =
    BreathRateEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> patientId,
      Value<String> timestamp,
      Value<int> rate,
      Value<String> source,
    });

final class $$BreathRateEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BreathRateEntriesTable,
          BreathRateEntry
        > {
  $$BreathRateEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.breathRateEntries.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.breathRateEntries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BreathRateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BreathRateEntriesTable> {
  $$BreathRateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreathRateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BreathRateEntriesTable> {
  $$BreathRateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreathRateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreathRateEntriesTable> {
  $$BreathRateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreathRateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BreathRateEntriesTable,
          BreathRateEntry,
          $$BreathRateEntriesTableFilterComposer,
          $$BreathRateEntriesTableOrderingComposer,
          $$BreathRateEntriesTableAnnotationComposer,
          $$BreathRateEntriesTableCreateCompanionBuilder,
          $$BreathRateEntriesTableUpdateCompanionBuilder,
          (BreathRateEntry, $$BreathRateEntriesTableReferences),
          BreathRateEntry,
          PrefetchHooks Function({bool sessionId, bool patientId})
        > {
  $$BreathRateEntriesTableTableManager(
    _$AppDatabase db,
    $BreathRateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BreathRateEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$BreathRateEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$BreathRateEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rate = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => BreathRateEntriesCompanion(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                rate: rate,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int patientId,
                required String timestamp,
                required int rate,
                Value<String> source = const Value.absent(),
              }) => BreathRateEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                rate: rate,
                source: source,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$BreathRateEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({sessionId = false, patientId = false}) {
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
                  dynamic
                >
              >(state) {
                if (sessionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$BreathRateEntriesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn:
                                $$BreathRateEntriesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$BreathRateEntriesTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$BreathRateEntriesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BreathRateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BreathRateEntriesTable,
      BreathRateEntry,
      $$BreathRateEntriesTableFilterComposer,
      $$BreathRateEntriesTableOrderingComposer,
      $$BreathRateEntriesTableAnnotationComposer,
      $$BreathRateEntriesTableCreateCompanionBuilder,
      $$BreathRateEntriesTableUpdateCompanionBuilder,
      (BreathRateEntry, $$BreathRateEntriesTableReferences),
      BreathRateEntry,
      PrefetchHooks Function({bool sessionId, bool patientId})
    >;
typedef $$HeartRateEntriesTableCreateCompanionBuilder =
    HeartRateEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int patientId,
      required String timestamp,
      required int rate,
    });
typedef $$HeartRateEntriesTableUpdateCompanionBuilder =
    HeartRateEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> patientId,
      Value<String> timestamp,
      Value<int> rate,
    });

final class $$HeartRateEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $HeartRateEntriesTable, HeartRateEntry> {
  $$HeartRateEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.heartRateEntries.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.heartRateEntries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HeartRateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HeartRateEntriesTable> {
  $$HeartRateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartRateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HeartRateEntriesTable> {
  $$HeartRateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartRateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeartRateEntriesTable> {
  $$HeartRateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartRateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeartRateEntriesTable,
          HeartRateEntry,
          $$HeartRateEntriesTableFilterComposer,
          $$HeartRateEntriesTableOrderingComposer,
          $$HeartRateEntriesTableAnnotationComposer,
          $$HeartRateEntriesTableCreateCompanionBuilder,
          $$HeartRateEntriesTableUpdateCompanionBuilder,
          (HeartRateEntry, $$HeartRateEntriesTableReferences),
          HeartRateEntry,
          PrefetchHooks Function({bool sessionId, bool patientId})
        > {
  $$HeartRateEntriesTableTableManager(
    _$AppDatabase db,
    $HeartRateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$HeartRateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HeartRateEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$HeartRateEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rate = const Value.absent(),
              }) => HeartRateEntriesCompanion(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                rate: rate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int patientId,
                required String timestamp,
                required int rate,
              }) => HeartRateEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                rate: rate,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$HeartRateEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({sessionId = false, patientId = false}) {
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
                  dynamic
                >
              >(state) {
                if (sessionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$HeartRateEntriesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn:
                                $$HeartRateEntriesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$HeartRateEntriesTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$HeartRateEntriesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HeartRateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeartRateEntriesTable,
      HeartRateEntry,
      $$HeartRateEntriesTableFilterComposer,
      $$HeartRateEntriesTableOrderingComposer,
      $$HeartRateEntriesTableAnnotationComposer,
      $$HeartRateEntriesTableCreateCompanionBuilder,
      $$HeartRateEntriesTableUpdateCompanionBuilder,
      (HeartRateEntry, $$HeartRateEntriesTableReferences),
      HeartRateEntry,
      PrefetchHooks Function({bool sessionId, bool patientId})
    >;
typedef $$EcgSampleEntriesTableCreateCompanionBuilder =
    EcgSampleEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int patientId,
      required int timestampMs,
      Value<int?> timestampUs,
      required int elapsedMs,
      Value<int?> elapsedUs,
      required int sampleIndex,
      required double ecgUv,
    });
typedef $$EcgSampleEntriesTableUpdateCompanionBuilder =
    EcgSampleEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> patientId,
      Value<int> timestampMs,
      Value<int?> timestampUs,
      Value<int> elapsedMs,
      Value<int?> elapsedUs,
      Value<int> sampleIndex,
      Value<double> ecgUv,
    });

final class $$EcgSampleEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $EcgSampleEntriesTable, EcgSampleEntry> {
  $$EcgSampleEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.ecgSampleEntries.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.ecgSampleEntries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EcgSampleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EcgSampleEntriesTable> {
  $$EcgSampleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampUs => $composableBuilder(
    column: $table.timestampUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedUs => $composableBuilder(
    column: $table.elapsedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleIndex => $composableBuilder(
    column: $table.sampleIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ecgUv => $composableBuilder(
    column: $table.ecgUv,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcgSampleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EcgSampleEntriesTable> {
  $$EcgSampleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampUs => $composableBuilder(
    column: $table.timestampUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedUs => $composableBuilder(
    column: $table.elapsedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleIndex => $composableBuilder(
    column: $table.sampleIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ecgUv => $composableBuilder(
    column: $table.ecgUv,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcgSampleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcgSampleEntriesTable> {
  $$EcgSampleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestampUs => $composableBuilder(
    column: $table.timestampUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<int> get elapsedUs =>
      $composableBuilder(column: $table.elapsedUs, builder: (column) => column);

  GeneratedColumn<int> get sampleIndex => $composableBuilder(
    column: $table.sampleIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ecgUv =>
      $composableBuilder(column: $table.ecgUv, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EcgSampleEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EcgSampleEntriesTable,
          EcgSampleEntry,
          $$EcgSampleEntriesTableFilterComposer,
          $$EcgSampleEntriesTableOrderingComposer,
          $$EcgSampleEntriesTableAnnotationComposer,
          $$EcgSampleEntriesTableCreateCompanionBuilder,
          $$EcgSampleEntriesTableUpdateCompanionBuilder,
          (EcgSampleEntry, $$EcgSampleEntriesTableReferences),
          EcgSampleEntry,
          PrefetchHooks Function({bool sessionId, bool patientId})
        > {
  $$EcgSampleEntriesTableTableManager(
    _$AppDatabase db,
    $EcgSampleEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$EcgSampleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$EcgSampleEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$EcgSampleEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<int?> timestampUs = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<int?> elapsedUs = const Value.absent(),
                Value<int> sampleIndex = const Value.absent(),
                Value<double> ecgUv = const Value.absent(),
              }) => EcgSampleEntriesCompanion(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestampMs: timestampMs,
                timestampUs: timestampUs,
                elapsedMs: elapsedMs,
                elapsedUs: elapsedUs,
                sampleIndex: sampleIndex,
                ecgUv: ecgUv,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int patientId,
                required int timestampMs,
                Value<int?> timestampUs = const Value.absent(),
                required int elapsedMs,
                Value<int?> elapsedUs = const Value.absent(),
                required int sampleIndex,
                required double ecgUv,
              }) => EcgSampleEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestampMs: timestampMs,
                timestampUs: timestampUs,
                elapsedMs: elapsedMs,
                elapsedUs: elapsedUs,
                sampleIndex: sampleIndex,
                ecgUv: ecgUv,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$EcgSampleEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({sessionId = false, patientId = false}) {
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
                  dynamic
                >
              >(state) {
                if (sessionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$EcgSampleEntriesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn:
                                $$EcgSampleEntriesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$EcgSampleEntriesTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$EcgSampleEntriesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EcgSampleEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EcgSampleEntriesTable,
      EcgSampleEntry,
      $$EcgSampleEntriesTableFilterComposer,
      $$EcgSampleEntriesTableOrderingComposer,
      $$EcgSampleEntriesTableAnnotationComposer,
      $$EcgSampleEntriesTableCreateCompanionBuilder,
      $$EcgSampleEntriesTableUpdateCompanionBuilder,
      (EcgSampleEntry, $$EcgSampleEntriesTableReferences),
      EcgSampleEntry,
      PrefetchHooks Function({bool sessionId, bool patientId})
    >;
typedef $$HrvEntriesTableCreateCompanionBuilder =
    HrvEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int patientId,
      required String timestamp,
      Value<double?> meanNn,
      Value<double?> sdnn,
      Value<double?> rmssd,
      Value<double?> sdsd,
      Value<double?> cvnn,
      Value<double?> cvsd,
      Value<double?> medianNn,
      Value<double?> madNn,
      Value<double?> mcvnn,
      Value<double?> iqrnn,
      Value<double?> sdrmssd,
      Value<double?> prc20nn,
      Value<double?> prc80nn,
      Value<double?> pnn50,
      Value<double?> pnn20,
      Value<double?> minNn,
      Value<double?> maxNn,
      Value<double?> hti,
      Value<double?> tinn,
      Value<double?> sdann1,
      Value<double?> sdann2,
      Value<double?> sdann5,
      Value<double?> sdnni1,
      Value<double?> sdnni2,
      Value<double?> sdnni5,
    });
typedef $$HrvEntriesTableUpdateCompanionBuilder =
    HrvEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> patientId,
      Value<String> timestamp,
      Value<double?> meanNn,
      Value<double?> sdnn,
      Value<double?> rmssd,
      Value<double?> sdsd,
      Value<double?> cvnn,
      Value<double?> cvsd,
      Value<double?> medianNn,
      Value<double?> madNn,
      Value<double?> mcvnn,
      Value<double?> iqrnn,
      Value<double?> sdrmssd,
      Value<double?> prc20nn,
      Value<double?> prc80nn,
      Value<double?> pnn50,
      Value<double?> pnn20,
      Value<double?> minNn,
      Value<double?> maxNn,
      Value<double?> hti,
      Value<double?> tinn,
      Value<double?> sdann1,
      Value<double?> sdann2,
      Value<double?> sdann5,
      Value<double?> sdnni1,
      Value<double?> sdnni2,
      Value<double?> sdnni5,
    });

final class $$HrvEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $HrvEntriesTable, HrvEntry> {
  $$HrvEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.hrvEntries.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.hrvEntries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HrvEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HrvEntriesTable> {
  $$HrvEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanNn => $composableBuilder(
    column: $table.meanNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdsd => $composableBuilder(
    column: $table.sdsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cvnn => $composableBuilder(
    column: $table.cvnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cvsd => $composableBuilder(
    column: $table.cvsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get medianNn => $composableBuilder(
    column: $table.medianNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get madNn => $composableBuilder(
    column: $table.madNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mcvnn => $composableBuilder(
    column: $table.mcvnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get iqrnn => $composableBuilder(
    column: $table.iqrnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdrmssd => $composableBuilder(
    column: $table.sdrmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prc20nn => $composableBuilder(
    column: $table.prc20nn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prc80nn => $composableBuilder(
    column: $table.prc80nn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pnn50 => $composableBuilder(
    column: $table.pnn50,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pnn20 => $composableBuilder(
    column: $table.pnn20,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minNn => $composableBuilder(
    column: $table.minNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxNn => $composableBuilder(
    column: $table.maxNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hti => $composableBuilder(
    column: $table.hti,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tinn => $composableBuilder(
    column: $table.tinn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdann1 => $composableBuilder(
    column: $table.sdann1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdann2 => $composableBuilder(
    column: $table.sdann2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdann5 => $composableBuilder(
    column: $table.sdann5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnni1 => $composableBuilder(
    column: $table.sdnni1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnni2 => $composableBuilder(
    column: $table.sdnni2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnni5 => $composableBuilder(
    column: $table.sdnni5,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HrvEntriesTable> {
  $$HrvEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanNn => $composableBuilder(
    column: $table.meanNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdsd => $composableBuilder(
    column: $table.sdsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cvnn => $composableBuilder(
    column: $table.cvnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cvsd => $composableBuilder(
    column: $table.cvsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get medianNn => $composableBuilder(
    column: $table.medianNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get madNn => $composableBuilder(
    column: $table.madNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mcvnn => $composableBuilder(
    column: $table.mcvnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get iqrnn => $composableBuilder(
    column: $table.iqrnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdrmssd => $composableBuilder(
    column: $table.sdrmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prc20nn => $composableBuilder(
    column: $table.prc20nn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prc80nn => $composableBuilder(
    column: $table.prc80nn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pnn50 => $composableBuilder(
    column: $table.pnn50,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pnn20 => $composableBuilder(
    column: $table.pnn20,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minNn => $composableBuilder(
    column: $table.minNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxNn => $composableBuilder(
    column: $table.maxNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hti => $composableBuilder(
    column: $table.hti,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tinn => $composableBuilder(
    column: $table.tinn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdann1 => $composableBuilder(
    column: $table.sdann1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdann2 => $composableBuilder(
    column: $table.sdann2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdann5 => $composableBuilder(
    column: $table.sdann5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnni1 => $composableBuilder(
    column: $table.sdnni1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnni2 => $composableBuilder(
    column: $table.sdnni2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnni5 => $composableBuilder(
    column: $table.sdnni5,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HrvEntriesTable> {
  $$HrvEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get meanNn =>
      $composableBuilder(column: $table.meanNn, builder: (column) => column);

  GeneratedColumn<double> get sdnn =>
      $composableBuilder(column: $table.sdnn, builder: (column) => column);

  GeneratedColumn<double> get rmssd =>
      $composableBuilder(column: $table.rmssd, builder: (column) => column);

  GeneratedColumn<double> get sdsd =>
      $composableBuilder(column: $table.sdsd, builder: (column) => column);

  GeneratedColumn<double> get cvnn =>
      $composableBuilder(column: $table.cvnn, builder: (column) => column);

  GeneratedColumn<double> get cvsd =>
      $composableBuilder(column: $table.cvsd, builder: (column) => column);

  GeneratedColumn<double> get medianNn =>
      $composableBuilder(column: $table.medianNn, builder: (column) => column);

  GeneratedColumn<double> get madNn =>
      $composableBuilder(column: $table.madNn, builder: (column) => column);

  GeneratedColumn<double> get mcvnn =>
      $composableBuilder(column: $table.mcvnn, builder: (column) => column);

  GeneratedColumn<double> get iqrnn =>
      $composableBuilder(column: $table.iqrnn, builder: (column) => column);

  GeneratedColumn<double> get sdrmssd =>
      $composableBuilder(column: $table.sdrmssd, builder: (column) => column);

  GeneratedColumn<double> get prc20nn =>
      $composableBuilder(column: $table.prc20nn, builder: (column) => column);

  GeneratedColumn<double> get prc80nn =>
      $composableBuilder(column: $table.prc80nn, builder: (column) => column);

  GeneratedColumn<double> get pnn50 =>
      $composableBuilder(column: $table.pnn50, builder: (column) => column);

  GeneratedColumn<double> get pnn20 =>
      $composableBuilder(column: $table.pnn20, builder: (column) => column);

  GeneratedColumn<double> get minNn =>
      $composableBuilder(column: $table.minNn, builder: (column) => column);

  GeneratedColumn<double> get maxNn =>
      $composableBuilder(column: $table.maxNn, builder: (column) => column);

  GeneratedColumn<double> get hti =>
      $composableBuilder(column: $table.hti, builder: (column) => column);

  GeneratedColumn<double> get tinn =>
      $composableBuilder(column: $table.tinn, builder: (column) => column);

  GeneratedColumn<double> get sdann1 =>
      $composableBuilder(column: $table.sdann1, builder: (column) => column);

  GeneratedColumn<double> get sdann2 =>
      $composableBuilder(column: $table.sdann2, builder: (column) => column);

  GeneratedColumn<double> get sdann5 =>
      $composableBuilder(column: $table.sdann5, builder: (column) => column);

  GeneratedColumn<double> get sdnni1 =>
      $composableBuilder(column: $table.sdnni1, builder: (column) => column);

  GeneratedColumn<double> get sdnni2 =>
      $composableBuilder(column: $table.sdnni2, builder: (column) => column);

  GeneratedColumn<double> get sdnni5 =>
      $composableBuilder(column: $table.sdnni5, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HrvEntriesTable,
          HrvEntry,
          $$HrvEntriesTableFilterComposer,
          $$HrvEntriesTableOrderingComposer,
          $$HrvEntriesTableAnnotationComposer,
          $$HrvEntriesTableCreateCompanionBuilder,
          $$HrvEntriesTableUpdateCompanionBuilder,
          (HrvEntry, $$HrvEntriesTableReferences),
          HrvEntry,
          PrefetchHooks Function({bool sessionId, bool patientId})
        > {
  $$HrvEntriesTableTableManager(_$AppDatabase db, $HrvEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HrvEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HrvEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$HrvEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<double?> meanNn = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> sdsd = const Value.absent(),
                Value<double?> cvnn = const Value.absent(),
                Value<double?> cvsd = const Value.absent(),
                Value<double?> medianNn = const Value.absent(),
                Value<double?> madNn = const Value.absent(),
                Value<double?> mcvnn = const Value.absent(),
                Value<double?> iqrnn = const Value.absent(),
                Value<double?> sdrmssd = const Value.absent(),
                Value<double?> prc20nn = const Value.absent(),
                Value<double?> prc80nn = const Value.absent(),
                Value<double?> pnn50 = const Value.absent(),
                Value<double?> pnn20 = const Value.absent(),
                Value<double?> minNn = const Value.absent(),
                Value<double?> maxNn = const Value.absent(),
                Value<double?> hti = const Value.absent(),
                Value<double?> tinn = const Value.absent(),
                Value<double?> sdann1 = const Value.absent(),
                Value<double?> sdann2 = const Value.absent(),
                Value<double?> sdann5 = const Value.absent(),
                Value<double?> sdnni1 = const Value.absent(),
                Value<double?> sdnni2 = const Value.absent(),
                Value<double?> sdnni5 = const Value.absent(),
              }) => HrvEntriesCompanion(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                meanNn: meanNn,
                sdnn: sdnn,
                rmssd: rmssd,
                sdsd: sdsd,
                cvnn: cvnn,
                cvsd: cvsd,
                medianNn: medianNn,
                madNn: madNn,
                mcvnn: mcvnn,
                iqrnn: iqrnn,
                sdrmssd: sdrmssd,
                prc20nn: prc20nn,
                prc80nn: prc80nn,
                pnn50: pnn50,
                pnn20: pnn20,
                minNn: minNn,
                maxNn: maxNn,
                hti: hti,
                tinn: tinn,
                sdann1: sdann1,
                sdann2: sdann2,
                sdann5: sdann5,
                sdnni1: sdnni1,
                sdnni2: sdnni2,
                sdnni5: sdnni5,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int patientId,
                required String timestamp,
                Value<double?> meanNn = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> sdsd = const Value.absent(),
                Value<double?> cvnn = const Value.absent(),
                Value<double?> cvsd = const Value.absent(),
                Value<double?> medianNn = const Value.absent(),
                Value<double?> madNn = const Value.absent(),
                Value<double?> mcvnn = const Value.absent(),
                Value<double?> iqrnn = const Value.absent(),
                Value<double?> sdrmssd = const Value.absent(),
                Value<double?> prc20nn = const Value.absent(),
                Value<double?> prc80nn = const Value.absent(),
                Value<double?> pnn50 = const Value.absent(),
                Value<double?> pnn20 = const Value.absent(),
                Value<double?> minNn = const Value.absent(),
                Value<double?> maxNn = const Value.absent(),
                Value<double?> hti = const Value.absent(),
                Value<double?> tinn = const Value.absent(),
                Value<double?> sdann1 = const Value.absent(),
                Value<double?> sdann2 = const Value.absent(),
                Value<double?> sdann5 = const Value.absent(),
                Value<double?> sdnni1 = const Value.absent(),
                Value<double?> sdnni2 = const Value.absent(),
                Value<double?> sdnni5 = const Value.absent(),
              }) => HrvEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                patientId: patientId,
                timestamp: timestamp,
                meanNn: meanNn,
                sdnn: sdnn,
                rmssd: rmssd,
                sdsd: sdsd,
                cvnn: cvnn,
                cvsd: cvsd,
                medianNn: medianNn,
                madNn: madNn,
                mcvnn: mcvnn,
                iqrnn: iqrnn,
                sdrmssd: sdrmssd,
                prc20nn: prc20nn,
                prc80nn: prc80nn,
                pnn50: pnn50,
                pnn20: pnn20,
                minNn: minNn,
                maxNn: maxNn,
                hti: hti,
                tinn: tinn,
                sdann1: sdann1,
                sdann2: sdann2,
                sdann5: sdann5,
                sdnni1: sdnni1,
                sdnni2: sdnni2,
                sdnni5: sdnni5,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$HrvEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({sessionId = false, patientId = false}) {
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
                  dynamic
                >
              >(state) {
                if (sessionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$HrvEntriesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn:
                                $$HrvEntriesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$HrvEntriesTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$HrvEntriesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HrvEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HrvEntriesTable,
      HrvEntry,
      $$HrvEntriesTableFilterComposer,
      $$HrvEntriesTableOrderingComposer,
      $$HrvEntriesTableAnnotationComposer,
      $$HrvEntriesTableCreateCompanionBuilder,
      $$HrvEntriesTableUpdateCompanionBuilder,
      (HrvEntry, $$HrvEntriesTableReferences),
      HrvEntry,
      PrefetchHooks Function({bool sessionId, bool patientId})
    >;
typedef $$PsychometricEntriesTableCreateCompanionBuilder =
    PsychometricEntriesCompanion Function({
      Value<int> id,
      required int patientId,
      required String scaleType,
      required int totalScore,
      required String severityLevel,
      required String responsesJson,
      required String administeredAt,
      Value<String?> administeredBy,
      Value<bool> requiresReview,
      Value<String?> notes,
    });
typedef $$PsychometricEntriesTableUpdateCompanionBuilder =
    PsychometricEntriesCompanion Function({
      Value<int> id,
      Value<int> patientId,
      Value<String> scaleType,
      Value<int> totalScore,
      Value<String> severityLevel,
      Value<String> responsesJson,
      Value<String> administeredAt,
      Value<String?> administeredBy,
      Value<bool> requiresReview,
      Value<String?> notes,
    });

final class $$PsychometricEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PsychometricEntriesTable,
          PsychometricEntry
        > {
  $$PsychometricEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.psychometricEntries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PsychometricEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PsychometricEntriesTable> {
  $$PsychometricEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scaleType => $composableBuilder(
    column: $table.scaleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severityLevel => $composableBuilder(
    column: $table.severityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsesJson => $composableBuilder(
    column: $table.responsesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get administeredAt => $composableBuilder(
    column: $table.administeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresReview => $composableBuilder(
    column: $table.requiresReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PsychometricEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PsychometricEntriesTable> {
  $$PsychometricEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scaleType => $composableBuilder(
    column: $table.scaleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severityLevel => $composableBuilder(
    column: $table.severityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsesJson => $composableBuilder(
    column: $table.responsesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get administeredAt => $composableBuilder(
    column: $table.administeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresReview => $composableBuilder(
    column: $table.requiresReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PsychometricEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PsychometricEntriesTable> {
  $$PsychometricEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scaleType =>
      $composableBuilder(column: $table.scaleType, builder: (column) => column);

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severityLevel => $composableBuilder(
    column: $table.severityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responsesJson => $composableBuilder(
    column: $table.responsesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get administeredAt => $composableBuilder(
    column: $table.administeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get administeredBy => $composableBuilder(
    column: $table.administeredBy,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresReview => $composableBuilder(
    column: $table.requiresReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PsychometricEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PsychometricEntriesTable,
          PsychometricEntry,
          $$PsychometricEntriesTableFilterComposer,
          $$PsychometricEntriesTableOrderingComposer,
          $$PsychometricEntriesTableAnnotationComposer,
          $$PsychometricEntriesTableCreateCompanionBuilder,
          $$PsychometricEntriesTableUpdateCompanionBuilder,
          (PsychometricEntry, $$PsychometricEntriesTableReferences),
          PsychometricEntry,
          PrefetchHooks Function({bool patientId})
        > {
  $$PsychometricEntriesTableTableManager(
    _$AppDatabase db,
    $PsychometricEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PsychometricEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PsychometricEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PsychometricEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> scaleType = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<String> severityLevel = const Value.absent(),
                Value<String> responsesJson = const Value.absent(),
                Value<String> administeredAt = const Value.absent(),
                Value<String?> administeredBy = const Value.absent(),
                Value<bool> requiresReview = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PsychometricEntriesCompanion(
                id: id,
                patientId: patientId,
                scaleType: scaleType,
                totalScore: totalScore,
                severityLevel: severityLevel,
                responsesJson: responsesJson,
                administeredAt: administeredAt,
                administeredBy: administeredBy,
                requiresReview: requiresReview,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int patientId,
                required String scaleType,
                required int totalScore,
                required String severityLevel,
                required String responsesJson,
                required String administeredAt,
                Value<String?> administeredBy = const Value.absent(),
                Value<bool> requiresReview = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => PsychometricEntriesCompanion.insert(
                id: id,
                patientId: patientId,
                scaleType: scaleType,
                totalScore: totalScore,
                severityLevel: severityLevel,
                responsesJson: responsesJson,
                administeredAt: administeredAt,
                administeredBy: administeredBy,
                requiresReview: requiresReview,
                notes: notes,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$PsychometricEntriesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({patientId = false}) {
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
                  dynamic
                >
              >(state) {
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable:
                                $$PsychometricEntriesTableReferences
                                    ._patientIdTable(db),
                            referencedColumn:
                                $$PsychometricEntriesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PsychometricEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PsychometricEntriesTable,
      PsychometricEntry,
      $$PsychometricEntriesTableFilterComposer,
      $$PsychometricEntriesTableOrderingComposer,
      $$PsychometricEntriesTableAnnotationComposer,
      $$PsychometricEntriesTableCreateCompanionBuilder,
      $$PsychometricEntriesTableUpdateCompanionBuilder,
      (PsychometricEntry, $$PsychometricEntriesTableReferences),
      PsychometricEntry,
      PrefetchHooks Function({bool patientId})
    >;
typedef $$SessionSummariesTableCreateCompanionBuilder =
    SessionSummariesCompanion Function({
      Value<int> id,
      required int patientId,
      Value<String> sessionType,
      required String startedAt,
      Value<String?> endedAt,
      Value<int> durationSeconds,
      Value<int?> breathRate,
      Value<String?> breathSource,
      Value<double?> avgHeartRate,
      Value<int?> minHeartRate,
      Value<int?> maxHeartRate,
      Value<double?> rmssd,
      Value<double?> sdnn,
      Value<double?> meanNn,
      Value<double?> pnn50,
      Value<String?> hrReadingsJson,
      Value<String?> extendedMetricsJson,
    });
typedef $$SessionSummariesTableUpdateCompanionBuilder =
    SessionSummariesCompanion Function({
      Value<int> id,
      Value<int> patientId,
      Value<String> sessionType,
      Value<String> startedAt,
      Value<String?> endedAt,
      Value<int> durationSeconds,
      Value<int?> breathRate,
      Value<String?> breathSource,
      Value<double?> avgHeartRate,
      Value<int?> minHeartRate,
      Value<int?> maxHeartRate,
      Value<double?> rmssd,
      Value<double?> sdnn,
      Value<double?> meanNn,
      Value<double?> pnn50,
      Value<String?> hrReadingsJson,
      Value<String?> extendedMetricsJson,
    });

final class $$SessionSummariesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionSummariesTable, SessionSummary> {
  $$SessionSummariesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.sessionSummaries.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $RfAssessmentRecordsTable,
    List<RfAssessmentRecord>
  >
  _rfAssessmentRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rfAssessmentRecords,
        aliasName: $_aliasNameGenerator(
          db.sessionSummaries.id,
          db.rfAssessmentRecords.sessionSummaryId,
        ),
      );

  $$RfAssessmentRecordsTableProcessedTableManager get rfAssessmentRecordsRefs {
    final manager = $$RfAssessmentRecordsTableTableManager(
      $_db,
      $_db.rfAssessmentRecords,
    ).filter((f) => f.sessionSummaryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rfAssessmentRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSummariesTable> {
  $$SessionSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breathRate => $composableBuilder(
    column: $table.breathRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breathSource => $composableBuilder(
    column: $table.breathSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minHeartRate => $composableBuilder(
    column: $table.minHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanNn => $composableBuilder(
    column: $table.meanNn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pnn50 => $composableBuilder(
    column: $table.pnn50,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hrReadingsJson => $composableBuilder(
    column: $table.hrReadingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extendedMetricsJson => $composableBuilder(
    column: $table.extendedMetricsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rfAssessmentRecordsRefs(
    Expression<bool> Function($$RfAssessmentRecordsTableFilterComposer f) f,
  ) {
    final $$RfAssessmentRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rfAssessmentRecords,
      getReferencedColumn: (t) => t.sessionSummaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RfAssessmentRecordsTableFilterComposer(
            $db: $db,
            $table: $db.rfAssessmentRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSummariesTable> {
  $$SessionSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breathRate => $composableBuilder(
    column: $table.breathRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breathSource => $composableBuilder(
    column: $table.breathSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minHeartRate => $composableBuilder(
    column: $table.minHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sdnn => $composableBuilder(
    column: $table.sdnn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanNn => $composableBuilder(
    column: $table.meanNn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pnn50 => $composableBuilder(
    column: $table.pnn50,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hrReadingsJson => $composableBuilder(
    column: $table.hrReadingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extendedMetricsJson => $composableBuilder(
    column: $table.extendedMetricsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSummariesTable> {
  $$SessionSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breathRate => $composableBuilder(
    column: $table.breathRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get breathSource => $composableBuilder(
    column: $table.breathSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minHeartRate => $composableBuilder(
    column: $table.minHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rmssd =>
      $composableBuilder(column: $table.rmssd, builder: (column) => column);

  GeneratedColumn<double> get sdnn =>
      $composableBuilder(column: $table.sdnn, builder: (column) => column);

  GeneratedColumn<double> get meanNn =>
      $composableBuilder(column: $table.meanNn, builder: (column) => column);

  GeneratedColumn<double> get pnn50 =>
      $composableBuilder(column: $table.pnn50, builder: (column) => column);

  GeneratedColumn<String> get hrReadingsJson => $composableBuilder(
    column: $table.hrReadingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extendedMetricsJson => $composableBuilder(
    column: $table.extendedMetricsJson,
    builder: (column) => column,
  );

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rfAssessmentRecordsRefs<T extends Object>(
    Expression<T> Function($$RfAssessmentRecordsTableAnnotationComposer a) f,
  ) {
    final $$RfAssessmentRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.rfAssessmentRecords,
          getReferencedColumn: (t) => t.sessionSummaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RfAssessmentRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.rfAssessmentRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SessionSummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSummariesTable,
          SessionSummary,
          $$SessionSummariesTableFilterComposer,
          $$SessionSummariesTableOrderingComposer,
          $$SessionSummariesTableAnnotationComposer,
          $$SessionSummariesTableCreateCompanionBuilder,
          $$SessionSummariesTableUpdateCompanionBuilder,
          (SessionSummary, $$SessionSummariesTableReferences),
          SessionSummary,
          PrefetchHooks Function({bool patientId, bool rfAssessmentRecordsRefs})
        > {
  $$SessionSummariesTableTableManager(
    _$AppDatabase db,
    $SessionSummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$SessionSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SessionSummariesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SessionSummariesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int?> breathRate = const Value.absent(),
                Value<String?> breathSource = const Value.absent(),
                Value<double?> avgHeartRate = const Value.absent(),
                Value<int?> minHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                Value<double?> meanNn = const Value.absent(),
                Value<double?> pnn50 = const Value.absent(),
                Value<String?> hrReadingsJson = const Value.absent(),
                Value<String?> extendedMetricsJson = const Value.absent(),
              }) => SessionSummariesCompanion(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                breathRate: breathRate,
                breathSource: breathSource,
                avgHeartRate: avgHeartRate,
                minHeartRate: minHeartRate,
                maxHeartRate: maxHeartRate,
                rmssd: rmssd,
                sdnn: sdnn,
                meanNn: meanNn,
                pnn50: pnn50,
                hrReadingsJson: hrReadingsJson,
                extendedMetricsJson: extendedMetricsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int patientId,
                Value<String> sessionType = const Value.absent(),
                required String startedAt,
                Value<String?> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int?> breathRate = const Value.absent(),
                Value<String?> breathSource = const Value.absent(),
                Value<double?> avgHeartRate = const Value.absent(),
                Value<int?> minHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<double?> rmssd = const Value.absent(),
                Value<double?> sdnn = const Value.absent(),
                Value<double?> meanNn = const Value.absent(),
                Value<double?> pnn50 = const Value.absent(),
                Value<String?> hrReadingsJson = const Value.absent(),
                Value<String?> extendedMetricsJson = const Value.absent(),
              }) => SessionSummariesCompanion.insert(
                id: id,
                patientId: patientId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                breathRate: breathRate,
                breathSource: breathSource,
                avgHeartRate: avgHeartRate,
                minHeartRate: minHeartRate,
                maxHeartRate: maxHeartRate,
                rmssd: rmssd,
                sdnn: sdnn,
                meanNn: meanNn,
                pnn50: pnn50,
                hrReadingsJson: hrReadingsJson,
                extendedMetricsJson: extendedMetricsJson,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$SessionSummariesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            patientId = false,
            rfAssessmentRecordsRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (rfAssessmentRecordsRefs) db.rfAssessmentRecords,
              ],
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
                  dynamic
                >
              >(state) {
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable: $$SessionSummariesTableReferences
                                ._patientIdTable(db),
                            referencedColumn:
                                $$SessionSummariesTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (rfAssessmentRecordsRefs)
                    await $_getPrefetchedData<
                      SessionSummary,
                      $SessionSummariesTable,
                      RfAssessmentRecord
                    >(
                      currentTable: table,
                      referencedTable: $$SessionSummariesTableReferences
                          ._rfAssessmentRecordsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$SessionSummariesTableReferences(
                                db,
                                table,
                                p0,
                              ).rfAssessmentRecordsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.sessionSummaryId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionSummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSummariesTable,
      SessionSummary,
      $$SessionSummariesTableFilterComposer,
      $$SessionSummariesTableOrderingComposer,
      $$SessionSummariesTableAnnotationComposer,
      $$SessionSummariesTableCreateCompanionBuilder,
      $$SessionSummariesTableUpdateCompanionBuilder,
      (SessionSummary, $$SessionSummariesTableReferences),
      SessionSummary,
      PrefetchHooks Function({bool patientId, bool rfAssessmentRecordsRefs})
    >;
typedef $$RfAssessmentRecordsTableCreateCompanionBuilder =
    RfAssessmentRecordsCompanion Function({
      Value<int> id,
      required int patientId,
      Value<int?> sessionSummaryId,
      required String surface,
      required String protocolVersion,
      required String mode,
      required String status,
      required String startedAt,
      required String endedAt,
      required double durationMs,
      required int completedCycles,
      Value<double?> rfBpm,
      Value<double?> rfCenterElapsedMs,
      Value<double?> peakToTroughAmplitude,
      Value<double?> scheduledBpmAtCenter,
      Value<double?> fittedRespirationBpm,
      Value<double?> adherenceDeltaBpm,
      Value<double?> respirationFitError,
      required int ectopicCorrections,
      required bool qualityPassed,
      required String qualityFlagsJson,
      Value<bool> appliedToPatient,
      Value<bool?> estimateConfirmed,
      required String protocolJson,
      required String resultJson,
      required String rrSamplesJson,
      Value<String?> respirationSamplesJson,
      required String createdAt,
    });
typedef $$RfAssessmentRecordsTableUpdateCompanionBuilder =
    RfAssessmentRecordsCompanion Function({
      Value<int> id,
      Value<int> patientId,
      Value<int?> sessionSummaryId,
      Value<String> surface,
      Value<String> protocolVersion,
      Value<String> mode,
      Value<String> status,
      Value<String> startedAt,
      Value<String> endedAt,
      Value<double> durationMs,
      Value<int> completedCycles,
      Value<double?> rfBpm,
      Value<double?> rfCenterElapsedMs,
      Value<double?> peakToTroughAmplitude,
      Value<double?> scheduledBpmAtCenter,
      Value<double?> fittedRespirationBpm,
      Value<double?> adherenceDeltaBpm,
      Value<double?> respirationFitError,
      Value<int> ectopicCorrections,
      Value<bool> qualityPassed,
      Value<String> qualityFlagsJson,
      Value<bool> appliedToPatient,
      Value<bool?> estimateConfirmed,
      Value<String> protocolJson,
      Value<String> resultJson,
      Value<String> rrSamplesJson,
      Value<String?> respirationSamplesJson,
      Value<String> createdAt,
    });

final class $$RfAssessmentRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RfAssessmentRecordsTable,
          RfAssessmentRecord
        > {
  $$RfAssessmentRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatientsTable _patientIdTable(_$AppDatabase db) =>
      db.patients.createAlias(
        $_aliasNameGenerator(db.rfAssessmentRecords.patientId, db.patients.id),
      );

  $$PatientsTableProcessedTableManager get patientId {
    final $_column = $_itemColumn<int>('patient_id')!;

    final manager = $$PatientsTableTableManager(
      $_db,
      $_db.patients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SessionSummariesTable _sessionSummaryIdTable(_$AppDatabase db) =>
      db.sessionSummaries.createAlias(
        $_aliasNameGenerator(
          db.rfAssessmentRecords.sessionSummaryId,
          db.sessionSummaries.id,
        ),
      );

  $$SessionSummariesTableProcessedTableManager? get sessionSummaryId {
    final $_column = $_itemColumn<int>('session_summary_id');
    if ($_column == null) return null;
    final manager = $$SessionSummariesTableTableManager(
      $_db,
      $_db.sessionSummaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionSummaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RfAssessmentRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RfAssessmentRecordsTable> {
  $$RfAssessmentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedCycles => $composableBuilder(
    column: $table.completedCycles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rfBpm => $composableBuilder(
    column: $table.rfBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rfCenterElapsedMs => $composableBuilder(
    column: $table.rfCenterElapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get peakToTroughAmplitude => $composableBuilder(
    column: $table.peakToTroughAmplitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scheduledBpmAtCenter => $composableBuilder(
    column: $table.scheduledBpmAtCenter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fittedRespirationBpm => $composableBuilder(
    column: $table.fittedRespirationBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adherenceDeltaBpm => $composableBuilder(
    column: $table.adherenceDeltaBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get respirationFitError => $composableBuilder(
    column: $table.respirationFitError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ectopicCorrections => $composableBuilder(
    column: $table.ectopicCorrections,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get qualityPassed => $composableBuilder(
    column: $table.qualityPassed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityFlagsJson => $composableBuilder(
    column: $table.qualityFlagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appliedToPatient => $composableBuilder(
    column: $table.appliedToPatient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estimateConfirmed => $composableBuilder(
    column: $table.estimateConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrSamplesJson => $composableBuilder(
    column: $table.rrSamplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get respirationSamplesJson => $composableBuilder(
    column: $table.respirationSamplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatientsTableFilterComposer get patientId {
    final $$PatientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableFilterComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionSummariesTableFilterComposer get sessionSummaryId {
    final $$SessionSummariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionSummaryId,
      referencedTable: $db.sessionSummaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSummariesTableFilterComposer(
            $db: $db,
            $table: $db.sessionSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RfAssessmentRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RfAssessmentRecordsTable> {
  $$RfAssessmentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surface => $composableBuilder(
    column: $table.surface,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedCycles => $composableBuilder(
    column: $table.completedCycles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rfBpm => $composableBuilder(
    column: $table.rfBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rfCenterElapsedMs => $composableBuilder(
    column: $table.rfCenterElapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get peakToTroughAmplitude => $composableBuilder(
    column: $table.peakToTroughAmplitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scheduledBpmAtCenter => $composableBuilder(
    column: $table.scheduledBpmAtCenter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fittedRespirationBpm => $composableBuilder(
    column: $table.fittedRespirationBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adherenceDeltaBpm => $composableBuilder(
    column: $table.adherenceDeltaBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get respirationFitError => $composableBuilder(
    column: $table.respirationFitError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ectopicCorrections => $composableBuilder(
    column: $table.ectopicCorrections,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get qualityPassed => $composableBuilder(
    column: $table.qualityPassed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityFlagsJson => $composableBuilder(
    column: $table.qualityFlagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appliedToPatient => $composableBuilder(
    column: $table.appliedToPatient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estimateConfirmed => $composableBuilder(
    column: $table.estimateConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrSamplesJson => $composableBuilder(
    column: $table.rrSamplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get respirationSamplesJson => $composableBuilder(
    column: $table.respirationSamplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatientsTableOrderingComposer get patientId {
    final $$PatientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableOrderingComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionSummariesTableOrderingComposer get sessionSummaryId {
    final $$SessionSummariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionSummaryId,
      referencedTable: $db.sessionSummaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSummariesTableOrderingComposer(
            $db: $db,
            $table: $db.sessionSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RfAssessmentRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RfAssessmentRecordsTable> {
  $$RfAssessmentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedCycles => $composableBuilder(
    column: $table.completedCycles,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rfBpm =>
      $composableBuilder(column: $table.rfBpm, builder: (column) => column);

  GeneratedColumn<double> get rfCenterElapsedMs => $composableBuilder(
    column: $table.rfCenterElapsedMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get peakToTroughAmplitude => $composableBuilder(
    column: $table.peakToTroughAmplitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scheduledBpmAtCenter => $composableBuilder(
    column: $table.scheduledBpmAtCenter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fittedRespirationBpm => $composableBuilder(
    column: $table.fittedRespirationBpm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get adherenceDeltaBpm => $composableBuilder(
    column: $table.adherenceDeltaBpm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get respirationFitError => $composableBuilder(
    column: $table.respirationFitError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ectopicCorrections => $composableBuilder(
    column: $table.ectopicCorrections,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get qualityPassed => $composableBuilder(
    column: $table.qualityPassed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityFlagsJson => $composableBuilder(
    column: $table.qualityFlagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appliedToPatient => $composableBuilder(
    column: $table.appliedToPatient,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estimateConfirmed => $composableBuilder(
    column: $table.estimateConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocolJson => $composableBuilder(
    column: $table.protocolJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrSamplesJson => $composableBuilder(
    column: $table.rrSamplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get respirationSamplesJson => $composableBuilder(
    column: $table.respirationSamplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PatientsTableAnnotationComposer get patientId {
    final $$PatientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.patients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatientsTableAnnotationComposer(
            $db: $db,
            $table: $db.patients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionSummariesTableAnnotationComposer get sessionSummaryId {
    final $$SessionSummariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionSummaryId,
      referencedTable: $db.sessionSummaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSummariesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RfAssessmentRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RfAssessmentRecordsTable,
          RfAssessmentRecord,
          $$RfAssessmentRecordsTableFilterComposer,
          $$RfAssessmentRecordsTableOrderingComposer,
          $$RfAssessmentRecordsTableAnnotationComposer,
          $$RfAssessmentRecordsTableCreateCompanionBuilder,
          $$RfAssessmentRecordsTableUpdateCompanionBuilder,
          (RfAssessmentRecord, $$RfAssessmentRecordsTableReferences),
          RfAssessmentRecord,
          PrefetchHooks Function({bool patientId, bool sessionSummaryId})
        > {
  $$RfAssessmentRecordsTableTableManager(
    _$AppDatabase db,
    $RfAssessmentRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RfAssessmentRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$RfAssessmentRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$RfAssessmentRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> patientId = const Value.absent(),
                Value<int?> sessionSummaryId = const Value.absent(),
                Value<String> surface = const Value.absent(),
                Value<String> protocolVersion = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String> endedAt = const Value.absent(),
                Value<double> durationMs = const Value.absent(),
                Value<int> completedCycles = const Value.absent(),
                Value<double?> rfBpm = const Value.absent(),
                Value<double?> rfCenterElapsedMs = const Value.absent(),
                Value<double?> peakToTroughAmplitude = const Value.absent(),
                Value<double?> scheduledBpmAtCenter = const Value.absent(),
                Value<double?> fittedRespirationBpm = const Value.absent(),
                Value<double?> adherenceDeltaBpm = const Value.absent(),
                Value<double?> respirationFitError = const Value.absent(),
                Value<int> ectopicCorrections = const Value.absent(),
                Value<bool> qualityPassed = const Value.absent(),
                Value<String> qualityFlagsJson = const Value.absent(),
                Value<bool> appliedToPatient = const Value.absent(),
                Value<bool?> estimateConfirmed = const Value.absent(),
                Value<String> protocolJson = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<String> rrSamplesJson = const Value.absent(),
                Value<String?> respirationSamplesJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => RfAssessmentRecordsCompanion(
                id: id,
                patientId: patientId,
                sessionSummaryId: sessionSummaryId,
                surface: surface,
                protocolVersion: protocolVersion,
                mode: mode,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMs: durationMs,
                completedCycles: completedCycles,
                rfBpm: rfBpm,
                rfCenterElapsedMs: rfCenterElapsedMs,
                peakToTroughAmplitude: peakToTroughAmplitude,
                scheduledBpmAtCenter: scheduledBpmAtCenter,
                fittedRespirationBpm: fittedRespirationBpm,
                adherenceDeltaBpm: adherenceDeltaBpm,
                respirationFitError: respirationFitError,
                ectopicCorrections: ectopicCorrections,
                qualityPassed: qualityPassed,
                qualityFlagsJson: qualityFlagsJson,
                appliedToPatient: appliedToPatient,
                estimateConfirmed: estimateConfirmed,
                protocolJson: protocolJson,
                resultJson: resultJson,
                rrSamplesJson: rrSamplesJson,
                respirationSamplesJson: respirationSamplesJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int patientId,
                Value<int?> sessionSummaryId = const Value.absent(),
                required String surface,
                required String protocolVersion,
                required String mode,
                required String status,
                required String startedAt,
                required String endedAt,
                required double durationMs,
                required int completedCycles,
                Value<double?> rfBpm = const Value.absent(),
                Value<double?> rfCenterElapsedMs = const Value.absent(),
                Value<double?> peakToTroughAmplitude = const Value.absent(),
                Value<double?> scheduledBpmAtCenter = const Value.absent(),
                Value<double?> fittedRespirationBpm = const Value.absent(),
                Value<double?> adherenceDeltaBpm = const Value.absent(),
                Value<double?> respirationFitError = const Value.absent(),
                required int ectopicCorrections,
                required bool qualityPassed,
                required String qualityFlagsJson,
                Value<bool> appliedToPatient = const Value.absent(),
                Value<bool?> estimateConfirmed = const Value.absent(),
                required String protocolJson,
                required String resultJson,
                required String rrSamplesJson,
                Value<String?> respirationSamplesJson = const Value.absent(),
                required String createdAt,
              }) => RfAssessmentRecordsCompanion.insert(
                id: id,
                patientId: patientId,
                sessionSummaryId: sessionSummaryId,
                surface: surface,
                protocolVersion: protocolVersion,
                mode: mode,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMs: durationMs,
                completedCycles: completedCycles,
                rfBpm: rfBpm,
                rfCenterElapsedMs: rfCenterElapsedMs,
                peakToTroughAmplitude: peakToTroughAmplitude,
                scheduledBpmAtCenter: scheduledBpmAtCenter,
                fittedRespirationBpm: fittedRespirationBpm,
                adherenceDeltaBpm: adherenceDeltaBpm,
                respirationFitError: respirationFitError,
                ectopicCorrections: ectopicCorrections,
                qualityPassed: qualityPassed,
                qualityFlagsJson: qualityFlagsJson,
                appliedToPatient: appliedToPatient,
                estimateConfirmed: estimateConfirmed,
                protocolJson: protocolJson,
                resultJson: resultJson,
                rrSamplesJson: rrSamplesJson,
                respirationSamplesJson: respirationSamplesJson,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$RfAssessmentRecordsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            patientId = false,
            sessionSummaryId = false,
          }) {
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
                  dynamic
                >
              >(state) {
                if (patientId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.patientId,
                            referencedTable:
                                $$RfAssessmentRecordsTableReferences
                                    ._patientIdTable(db),
                            referencedColumn:
                                $$RfAssessmentRecordsTableReferences
                                    ._patientIdTable(db)
                                    .id,
                          )
                          as T;
                }
                if (sessionSummaryId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionSummaryId,
                            referencedTable:
                                $$RfAssessmentRecordsTableReferences
                                    ._sessionSummaryIdTable(db),
                            referencedColumn:
                                $$RfAssessmentRecordsTableReferences
                                    ._sessionSummaryIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RfAssessmentRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RfAssessmentRecordsTable,
      RfAssessmentRecord,
      $$RfAssessmentRecordsTableFilterComposer,
      $$RfAssessmentRecordsTableOrderingComposer,
      $$RfAssessmentRecordsTableAnnotationComposer,
      $$RfAssessmentRecordsTableCreateCompanionBuilder,
      $$RfAssessmentRecordsTableUpdateCompanionBuilder,
      (RfAssessmentRecord, $$RfAssessmentRecordsTableReferences),
      RfAssessmentRecord,
      PrefetchHooks Function({bool patientId, bool sessionSummaryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$BreathRateEntriesTableTableManager get breathRateEntries =>
      $$BreathRateEntriesTableTableManager(_db, _db.breathRateEntries);
  $$HeartRateEntriesTableTableManager get heartRateEntries =>
      $$HeartRateEntriesTableTableManager(_db, _db.heartRateEntries);
  $$EcgSampleEntriesTableTableManager get ecgSampleEntries =>
      $$EcgSampleEntriesTableTableManager(_db, _db.ecgSampleEntries);
  $$HrvEntriesTableTableManager get hrvEntries =>
      $$HrvEntriesTableTableManager(_db, _db.hrvEntries);
  $$PsychometricEntriesTableTableManager get psychometricEntries =>
      $$PsychometricEntriesTableTableManager(_db, _db.psychometricEntries);
  $$SessionSummariesTableTableManager get sessionSummaries =>
      $$SessionSummariesTableTableManager(_db, _db.sessionSummaries);
  $$RfAssessmentRecordsTableTableManager get rfAssessmentRecords =>
      $$RfAssessmentRecordsTableTableManager(_db, _db.rfAssessmentRecords);
}
