// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BackupData _$BackupDataFromJson(Map<String, dynamic> json) {
  return _BackupData.fromJson(json);
}

/// @nodoc
mixin _$BackupData {
  BackupMetadata get metadata => throw _privateConstructorUsedError;
  Map<String, dynamic> get sharedPreferences =>
      throw _privateConstructorUsedError;
  List<DatabaseFile> get databases => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BackupDataCopyWith<BackupData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupDataCopyWith<$Res> {
  factory $BackupDataCopyWith(
          BackupData value, $Res Function(BackupData) then) =
      _$BackupDataCopyWithImpl<$Res, BackupData>;
  @useResult
  $Res call(
      {BackupMetadata metadata,
      Map<String, dynamic> sharedPreferences,
      List<DatabaseFile> databases});

  $BackupMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$BackupDataCopyWithImpl<$Res, $Val extends BackupData>
    implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? sharedPreferences = null,
    Object? databases = null,
  }) {
    return _then(_value.copyWith(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      sharedPreferences: null == sharedPreferences
          ? _value.sharedPreferences
          : sharedPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      databases: null == databases
          ? _value.databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<DatabaseFile>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BackupDataImplCopyWith<$Res>
    implements $BackupDataCopyWith<$Res> {
  factory _$$BackupDataImplCopyWith(
          _$BackupDataImpl value, $Res Function(_$BackupDataImpl) then) =
      __$$BackupDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {BackupMetadata metadata,
      Map<String, dynamic> sharedPreferences,
      List<DatabaseFile> databases});

  @override
  $BackupMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$$BackupDataImplCopyWithImpl<$Res>
    extends _$BackupDataCopyWithImpl<$Res, _$BackupDataImpl>
    implements _$$BackupDataImplCopyWith<$Res> {
  __$$BackupDataImplCopyWithImpl(
      _$BackupDataImpl _value, $Res Function(_$BackupDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? sharedPreferences = null,
    Object? databases = null,
  }) {
    return _then(_$BackupDataImpl(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      sharedPreferences: null == sharedPreferences
          ? _value._sharedPreferences
          : sharedPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      databases: null == databases
          ? _value._databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<DatabaseFile>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupDataImpl implements _BackupData {
  const _$BackupDataImpl(
      {required this.metadata,
      required final Map<String, dynamic> sharedPreferences,
      required final List<DatabaseFile> databases})
      : _sharedPreferences = sharedPreferences,
        _databases = databases;

  factory _$BackupDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupDataImplFromJson(json);

  @override
  final BackupMetadata metadata;
  final Map<String, dynamic> _sharedPreferences;
  @override
  Map<String, dynamic> get sharedPreferences {
    if (_sharedPreferences is EqualUnmodifiableMapView)
      return _sharedPreferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sharedPreferences);
  }

  final List<DatabaseFile> _databases;
  @override
  List<DatabaseFile> get databases {
    if (_databases is EqualUnmodifiableListView) return _databases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_databases);
  }

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, sharedPreferences: $sharedPreferences, databases: $databases)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupDataImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other._sharedPreferences, _sharedPreferences) &&
            const DeepCollectionEquality()
                .equals(other._databases, _databases));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      metadata,
      const DeepCollectionEquality().hash(_sharedPreferences),
      const DeepCollectionEquality().hash(_databases));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupDataImplCopyWith<_$BackupDataImpl> get copyWith =>
      __$$BackupDataImplCopyWithImpl<_$BackupDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupDataImplToJson(
      this,
    );
  }
}

abstract class _BackupData implements BackupData {
  const factory _BackupData(
      {required final BackupMetadata metadata,
      required final Map<String, dynamic> sharedPreferences,
      required final List<DatabaseFile> databases}) = _$BackupDataImpl;

  factory _BackupData.fromJson(Map<String, dynamic> json) =
      _$BackupDataImpl.fromJson;

  @override
  BackupMetadata get metadata;
  @override
  Map<String, dynamic> get sharedPreferences;
  @override
  List<DatabaseFile> get databases;
  @override
  @JsonKey(ignore: true)
  _$$BackupDataImplCopyWith<_$BackupDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) {
  return _BackupMetadata.fromJson(json);
}

/// @nodoc
mixin _$BackupMetadata {
  String get appVersion => throw _privateConstructorUsedError;
  String get buildNumber => throw _privateConstructorUsedError;
  int get timestamp => throw _privateConstructorUsedError;
  String get platform => throw _privateConstructorUsedError;
  int get backupCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BackupMetadataCopyWith<BackupMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupMetadataCopyWith<$Res> {
  factory $BackupMetadataCopyWith(
          BackupMetadata value, $Res Function(BackupMetadata) then) =
      _$BackupMetadataCopyWithImpl<$Res, BackupMetadata>;
  @useResult
  $Res call(
      {String appVersion,
      String buildNumber,
      int timestamp,
      String platform,
      int backupCode});
}

/// @nodoc
class _$BackupMetadataCopyWithImpl<$Res, $Val extends BackupMetadata>
    implements $BackupMetadataCopyWith<$Res> {
  _$BackupMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appVersion = null,
    Object? buildNumber = null,
    Object? timestamp = null,
    Object? platform = null,
    Object? backupCode = null,
  }) {
    return _then(_value.copyWith(
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      backupCode: null == backupCode
          ? _value.backupCode
          : backupCode // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupMetadataImplCopyWith<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  factory _$$BackupMetadataImplCopyWith(_$BackupMetadataImpl value,
          $Res Function(_$BackupMetadataImpl) then) =
      __$$BackupMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String appVersion,
      String buildNumber,
      int timestamp,
      String platform,
      int backupCode});
}

/// @nodoc
class __$$BackupMetadataImplCopyWithImpl<$Res>
    extends _$BackupMetadataCopyWithImpl<$Res, _$BackupMetadataImpl>
    implements _$$BackupMetadataImplCopyWith<$Res> {
  __$$BackupMetadataImplCopyWithImpl(
      _$BackupMetadataImpl _value, $Res Function(_$BackupMetadataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appVersion = null,
    Object? buildNumber = null,
    Object? timestamp = null,
    Object? platform = null,
    Object? backupCode = null,
  }) {
    return _then(_$BackupMetadataImpl(
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _value.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      backupCode: null == backupCode
          ? _value.backupCode
          : backupCode // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupMetadataImpl implements _BackupMetadata {
  const _$BackupMetadataImpl(
      {required this.appVersion,
      required this.buildNumber,
      required this.timestamp,
      required this.platform,
      required this.backupCode});

  factory _$BackupMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupMetadataImplFromJson(json);

  @override
  final String appVersion;
  @override
  final String buildNumber;
  @override
  final int timestamp;
  @override
  final String platform;
  @override
  final int backupCode;

  @override
  String toString() {
    return 'BackupMetadata(appVersion: $appVersion, buildNumber: $buildNumber, timestamp: $timestamp, platform: $platform, backupCode: $backupCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupMetadataImpl &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.buildNumber, buildNumber) ||
                other.buildNumber == buildNumber) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.backupCode, backupCode) ||
                other.backupCode == backupCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, appVersion, buildNumber, timestamp, platform, backupCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupMetadataImplCopyWith<_$BackupMetadataImpl> get copyWith =>
      __$$BackupMetadataImplCopyWithImpl<_$BackupMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupMetadataImplToJson(
      this,
    );
  }
}

abstract class _BackupMetadata implements BackupMetadata {
  const factory _BackupMetadata(
      {required final String appVersion,
      required final String buildNumber,
      required final int timestamp,
      required final String platform,
      required final int backupCode}) = _$BackupMetadataImpl;

  factory _BackupMetadata.fromJson(Map<String, dynamic> json) =
      _$BackupMetadataImpl.fromJson;

  @override
  String get appVersion;
  @override
  String get buildNumber;
  @override
  int get timestamp;
  @override
  String get platform;
  @override
  int get backupCode;
  @override
  @JsonKey(ignore: true)
  _$$BackupMetadataImplCopyWith<_$BackupMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DatabaseFile _$DatabaseFileFromJson(Map<String, dynamic> json) {
  return _DatabaseFile.fromJson(json);
}

/// @nodoc
mixin _$DatabaseFile {
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  String get checksum => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DatabaseFileCopyWith<DatabaseFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DatabaseFileCopyWith<$Res> {
  factory $DatabaseFileCopyWith(
          DatabaseFile value, $Res Function(DatabaseFile) then) =
      _$DatabaseFileCopyWithImpl<$Res, DatabaseFile>;
  @useResult
  $Res call({String name, String relativePath, int size, String checksum});
}

/// @nodoc
class _$DatabaseFileCopyWithImpl<$Res, $Val extends DatabaseFile>
    implements $DatabaseFileCopyWith<$Res> {
  _$DatabaseFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? size = null,
    Object? checksum = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DatabaseFileImplCopyWith<$Res>
    implements $DatabaseFileCopyWith<$Res> {
  factory _$$DatabaseFileImplCopyWith(
          _$DatabaseFileImpl value, $Res Function(_$DatabaseFileImpl) then) =
      __$$DatabaseFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String relativePath, int size, String checksum});
}

/// @nodoc
class __$$DatabaseFileImplCopyWithImpl<$Res>
    extends _$DatabaseFileCopyWithImpl<$Res, _$DatabaseFileImpl>
    implements _$$DatabaseFileImplCopyWith<$Res> {
  __$$DatabaseFileImplCopyWithImpl(
      _$DatabaseFileImpl _value, $Res Function(_$DatabaseFileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? size = null,
    Object? checksum = null,
  }) {
    return _then(_$DatabaseFileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DatabaseFileImpl implements _DatabaseFile {
  const _$DatabaseFileImpl(
      {required this.name,
      required this.relativePath,
      required this.size,
      required this.checksum});

  factory _$DatabaseFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DatabaseFileImplFromJson(json);

  @override
  final String name;
  @override
  final String relativePath;
  @override
  final int size;
  @override
  final String checksum;

  @override
  String toString() {
    return 'DatabaseFile(name: $name, relativePath: $relativePath, size: $size, checksum: $checksum)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DatabaseFileImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, relativePath, size, checksum);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DatabaseFileImplCopyWith<_$DatabaseFileImpl> get copyWith =>
      __$$DatabaseFileImplCopyWithImpl<_$DatabaseFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DatabaseFileImplToJson(
      this,
    );
  }
}

abstract class _DatabaseFile implements DatabaseFile {
  const factory _DatabaseFile(
      {required final String name,
      required final String relativePath,
      required final int size,
      required final String checksum}) = _$DatabaseFileImpl;

  factory _DatabaseFile.fromJson(Map<String, dynamic> json) =
      _$DatabaseFileImpl.fromJson;

  @override
  String get name;
  @override
  String get relativePath;
  @override
  int get size;
  @override
  String get checksum;
  @override
  @JsonKey(ignore: true)
  _$$DatabaseFileImplCopyWith<_$DatabaseFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackupState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isExporting => throw _privateConstructorUsedError;
  bool get isImporting => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  String? get currentOperation => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get lastExportPath => throw _privateConstructorUsedError;
  BackupMetadata? get lastImportMetadata => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackupStateCopyWith<BackupState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupStateCopyWith<$Res> {
  factory $BackupStateCopyWith(
          BackupState value, $Res Function(BackupState) then) =
      _$BackupStateCopyWithImpl<$Res, BackupState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isExporting,
      bool isImporting,
      double progress,
      String? currentOperation,
      String? error,
      String? lastExportPath,
      BackupMetadata? lastImportMetadata});

  $BackupMetadataCopyWith<$Res>? get lastImportMetadata;
}

/// @nodoc
class _$BackupStateCopyWithImpl<$Res, $Val extends BackupState>
    implements $BackupStateCopyWith<$Res> {
  _$BackupStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isExporting = null,
    Object? isImporting = null,
    Object? progress = null,
    Object? currentOperation = freezed,
    Object? error = freezed,
    Object? lastExportPath = freezed,
    Object? lastImportMetadata = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExporting: null == isExporting
          ? _value.isExporting
          : isExporting // ignore: cast_nullable_to_non_nullable
              as bool,
      isImporting: null == isImporting
          ? _value.isImporting
          : isImporting // ignore: cast_nullable_to_non_nullable
              as bool,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentOperation: freezed == currentOperation
          ? _value.currentOperation
          : currentOperation // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastExportPath: freezed == lastExportPath
          ? _value.lastExportPath
          : lastExportPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastImportMetadata: freezed == lastImportMetadata
          ? _value.lastImportMetadata
          : lastImportMetadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get lastImportMetadata {
    if (_value.lastImportMetadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_value.lastImportMetadata!, (value) {
      return _then(_value.copyWith(lastImportMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BackupStateImplCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory _$$BackupStateImplCopyWith(
          _$BackupStateImpl value, $Res Function(_$BackupStateImpl) then) =
      __$$BackupStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isExporting,
      bool isImporting,
      double progress,
      String? currentOperation,
      String? error,
      String? lastExportPath,
      BackupMetadata? lastImportMetadata});

  @override
  $BackupMetadataCopyWith<$Res>? get lastImportMetadata;
}

/// @nodoc
class __$$BackupStateImplCopyWithImpl<$Res>
    extends _$BackupStateCopyWithImpl<$Res, _$BackupStateImpl>
    implements _$$BackupStateImplCopyWith<$Res> {
  __$$BackupStateImplCopyWithImpl(
      _$BackupStateImpl _value, $Res Function(_$BackupStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isExporting = null,
    Object? isImporting = null,
    Object? progress = null,
    Object? currentOperation = freezed,
    Object? error = freezed,
    Object? lastExportPath = freezed,
    Object? lastImportMetadata = freezed,
  }) {
    return _then(_$BackupStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExporting: null == isExporting
          ? _value.isExporting
          : isExporting // ignore: cast_nullable_to_non_nullable
              as bool,
      isImporting: null == isImporting
          ? _value.isImporting
          : isImporting // ignore: cast_nullable_to_non_nullable
              as bool,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentOperation: freezed == currentOperation
          ? _value.currentOperation
          : currentOperation // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastExportPath: freezed == lastExportPath
          ? _value.lastExportPath
          : lastExportPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastImportMetadata: freezed == lastImportMetadata
          ? _value.lastImportMetadata
          : lastImportMetadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
    ));
  }
}

/// @nodoc

class _$BackupStateImpl implements _BackupState {
  const _$BackupStateImpl(
      {this.isLoading = false,
      this.isExporting = false,
      this.isImporting = false,
      this.progress = 0.0,
      this.currentOperation,
      this.error,
      this.lastExportPath,
      this.lastImportMetadata});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isExporting;
  @override
  @JsonKey()
  final bool isImporting;
  @override
  @JsonKey()
  final double progress;
  @override
  final String? currentOperation;
  @override
  final String? error;
  @override
  final String? lastExportPath;
  @override
  final BackupMetadata? lastImportMetadata;

  @override
  String toString() {
    return 'BackupState(isLoading: $isLoading, isExporting: $isExporting, isImporting: $isImporting, progress: $progress, currentOperation: $currentOperation, error: $error, lastExportPath: $lastExportPath, lastImportMetadata: $lastImportMetadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isExporting, isExporting) ||
                other.isExporting == isExporting) &&
            (identical(other.isImporting, isImporting) ||
                other.isImporting == isImporting) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.currentOperation, currentOperation) ||
                other.currentOperation == currentOperation) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastExportPath, lastExportPath) ||
                other.lastExportPath == lastExportPath) &&
            (identical(other.lastImportMetadata, lastImportMetadata) ||
                other.lastImportMetadata == lastImportMetadata));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isExporting,
      isImporting,
      progress,
      currentOperation,
      error,
      lastExportPath,
      lastImportMetadata);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupStateImplCopyWith<_$BackupStateImpl> get copyWith =>
      __$$BackupStateImplCopyWithImpl<_$BackupStateImpl>(this, _$identity);
}

abstract class _BackupState implements BackupState {
  const factory _BackupState(
      {final bool isLoading,
      final bool isExporting,
      final bool isImporting,
      final double progress,
      final String? currentOperation,
      final String? error,
      final String? lastExportPath,
      final BackupMetadata? lastImportMetadata}) = _$BackupStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isExporting;
  @override
  bool get isImporting;
  @override
  double get progress;
  @override
  String? get currentOperation;
  @override
  String? get error;
  @override
  String? get lastExportPath;
  @override
  BackupMetadata? get lastImportMetadata;
  @override
  @JsonKey(ignore: true)
  _$$BackupStateImplCopyWith<_$BackupStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CompatibilityInfo {
  CompatibilityLevel get level => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  List<String>? get warnings => throw _privateConstructorUsedError;
  List<String>? get errors => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CompatibilityInfoCopyWith<CompatibilityInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityInfoCopyWith<$Res> {
  factory $CompatibilityInfoCopyWith(
          CompatibilityInfo value, $Res Function(CompatibilityInfo) then) =
      _$CompatibilityInfoCopyWithImpl<$Res, CompatibilityInfo>;
  @useResult
  $Res call(
      {CompatibilityLevel level,
      String message,
      List<String>? warnings,
      List<String>? errors});
}

/// @nodoc
class _$CompatibilityInfoCopyWithImpl<$Res, $Val extends CompatibilityInfo>
    implements $CompatibilityInfoCopyWith<$Res> {
  _$CompatibilityInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? message = null,
    Object? warnings = freezed,
    Object? errors = freezed,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      warnings: freezed == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      errors: freezed == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompatibilityInfoImplCopyWith<$Res>
    implements $CompatibilityInfoCopyWith<$Res> {
  factory _$$CompatibilityInfoImplCopyWith(_$CompatibilityInfoImpl value,
          $Res Function(_$CompatibilityInfoImpl) then) =
      __$$CompatibilityInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CompatibilityLevel level,
      String message,
      List<String>? warnings,
      List<String>? errors});
}

/// @nodoc
class __$$CompatibilityInfoImplCopyWithImpl<$Res>
    extends _$CompatibilityInfoCopyWithImpl<$Res, _$CompatibilityInfoImpl>
    implements _$$CompatibilityInfoImplCopyWith<$Res> {
  __$$CompatibilityInfoImplCopyWithImpl(_$CompatibilityInfoImpl _value,
      $Res Function(_$CompatibilityInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? message = null,
    Object? warnings = freezed,
    Object? errors = freezed,
  }) {
    return _then(_$CompatibilityInfoImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      warnings: freezed == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      errors: freezed == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc

class _$CompatibilityInfoImpl implements _CompatibilityInfo {
  const _$CompatibilityInfoImpl(
      {required this.level,
      required this.message,
      final List<String>? warnings,
      final List<String>? errors})
      : _warnings = warnings,
        _errors = errors;

  @override
  final CompatibilityLevel level;
  @override
  final String message;
  final List<String>? _warnings;
  @override
  List<String>? get warnings {
    final value = _warnings;
    if (value == null) return null;
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _errors;
  @override
  List<String>? get errors {
    final value = _errors;
    if (value == null) return null;
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CompatibilityInfo(level: $level, message: $message, warnings: $warnings, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityInfoImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      message,
      const DeepCollectionEquality().hash(_warnings),
      const DeepCollectionEquality().hash(_errors));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityInfoImplCopyWith<_$CompatibilityInfoImpl> get copyWith =>
      __$$CompatibilityInfoImplCopyWithImpl<_$CompatibilityInfoImpl>(
          this, _$identity);
}

abstract class _CompatibilityInfo implements CompatibilityInfo {
  const factory _CompatibilityInfo(
      {required final CompatibilityLevel level,
      required final String message,
      final List<String>? warnings,
      final List<String>? errors}) = _$CompatibilityInfoImpl;

  @override
  CompatibilityLevel get level;
  @override
  String get message;
  @override
  List<String>? get warnings;
  @override
  List<String>? get errors;
  @override
  @JsonKey(ignore: true)
  _$$CompatibilityInfoImplCopyWith<_$CompatibilityInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ImportOptions {
  bool get importSharedPreferences => throw _privateConstructorUsedError;
  bool get importDatabases => throw _privateConstructorUsedError;
  bool get createBackup => throw _privateConstructorUsedError;
  bool get forceImport => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ImportOptionsCopyWith<ImportOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportOptionsCopyWith<$Res> {
  factory $ImportOptionsCopyWith(
          ImportOptions value, $Res Function(ImportOptions) then) =
      _$ImportOptionsCopyWithImpl<$Res, ImportOptions>;
  @useResult
  $Res call(
      {bool importSharedPreferences,
      bool importDatabases,
      bool createBackup,
      bool forceImport});
}

/// @nodoc
class _$ImportOptionsCopyWithImpl<$Res, $Val extends ImportOptions>
    implements $ImportOptionsCopyWith<$Res> {
  _$ImportOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? importSharedPreferences = null,
    Object? importDatabases = null,
    Object? createBackup = null,
    Object? forceImport = null,
  }) {
    return _then(_value.copyWith(
      importSharedPreferences: null == importSharedPreferences
          ? _value.importSharedPreferences
          : importSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      importDatabases: null == importDatabases
          ? _value.importDatabases
          : importDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _value.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      forceImport: null == forceImport
          ? _value.forceImport
          : forceImport // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportOptionsImplCopyWith<$Res>
    implements $ImportOptionsCopyWith<$Res> {
  factory _$$ImportOptionsImplCopyWith(
          _$ImportOptionsImpl value, $Res Function(_$ImportOptionsImpl) then) =
      __$$ImportOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool importSharedPreferences,
      bool importDatabases,
      bool createBackup,
      bool forceImport});
}

/// @nodoc
class __$$ImportOptionsImplCopyWithImpl<$Res>
    extends _$ImportOptionsCopyWithImpl<$Res, _$ImportOptionsImpl>
    implements _$$ImportOptionsImplCopyWith<$Res> {
  __$$ImportOptionsImplCopyWithImpl(
      _$ImportOptionsImpl _value, $Res Function(_$ImportOptionsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? importSharedPreferences = null,
    Object? importDatabases = null,
    Object? createBackup = null,
    Object? forceImport = null,
  }) {
    return _then(_$ImportOptionsImpl(
      importSharedPreferences: null == importSharedPreferences
          ? _value.importSharedPreferences
          : importSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      importDatabases: null == importDatabases
          ? _value.importDatabases
          : importDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _value.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      forceImport: null == forceImport
          ? _value.forceImport
          : forceImport // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ImportOptionsImpl implements _ImportOptions {
  const _$ImportOptionsImpl(
      {this.importSharedPreferences = true,
      this.importDatabases = true,
      this.createBackup = true,
      this.forceImport = false});

  @override
  @JsonKey()
  final bool importSharedPreferences;
  @override
  @JsonKey()
  final bool importDatabases;
  @override
  @JsonKey()
  final bool createBackup;
  @override
  @JsonKey()
  final bool forceImport;

  @override
  String toString() {
    return 'ImportOptions(importSharedPreferences: $importSharedPreferences, importDatabases: $importDatabases, createBackup: $createBackup, forceImport: $forceImport)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportOptionsImpl &&
            (identical(
                    other.importSharedPreferences, importSharedPreferences) ||
                other.importSharedPreferences == importSharedPreferences) &&
            (identical(other.importDatabases, importDatabases) ||
                other.importDatabases == importDatabases) &&
            (identical(other.createBackup, createBackup) ||
                other.createBackup == createBackup) &&
            (identical(other.forceImport, forceImport) ||
                other.forceImport == forceImport));
  }

  @override
  int get hashCode => Object.hash(runtimeType, importSharedPreferences,
      importDatabases, createBackup, forceImport);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportOptionsImplCopyWith<_$ImportOptionsImpl> get copyWith =>
      __$$ImportOptionsImplCopyWithImpl<_$ImportOptionsImpl>(this, _$identity);
}

abstract class _ImportOptions implements ImportOptions {
  const factory _ImportOptions(
      {final bool importSharedPreferences,
      final bool importDatabases,
      final bool createBackup,
      final bool forceImport}) = _$ImportOptionsImpl;

  @override
  bool get importSharedPreferences;
  @override
  bool get importDatabases;
  @override
  bool get createBackup;
  @override
  bool get forceImport;
  @override
  @JsonKey(ignore: true)
  _$$ImportOptionsImplCopyWith<_$ImportOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RestoreOptions {
  bool get restoreSharedPreferences => throw _privateConstructorUsedError;
  bool get restoreDatabases => throw _privateConstructorUsedError;
  bool get forceRestore => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RestoreOptionsCopyWith<RestoreOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestoreOptionsCopyWith<$Res> {
  factory $RestoreOptionsCopyWith(
          RestoreOptions value, $Res Function(RestoreOptions) then) =
      _$RestoreOptionsCopyWithImpl<$Res, RestoreOptions>;
  @useResult
  $Res call(
      {bool restoreSharedPreferences,
      bool restoreDatabases,
      bool forceRestore});
}

/// @nodoc
class _$RestoreOptionsCopyWithImpl<$Res, $Val extends RestoreOptions>
    implements $RestoreOptionsCopyWith<$Res> {
  _$RestoreOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? restoreSharedPreferences = null,
    Object? restoreDatabases = null,
    Object? forceRestore = null,
  }) {
    return _then(_value.copyWith(
      restoreSharedPreferences: null == restoreSharedPreferences
          ? _value.restoreSharedPreferences
          : restoreSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      restoreDatabases: null == restoreDatabases
          ? _value.restoreDatabases
          : restoreDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      forceRestore: null == forceRestore
          ? _value.forceRestore
          : forceRestore // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RestoreOptionsImplCopyWith<$Res>
    implements $RestoreOptionsCopyWith<$Res> {
  factory _$$RestoreOptionsImplCopyWith(_$RestoreOptionsImpl value,
          $Res Function(_$RestoreOptionsImpl) then) =
      __$$RestoreOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool restoreSharedPreferences,
      bool restoreDatabases,
      bool forceRestore});
}

/// @nodoc
class __$$RestoreOptionsImplCopyWithImpl<$Res>
    extends _$RestoreOptionsCopyWithImpl<$Res, _$RestoreOptionsImpl>
    implements _$$RestoreOptionsImplCopyWith<$Res> {
  __$$RestoreOptionsImplCopyWithImpl(
      _$RestoreOptionsImpl _value, $Res Function(_$RestoreOptionsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? restoreSharedPreferences = null,
    Object? restoreDatabases = null,
    Object? forceRestore = null,
  }) {
    return _then(_$RestoreOptionsImpl(
      restoreSharedPreferences: null == restoreSharedPreferences
          ? _value.restoreSharedPreferences
          : restoreSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      restoreDatabases: null == restoreDatabases
          ? _value.restoreDatabases
          : restoreDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      forceRestore: null == forceRestore
          ? _value.forceRestore
          : forceRestore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$RestoreOptionsImpl implements _RestoreOptions {
  const _$RestoreOptionsImpl(
      {this.restoreSharedPreferences = true,
      this.restoreDatabases = true,
      this.forceRestore = false});

  @override
  @JsonKey()
  final bool restoreSharedPreferences;
  @override
  @JsonKey()
  final bool restoreDatabases;
  @override
  @JsonKey()
  final bool forceRestore;

  @override
  String toString() {
    return 'RestoreOptions(restoreSharedPreferences: $restoreSharedPreferences, restoreDatabases: $restoreDatabases, forceRestore: $forceRestore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestoreOptionsImpl &&
            (identical(
                    other.restoreSharedPreferences, restoreSharedPreferences) ||
                other.restoreSharedPreferences == restoreSharedPreferences) &&
            (identical(other.restoreDatabases, restoreDatabases) ||
                other.restoreDatabases == restoreDatabases) &&
            (identical(other.forceRestore, forceRestore) ||
                other.forceRestore == forceRestore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, restoreSharedPreferences, restoreDatabases, forceRestore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RestoreOptionsImplCopyWith<_$RestoreOptionsImpl> get copyWith =>
      __$$RestoreOptionsImplCopyWithImpl<_$RestoreOptionsImpl>(
          this, _$identity);
}

abstract class _RestoreOptions implements RestoreOptions {
  const factory _RestoreOptions(
      {final bool restoreSharedPreferences,
      final bool restoreDatabases,
      final bool forceRestore}) = _$RestoreOptionsImpl;

  @override
  bool get restoreSharedPreferences;
  @override
  bool get restoreDatabases;
  @override
  bool get forceRestore;
  @override
  @JsonKey(ignore: true)
  _$$RestoreOptionsImplCopyWith<_$RestoreOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackupFileInfo {
  String get fileName => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  DateTime get createdTime => throw _privateConstructorUsedError;
  BackupMetadata? get metadata => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackupFileInfoCopyWith<BackupFileInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupFileInfoCopyWith<$Res> {
  factory $BackupFileInfoCopyWith(
          BackupFileInfo value, $Res Function(BackupFileInfo) then) =
      _$BackupFileInfoCopyWithImpl<$Res, BackupFileInfo>;
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      int fileSize,
      DateTime createdTime,
      BackupMetadata? metadata,
      String? description});

  $BackupMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class _$BackupFileInfoCopyWithImpl<$Res, $Val extends BackupFileInfo>
    implements $BackupFileInfoCopyWith<$Res> {
  _$BackupFileInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileSize = null,
    Object? createdTime = null,
    Object? metadata = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      createdTime: null == createdTime
          ? _value.createdTime
          : createdTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BackupFileInfoImplCopyWith<$Res>
    implements $BackupFileInfoCopyWith<$Res> {
  factory _$$BackupFileInfoImplCopyWith(_$BackupFileInfoImpl value,
          $Res Function(_$BackupFileInfoImpl) then) =
      __$$BackupFileInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      int fileSize,
      DateTime createdTime,
      BackupMetadata? metadata,
      String? description});

  @override
  $BackupMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$BackupFileInfoImplCopyWithImpl<$Res>
    extends _$BackupFileInfoCopyWithImpl<$Res, _$BackupFileInfoImpl>
    implements _$$BackupFileInfoImplCopyWith<$Res> {
  __$$BackupFileInfoImplCopyWithImpl(
      _$BackupFileInfoImpl _value, $Res Function(_$BackupFileInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileSize = null,
    Object? createdTime = null,
    Object? metadata = freezed,
    Object? description = freezed,
  }) {
    return _then(_$BackupFileInfoImpl(
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      createdTime: null == createdTime
          ? _value.createdTime
          : createdTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BackupFileInfoImpl implements _BackupFileInfo {
  const _$BackupFileInfoImpl(
      {required this.fileName,
      required this.filePath,
      required this.fileSize,
      required this.createdTime,
      this.metadata,
      this.description});

  @override
  final String fileName;
  @override
  final String filePath;
  @override
  final int fileSize;
  @override
  final DateTime createdTime;
  @override
  final BackupMetadata? metadata;
  @override
  final String? description;

  @override
  String toString() {
    return 'BackupFileInfo(fileName: $fileName, filePath: $filePath, fileSize: $fileSize, createdTime: $createdTime, metadata: $metadata, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupFileInfoImpl &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.createdTime, createdTime) ||
                other.createdTime == createdTime) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileName, filePath, fileSize,
      createdTime, metadata, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupFileInfoImplCopyWith<_$BackupFileInfoImpl> get copyWith =>
      __$$BackupFileInfoImplCopyWithImpl<_$BackupFileInfoImpl>(
          this, _$identity);
}

abstract class _BackupFileInfo implements BackupFileInfo {
  const factory _BackupFileInfo(
      {required final String fileName,
      required final String filePath,
      required final int fileSize,
      required final DateTime createdTime,
      final BackupMetadata? metadata,
      final String? description}) = _$BackupFileInfoImpl;

  @override
  String get fileName;
  @override
  String get filePath;
  @override
  int get fileSize;
  @override
  DateTime get createdTime;
  @override
  BackupMetadata? get metadata;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$BackupFileInfoImplCopyWith<_$BackupFileInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackupFilesState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<BackupFileInfo> get backupFiles => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackupFilesStateCopyWith<BackupFilesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupFilesStateCopyWith<$Res> {
  factory $BackupFilesStateCopyWith(
          BackupFilesState value, $Res Function(BackupFilesState) then) =
      _$BackupFilesStateCopyWithImpl<$Res, BackupFilesState>;
  @useResult
  $Res call({bool isLoading, List<BackupFileInfo> backupFiles, String? error});
}

/// @nodoc
class _$BackupFilesStateCopyWithImpl<$Res, $Val extends BackupFilesState>
    implements $BackupFilesStateCopyWith<$Res> {
  _$BackupFilesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? backupFiles = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFiles: null == backupFiles
          ? _value.backupFiles
          : backupFiles // ignore: cast_nullable_to_non_nullable
              as List<BackupFileInfo>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupFilesStateImplCopyWith<$Res>
    implements $BackupFilesStateCopyWith<$Res> {
  factory _$$BackupFilesStateImplCopyWith(_$BackupFilesStateImpl value,
          $Res Function(_$BackupFilesStateImpl) then) =
      __$$BackupFilesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, List<BackupFileInfo> backupFiles, String? error});
}

/// @nodoc
class __$$BackupFilesStateImplCopyWithImpl<$Res>
    extends _$BackupFilesStateCopyWithImpl<$Res, _$BackupFilesStateImpl>
    implements _$$BackupFilesStateImplCopyWith<$Res> {
  __$$BackupFilesStateImplCopyWithImpl(_$BackupFilesStateImpl _value,
      $Res Function(_$BackupFilesStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? backupFiles = null,
    Object? error = freezed,
  }) {
    return _then(_$BackupFilesStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFiles: null == backupFiles
          ? _value._backupFiles
          : backupFiles // ignore: cast_nullable_to_non_nullable
              as List<BackupFileInfo>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BackupFilesStateImpl implements _BackupFilesState {
  const _$BackupFilesStateImpl(
      {this.isLoading = false,
      final List<BackupFileInfo> backupFiles = const [],
      this.error})
      : _backupFiles = backupFiles;

  @override
  @JsonKey()
  final bool isLoading;
  final List<BackupFileInfo> _backupFiles;
  @override
  @JsonKey()
  List<BackupFileInfo> get backupFiles {
    if (_backupFiles is EqualUnmodifiableListView) return _backupFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_backupFiles);
  }

  @override
  final String? error;

  @override
  String toString() {
    return 'BackupFilesState(isLoading: $isLoading, backupFiles: $backupFiles, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupFilesStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other._backupFiles, _backupFiles) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading,
      const DeepCollectionEquality().hash(_backupFiles), error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupFilesStateImplCopyWith<_$BackupFilesStateImpl> get copyWith =>
      __$$BackupFilesStateImplCopyWithImpl<_$BackupFilesStateImpl>(
          this, _$identity);
}

abstract class _BackupFilesState implements BackupFilesState {
  const factory _BackupFilesState(
      {final bool isLoading,
      final List<BackupFileInfo> backupFiles,
      final String? error}) = _$BackupFilesStateImpl;

  @override
  bool get isLoading;
  @override
  List<BackupFileInfo> get backupFiles;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$BackupFilesStateImplCopyWith<_$BackupFilesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ExportOptions {
  bool get includeSharedPreferences => throw _privateConstructorUsedError;
  bool get includeDatabases => throw _privateConstructorUsedError;
  String? get customPath => throw _privateConstructorUsedError;
  String? get customFileName => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ExportOptionsCopyWith<ExportOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportOptionsCopyWith<$Res> {
  factory $ExportOptionsCopyWith(
          ExportOptions value, $Res Function(ExportOptions) then) =
      _$ExportOptionsCopyWithImpl<$Res, ExportOptions>;
  @useResult
  $Res call(
      {bool includeSharedPreferences,
      bool includeDatabases,
      String? customPath,
      String? customFileName});
}

/// @nodoc
class _$ExportOptionsCopyWithImpl<$Res, $Val extends ExportOptions>
    implements $ExportOptionsCopyWith<$Res> {
  _$ExportOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? includeSharedPreferences = null,
    Object? includeDatabases = null,
    Object? customPath = freezed,
    Object? customFileName = freezed,
  }) {
    return _then(_value.copyWith(
      includeSharedPreferences: null == includeSharedPreferences
          ? _value.includeSharedPreferences
          : includeSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      includeDatabases: null == includeDatabases
          ? _value.includeDatabases
          : includeDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      customPath: freezed == customPath
          ? _value.customPath
          : customPath // ignore: cast_nullable_to_non_nullable
              as String?,
      customFileName: freezed == customFileName
          ? _value.customFileName
          : customFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportOptionsImplCopyWith<$Res>
    implements $ExportOptionsCopyWith<$Res> {
  factory _$$ExportOptionsImplCopyWith(
          _$ExportOptionsImpl value, $Res Function(_$ExportOptionsImpl) then) =
      __$$ExportOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool includeSharedPreferences,
      bool includeDatabases,
      String? customPath,
      String? customFileName});
}

/// @nodoc
class __$$ExportOptionsImplCopyWithImpl<$Res>
    extends _$ExportOptionsCopyWithImpl<$Res, _$ExportOptionsImpl>
    implements _$$ExportOptionsImplCopyWith<$Res> {
  __$$ExportOptionsImplCopyWithImpl(
      _$ExportOptionsImpl _value, $Res Function(_$ExportOptionsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? includeSharedPreferences = null,
    Object? includeDatabases = null,
    Object? customPath = freezed,
    Object? customFileName = freezed,
  }) {
    return _then(_$ExportOptionsImpl(
      includeSharedPreferences: null == includeSharedPreferences
          ? _value.includeSharedPreferences
          : includeSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      includeDatabases: null == includeDatabases
          ? _value.includeDatabases
          : includeDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      customPath: freezed == customPath
          ? _value.customPath
          : customPath // ignore: cast_nullable_to_non_nullable
              as String?,
      customFileName: freezed == customFileName
          ? _value.customFileName
          : customFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ExportOptionsImpl implements _ExportOptions {
  const _$ExportOptionsImpl(
      {this.includeSharedPreferences = true,
      this.includeDatabases = true,
      this.customPath,
      this.customFileName});

  @override
  @JsonKey()
  final bool includeSharedPreferences;
  @override
  @JsonKey()
  final bool includeDatabases;
  @override
  final String? customPath;
  @override
  final String? customFileName;

  @override
  String toString() {
    return 'ExportOptions(includeSharedPreferences: $includeSharedPreferences, includeDatabases: $includeDatabases, customPath: $customPath, customFileName: $customFileName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportOptionsImpl &&
            (identical(
                    other.includeSharedPreferences, includeSharedPreferences) ||
                other.includeSharedPreferences == includeSharedPreferences) &&
            (identical(other.includeDatabases, includeDatabases) ||
                other.includeDatabases == includeDatabases) &&
            (identical(other.customPath, customPath) ||
                other.customPath == customPath) &&
            (identical(other.customFileName, customFileName) ||
                other.customFileName == customFileName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, includeSharedPreferences,
      includeDatabases, customPath, customFileName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportOptionsImplCopyWith<_$ExportOptionsImpl> get copyWith =>
      __$$ExportOptionsImplCopyWithImpl<_$ExportOptionsImpl>(this, _$identity);
}

abstract class _ExportOptions implements ExportOptions {
  const factory _ExportOptions(
      {final bool includeSharedPreferences,
      final bool includeDatabases,
      final String? customPath,
      final String? customFileName}) = _$ExportOptionsImpl;

  @override
  bool get includeSharedPreferences;
  @override
  bool get includeDatabases;
  @override
  String? get customPath;
  @override
  String? get customFileName;
  @override
  @JsonKey(ignore: true)
  _$$ExportOptionsImplCopyWith<_$ExportOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HashInfo _$HashInfoFromJson(Map<String, dynamic> json) {
  return _HashInfo.fromJson(json);
}

/// @nodoc
mixin _$HashInfo {
  String get algorithm => throw _privateConstructorUsedError;
  String get hash => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HashInfoCopyWith<HashInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HashInfoCopyWith<$Res> {
  factory $HashInfoCopyWith(HashInfo value, $Res Function(HashInfo) then) =
      _$HashInfoCopyWithImpl<$Res, HashInfo>;
  @useResult
  $Res call({String algorithm, String hash, String timestamp});
}

/// @nodoc
class _$HashInfoCopyWithImpl<$Res, $Val extends HashInfo>
    implements $HashInfoCopyWith<$Res> {
  _$HashInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithm = null,
    Object? hash = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HashInfoImplCopyWith<$Res>
    implements $HashInfoCopyWith<$Res> {
  factory _$$HashInfoImplCopyWith(
          _$HashInfoImpl value, $Res Function(_$HashInfoImpl) then) =
      __$$HashInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String algorithm, String hash, String timestamp});
}

/// @nodoc
class __$$HashInfoImplCopyWithImpl<$Res>
    extends _$HashInfoCopyWithImpl<$Res, _$HashInfoImpl>
    implements _$$HashInfoImplCopyWith<$Res> {
  __$$HashInfoImplCopyWithImpl(
      _$HashInfoImpl _value, $Res Function(_$HashInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithm = null,
    Object? hash = null,
    Object? timestamp = null,
  }) {
    return _then(_$HashInfoImpl(
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HashInfoImpl implements _HashInfo {
  const _$HashInfoImpl(
      {required this.algorithm, required this.hash, required this.timestamp});

  factory _$HashInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$HashInfoImplFromJson(json);

  @override
  final String algorithm;
  @override
  final String hash;
  @override
  final String timestamp;

  @override
  String toString() {
    return 'HashInfo(algorithm: $algorithm, hash: $hash, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HashInfoImpl &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, algorithm, hash, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HashInfoImplCopyWith<_$HashInfoImpl> get copyWith =>
      __$$HashInfoImplCopyWithImpl<_$HashInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HashInfoImplToJson(
      this,
    );
  }
}

abstract class _HashInfo implements HashInfo {
  const factory _HashInfo(
      {required final String algorithm,
      required final String hash,
      required final String timestamp}) = _$HashInfoImpl;

  factory _HashInfo.fromJson(Map<String, dynamic> json) =
      _$HashInfoImpl.fromJson;

  @override
  String get algorithm;
  @override
  String get hash;
  @override
  String get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$HashInfoImplCopyWith<_$HashInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BackupPreviewInfo {
  BackupMetadata get metadata => throw _privateConstructorUsedError;
  Map<String, dynamic> get dataStatistics => throw _privateConstructorUsedError;
  List<String> get dataTypes => throw _privateConstructorUsedError;
  bool get hasHash => throw _privateConstructorUsedError;
  bool get hashValid => throw _privateConstructorUsedError;
  String? get hashError => throw _privateConstructorUsedError;
  CompatibilityInfo? get compatibilityInfo =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BackupPreviewInfoCopyWith<BackupPreviewInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupPreviewInfoCopyWith<$Res> {
  factory $BackupPreviewInfoCopyWith(
          BackupPreviewInfo value, $Res Function(BackupPreviewInfo) then) =
      _$BackupPreviewInfoCopyWithImpl<$Res, BackupPreviewInfo>;
  @useResult
  $Res call(
      {BackupMetadata metadata,
      Map<String, dynamic> dataStatistics,
      List<String> dataTypes,
      bool hasHash,
      bool hashValid,
      String? hashError,
      CompatibilityInfo? compatibilityInfo});

  $BackupMetadataCopyWith<$Res> get metadata;
  $CompatibilityInfoCopyWith<$Res>? get compatibilityInfo;
}

/// @nodoc
class _$BackupPreviewInfoCopyWithImpl<$Res, $Val extends BackupPreviewInfo>
    implements $BackupPreviewInfoCopyWith<$Res> {
  _$BackupPreviewInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? dataStatistics = null,
    Object? dataTypes = null,
    Object? hasHash = null,
    Object? hashValid = null,
    Object? hashError = freezed,
    Object? compatibilityInfo = freezed,
  }) {
    return _then(_value.copyWith(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      dataStatistics: null == dataStatistics
          ? _value.dataStatistics
          : dataStatistics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      dataTypes: null == dataTypes
          ? _value.dataTypes
          : dataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hasHash: null == hasHash
          ? _value.hasHash
          : hasHash // ignore: cast_nullable_to_non_nullable
              as bool,
      hashValid: null == hashValid
          ? _value.hashValid
          : hashValid // ignore: cast_nullable_to_non_nullable
              as bool,
      hashError: freezed == hashError
          ? _value.hashError
          : hashError // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityInfo: freezed == compatibilityInfo
          ? _value.compatibilityInfo
          : compatibilityInfo // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CompatibilityInfoCopyWith<$Res>? get compatibilityInfo {
    if (_value.compatibilityInfo == null) {
      return null;
    }

    return $CompatibilityInfoCopyWith<$Res>(_value.compatibilityInfo!, (value) {
      return _then(_value.copyWith(compatibilityInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BackupPreviewInfoImplCopyWith<$Res>
    implements $BackupPreviewInfoCopyWith<$Res> {
  factory _$$BackupPreviewInfoImplCopyWith(_$BackupPreviewInfoImpl value,
          $Res Function(_$BackupPreviewInfoImpl) then) =
      __$$BackupPreviewInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {BackupMetadata metadata,
      Map<String, dynamic> dataStatistics,
      List<String> dataTypes,
      bool hasHash,
      bool hashValid,
      String? hashError,
      CompatibilityInfo? compatibilityInfo});

  @override
  $BackupMetadataCopyWith<$Res> get metadata;
  @override
  $CompatibilityInfoCopyWith<$Res>? get compatibilityInfo;
}

/// @nodoc
class __$$BackupPreviewInfoImplCopyWithImpl<$Res>
    extends _$BackupPreviewInfoCopyWithImpl<$Res, _$BackupPreviewInfoImpl>
    implements _$$BackupPreviewInfoImplCopyWith<$Res> {
  __$$BackupPreviewInfoImplCopyWithImpl(_$BackupPreviewInfoImpl _value,
      $Res Function(_$BackupPreviewInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? dataStatistics = null,
    Object? dataTypes = null,
    Object? hasHash = null,
    Object? hashValid = null,
    Object? hashError = freezed,
    Object? compatibilityInfo = freezed,
  }) {
    return _then(_$BackupPreviewInfoImpl(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      dataStatistics: null == dataStatistics
          ? _value._dataStatistics
          : dataStatistics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      dataTypes: null == dataTypes
          ? _value._dataTypes
          : dataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hasHash: null == hasHash
          ? _value.hasHash
          : hasHash // ignore: cast_nullable_to_non_nullable
              as bool,
      hashValid: null == hashValid
          ? _value.hashValid
          : hashValid // ignore: cast_nullable_to_non_nullable
              as bool,
      hashError: freezed == hashError
          ? _value.hashError
          : hashError // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityInfo: freezed == compatibilityInfo
          ? _value.compatibilityInfo
          : compatibilityInfo // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo?,
    ));
  }
}

/// @nodoc

class _$BackupPreviewInfoImpl implements _BackupPreviewInfo {
  const _$BackupPreviewInfoImpl(
      {required this.metadata,
      required final Map<String, dynamic> dataStatistics,
      required final List<String> dataTypes,
      required this.hasHash,
      required this.hashValid,
      this.hashError,
      this.compatibilityInfo})
      : _dataStatistics = dataStatistics,
        _dataTypes = dataTypes;

  @override
  final BackupMetadata metadata;
  final Map<String, dynamic> _dataStatistics;
  @override
  Map<String, dynamic> get dataStatistics {
    if (_dataStatistics is EqualUnmodifiableMapView) return _dataStatistics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_dataStatistics);
  }

  final List<String> _dataTypes;
  @override
  List<String> get dataTypes {
    if (_dataTypes is EqualUnmodifiableListView) return _dataTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dataTypes);
  }

  @override
  final bool hasHash;
  @override
  final bool hashValid;
  @override
  final String? hashError;
  @override
  final CompatibilityInfo? compatibilityInfo;

  @override
  String toString() {
    return 'BackupPreviewInfo(metadata: $metadata, dataStatistics: $dataStatistics, dataTypes: $dataTypes, hasHash: $hasHash, hashValid: $hashValid, hashError: $hashError, compatibilityInfo: $compatibilityInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupPreviewInfoImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other._dataStatistics, _dataStatistics) &&
            const DeepCollectionEquality()
                .equals(other._dataTypes, _dataTypes) &&
            (identical(other.hasHash, hasHash) || other.hasHash == hasHash) &&
            (identical(other.hashValid, hashValid) ||
                other.hashValid == hashValid) &&
            (identical(other.hashError, hashError) ||
                other.hashError == hashError) &&
            (identical(other.compatibilityInfo, compatibilityInfo) ||
                other.compatibilityInfo == compatibilityInfo));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      metadata,
      const DeepCollectionEquality().hash(_dataStatistics),
      const DeepCollectionEquality().hash(_dataTypes),
      hasHash,
      hashValid,
      hashError,
      compatibilityInfo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupPreviewInfoImplCopyWith<_$BackupPreviewInfoImpl> get copyWith =>
      __$$BackupPreviewInfoImplCopyWithImpl<_$BackupPreviewInfoImpl>(
          this, _$identity);
}

abstract class _BackupPreviewInfo implements BackupPreviewInfo {
  const factory _BackupPreviewInfo(
      {required final BackupMetadata metadata,
      required final Map<String, dynamic> dataStatistics,
      required final List<String> dataTypes,
      required final bool hasHash,
      required final bool hashValid,
      final String? hashError,
      final CompatibilityInfo? compatibilityInfo}) = _$BackupPreviewInfoImpl;

  @override
  BackupMetadata get metadata;
  @override
  Map<String, dynamic> get dataStatistics;
  @override
  List<String> get dataTypes;
  @override
  bool get hasHash;
  @override
  bool get hashValid;
  @override
  String? get hashError;
  @override
  CompatibilityInfo? get compatibilityInfo;
  @override
  @JsonKey(ignore: true)
  _$$BackupPreviewInfoImplCopyWith<_$BackupPreviewInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DataStatistics {
  int get countersCount => throw _privateConstructorUsedError;
  int get mahjongSessionsCount => throw _privateConstructorUsedError;
  int get poker50SessionsCount => throw _privateConstructorUsedError;
  int get templatesCount => throw _privateConstructorUsedError;
  int get sharedPreferencesCount => throw _privateConstructorUsedError;
  int get databaseFilesCount => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DataStatisticsCopyWith<DataStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataStatisticsCopyWith<$Res> {
  factory $DataStatisticsCopyWith(
          DataStatistics value, $Res Function(DataStatistics) then) =
      _$DataStatisticsCopyWithImpl<$Res, DataStatistics>;
  @useResult
  $Res call(
      {int countersCount,
      int mahjongSessionsCount,
      int poker50SessionsCount,
      int templatesCount,
      int sharedPreferencesCount,
      int databaseFilesCount});
}

/// @nodoc
class _$DataStatisticsCopyWithImpl<$Res, $Val extends DataStatistics>
    implements $DataStatisticsCopyWith<$Res> {
  _$DataStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? countersCount = null,
    Object? mahjongSessionsCount = null,
    Object? poker50SessionsCount = null,
    Object? templatesCount = null,
    Object? sharedPreferencesCount = null,
    Object? databaseFilesCount = null,
  }) {
    return _then(_value.copyWith(
      countersCount: null == countersCount
          ? _value.countersCount
          : countersCount // ignore: cast_nullable_to_non_nullable
              as int,
      mahjongSessionsCount: null == mahjongSessionsCount
          ? _value.mahjongSessionsCount
          : mahjongSessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      poker50SessionsCount: null == poker50SessionsCount
          ? _value.poker50SessionsCount
          : poker50SessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      templatesCount: null == templatesCount
          ? _value.templatesCount
          : templatesCount // ignore: cast_nullable_to_non_nullable
              as int,
      sharedPreferencesCount: null == sharedPreferencesCount
          ? _value.sharedPreferencesCount
          : sharedPreferencesCount // ignore: cast_nullable_to_non_nullable
              as int,
      databaseFilesCount: null == databaseFilesCount
          ? _value.databaseFilesCount
          : databaseFilesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataStatisticsImplCopyWith<$Res>
    implements $DataStatisticsCopyWith<$Res> {
  factory _$$DataStatisticsImplCopyWith(_$DataStatisticsImpl value,
          $Res Function(_$DataStatisticsImpl) then) =
      __$$DataStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int countersCount,
      int mahjongSessionsCount,
      int poker50SessionsCount,
      int templatesCount,
      int sharedPreferencesCount,
      int databaseFilesCount});
}

/// @nodoc
class __$$DataStatisticsImplCopyWithImpl<$Res>
    extends _$DataStatisticsCopyWithImpl<$Res, _$DataStatisticsImpl>
    implements _$$DataStatisticsImplCopyWith<$Res> {
  __$$DataStatisticsImplCopyWithImpl(
      _$DataStatisticsImpl _value, $Res Function(_$DataStatisticsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? countersCount = null,
    Object? mahjongSessionsCount = null,
    Object? poker50SessionsCount = null,
    Object? templatesCount = null,
    Object? sharedPreferencesCount = null,
    Object? databaseFilesCount = null,
  }) {
    return _then(_$DataStatisticsImpl(
      countersCount: null == countersCount
          ? _value.countersCount
          : countersCount // ignore: cast_nullable_to_non_nullable
              as int,
      mahjongSessionsCount: null == mahjongSessionsCount
          ? _value.mahjongSessionsCount
          : mahjongSessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      poker50SessionsCount: null == poker50SessionsCount
          ? _value.poker50SessionsCount
          : poker50SessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      templatesCount: null == templatesCount
          ? _value.templatesCount
          : templatesCount // ignore: cast_nullable_to_non_nullable
              as int,
      sharedPreferencesCount: null == sharedPreferencesCount
          ? _value.sharedPreferencesCount
          : sharedPreferencesCount // ignore: cast_nullable_to_non_nullable
              as int,
      databaseFilesCount: null == databaseFilesCount
          ? _value.databaseFilesCount
          : databaseFilesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DataStatisticsImpl implements _DataStatistics {
  const _$DataStatisticsImpl(
      {this.countersCount = 0,
      this.mahjongSessionsCount = 0,
      this.poker50SessionsCount = 0,
      this.templatesCount = 0,
      this.sharedPreferencesCount = 0,
      this.databaseFilesCount = 0});

  @override
  @JsonKey()
  final int countersCount;
  @override
  @JsonKey()
  final int mahjongSessionsCount;
  @override
  @JsonKey()
  final int poker50SessionsCount;
  @override
  @JsonKey()
  final int templatesCount;
  @override
  @JsonKey()
  final int sharedPreferencesCount;
  @override
  @JsonKey()
  final int databaseFilesCount;

  @override
  String toString() {
    return 'DataStatistics(countersCount: $countersCount, mahjongSessionsCount: $mahjongSessionsCount, poker50SessionsCount: $poker50SessionsCount, templatesCount: $templatesCount, sharedPreferencesCount: $sharedPreferencesCount, databaseFilesCount: $databaseFilesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataStatisticsImpl &&
            (identical(other.countersCount, countersCount) ||
                other.countersCount == countersCount) &&
            (identical(other.mahjongSessionsCount, mahjongSessionsCount) ||
                other.mahjongSessionsCount == mahjongSessionsCount) &&
            (identical(other.poker50SessionsCount, poker50SessionsCount) ||
                other.poker50SessionsCount == poker50SessionsCount) &&
            (identical(other.templatesCount, templatesCount) ||
                other.templatesCount == templatesCount) &&
            (identical(other.sharedPreferencesCount, sharedPreferencesCount) ||
                other.sharedPreferencesCount == sharedPreferencesCount) &&
            (identical(other.databaseFilesCount, databaseFilesCount) ||
                other.databaseFilesCount == databaseFilesCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      countersCount,
      mahjongSessionsCount,
      poker50SessionsCount,
      templatesCount,
      sharedPreferencesCount,
      databaseFilesCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DataStatisticsImplCopyWith<_$DataStatisticsImpl> get copyWith =>
      __$$DataStatisticsImplCopyWithImpl<_$DataStatisticsImpl>(
          this, _$identity);
}

abstract class _DataStatistics implements DataStatistics {
  const factory _DataStatistics(
      {final int countersCount,
      final int mahjongSessionsCount,
      final int poker50SessionsCount,
      final int templatesCount,
      final int sharedPreferencesCount,
      final int databaseFilesCount}) = _$DataStatisticsImpl;

  @override
  int get countersCount;
  @override
  int get mahjongSessionsCount;
  @override
  int get poker50SessionsCount;
  @override
  int get templatesCount;
  @override
  int get sharedPreferencesCount;
  @override
  int get databaseFilesCount;
  @override
  @JsonKey(ignore: true)
  _$$DataStatisticsImplCopyWith<_$DataStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PreviewState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isAnalyzing => throw _privateConstructorUsedError;
  bool get isCheckingCompatibility => throw _privateConstructorUsedError;
  BackupPreviewInfo? get previewInfo => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get selectedFilePath => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PreviewStateCopyWith<PreviewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PreviewStateCopyWith<$Res> {
  factory $PreviewStateCopyWith(
          PreviewState value, $Res Function(PreviewState) then) =
      _$PreviewStateCopyWithImpl<$Res, PreviewState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isAnalyzing,
      bool isCheckingCompatibility,
      BackupPreviewInfo? previewInfo,
      String? error,
      String? selectedFilePath});

  $BackupPreviewInfoCopyWith<$Res>? get previewInfo;
}

/// @nodoc
class _$PreviewStateCopyWithImpl<$Res, $Val extends PreviewState>
    implements $PreviewStateCopyWith<$Res> {
  _$PreviewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAnalyzing = null,
    Object? isCheckingCompatibility = null,
    Object? previewInfo = freezed,
    Object? error = freezed,
    Object? selectedFilePath = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzing: null == isAnalyzing
          ? _value.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckingCompatibility: null == isCheckingCompatibility
          ? _value.isCheckingCompatibility
          : isCheckingCompatibility // ignore: cast_nullable_to_non_nullable
              as bool,
      previewInfo: freezed == previewInfo
          ? _value.previewInfo
          : previewInfo // ignore: cast_nullable_to_non_nullable
              as BackupPreviewInfo?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFilePath: freezed == selectedFilePath
          ? _value.selectedFilePath
          : selectedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BackupPreviewInfoCopyWith<$Res>? get previewInfo {
    if (_value.previewInfo == null) {
      return null;
    }

    return $BackupPreviewInfoCopyWith<$Res>(_value.previewInfo!, (value) {
      return _then(_value.copyWith(previewInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PreviewStateImplCopyWith<$Res>
    implements $PreviewStateCopyWith<$Res> {
  factory _$$PreviewStateImplCopyWith(
          _$PreviewStateImpl value, $Res Function(_$PreviewStateImpl) then) =
      __$$PreviewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isAnalyzing,
      bool isCheckingCompatibility,
      BackupPreviewInfo? previewInfo,
      String? error,
      String? selectedFilePath});

  @override
  $BackupPreviewInfoCopyWith<$Res>? get previewInfo;
}

/// @nodoc
class __$$PreviewStateImplCopyWithImpl<$Res>
    extends _$PreviewStateCopyWithImpl<$Res, _$PreviewStateImpl>
    implements _$$PreviewStateImplCopyWith<$Res> {
  __$$PreviewStateImplCopyWithImpl(
      _$PreviewStateImpl _value, $Res Function(_$PreviewStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAnalyzing = null,
    Object? isCheckingCompatibility = null,
    Object? previewInfo = freezed,
    Object? error = freezed,
    Object? selectedFilePath = freezed,
  }) {
    return _then(_$PreviewStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzing: null == isAnalyzing
          ? _value.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckingCompatibility: null == isCheckingCompatibility
          ? _value.isCheckingCompatibility
          : isCheckingCompatibility // ignore: cast_nullable_to_non_nullable
              as bool,
      previewInfo: freezed == previewInfo
          ? _value.previewInfo
          : previewInfo // ignore: cast_nullable_to_non_nullable
              as BackupPreviewInfo?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFilePath: freezed == selectedFilePath
          ? _value.selectedFilePath
          : selectedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PreviewStateImpl implements _PreviewState {
  const _$PreviewStateImpl(
      {this.isLoading = false,
      this.isAnalyzing = false,
      this.isCheckingCompatibility = false,
      this.previewInfo,
      this.error,
      this.selectedFilePath});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isAnalyzing;
  @override
  @JsonKey()
  final bool isCheckingCompatibility;
  @override
  final BackupPreviewInfo? previewInfo;
  @override
  final String? error;
  @override
  final String? selectedFilePath;

  @override
  String toString() {
    return 'PreviewState(isLoading: $isLoading, isAnalyzing: $isAnalyzing, isCheckingCompatibility: $isCheckingCompatibility, previewInfo: $previewInfo, error: $error, selectedFilePath: $selectedFilePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PreviewStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isAnalyzing, isAnalyzing) ||
                other.isAnalyzing == isAnalyzing) &&
            (identical(
                    other.isCheckingCompatibility, isCheckingCompatibility) ||
                other.isCheckingCompatibility == isCheckingCompatibility) &&
            (identical(other.previewInfo, previewInfo) ||
                other.previewInfo == previewInfo) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.selectedFilePath, selectedFilePath) ||
                other.selectedFilePath == selectedFilePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, isAnalyzing,
      isCheckingCompatibility, previewInfo, error, selectedFilePath);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PreviewStateImplCopyWith<_$PreviewStateImpl> get copyWith =>
      __$$PreviewStateImplCopyWithImpl<_$PreviewStateImpl>(this, _$identity);
}

abstract class _PreviewState implements PreviewState {
  const factory _PreviewState(
      {final bool isLoading,
      final bool isAnalyzing,
      final bool isCheckingCompatibility,
      final BackupPreviewInfo? previewInfo,
      final String? error,
      final String? selectedFilePath}) = _$PreviewStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isAnalyzing;
  @override
  bool get isCheckingCompatibility;
  @override
  BackupPreviewInfo? get previewInfo;
  @override
  String? get error;
  @override
  String? get selectedFilePath;
  @override
  @JsonKey(ignore: true)
  _$$PreviewStateImplCopyWith<_$PreviewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
