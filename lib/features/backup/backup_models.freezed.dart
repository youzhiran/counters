// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackupData {
  BackupMetadata get metadata;
  Map<String, dynamic> get sharedPreferences;
  List<DatabaseFile> get databases;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupDataCopyWith<BackupData> get copyWith =>
      _$BackupDataCopyWithImpl<BackupData>(this as BackupData, _$identity);

  /// Serializes this BackupData to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupData &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other.sharedPreferences, sharedPreferences) &&
            const DeepCollectionEquality().equals(other.databases, databases));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      metadata,
      const DeepCollectionEquality().hash(sharedPreferences),
      const DeepCollectionEquality().hash(databases));

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, sharedPreferences: $sharedPreferences, databases: $databases)';
  }
}

/// @nodoc
abstract mixin class $BackupDataCopyWith<$Res> {
  factory $BackupDataCopyWith(
          BackupData value, $Res Function(BackupData) _then) =
      _$BackupDataCopyWithImpl;
  @useResult
  $Res call(
      {BackupMetadata metadata,
      Map<String, dynamic> sharedPreferences,
      List<DatabaseFile> databases});

  $BackupMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$BackupDataCopyWithImpl<$Res> implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._self, this._then);

  final BackupData _self;
  final $Res Function(BackupData) _then;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? sharedPreferences = null,
    Object? databases = null,
  }) {
    return _then(_self.copyWith(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      sharedPreferences: null == sharedPreferences
          ? _self.sharedPreferences
          : sharedPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      databases: null == databases
          ? _self.databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<DatabaseFile>,
    ));
  }

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BackupData].
extension BackupDataPatterns on BackupData {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            BackupMetadata metadata,
            Map<String, dynamic> sharedPreferences,
            List<DatabaseFile> databases)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(
            _that.metadata, _that.sharedPreferences, _that.databases);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            BackupMetadata metadata,
            Map<String, dynamic> sharedPreferences,
            List<DatabaseFile> databases)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData():
        return $default(
            _that.metadata, _that.sharedPreferences, _that.databases);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            BackupMetadata metadata,
            Map<String, dynamic> sharedPreferences,
            List<DatabaseFile> databases)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(
            _that.metadata, _that.sharedPreferences, _that.databases);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BackupData implements BackupData {
  const _BackupData(
      {required this.metadata,
      required final Map<String, dynamic> sharedPreferences,
      required final List<DatabaseFile> databases})
      : _sharedPreferences = sharedPreferences,
        _databases = databases;
  factory _BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);

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

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupDataCopyWith<_BackupData> get copyWith =>
      __$BackupDataCopyWithImpl<_BackupData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BackupDataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupData &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other._sharedPreferences, _sharedPreferences) &&
            const DeepCollectionEquality()
                .equals(other._databases, _databases));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      metadata,
      const DeepCollectionEquality().hash(_sharedPreferences),
      const DeepCollectionEquality().hash(_databases));

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, sharedPreferences: $sharedPreferences, databases: $databases)';
  }
}

/// @nodoc
abstract mixin class _$BackupDataCopyWith<$Res>
    implements $BackupDataCopyWith<$Res> {
  factory _$BackupDataCopyWith(
          _BackupData value, $Res Function(_BackupData) _then) =
      __$BackupDataCopyWithImpl;
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
class __$BackupDataCopyWithImpl<$Res> implements _$BackupDataCopyWith<$Res> {
  __$BackupDataCopyWithImpl(this._self, this._then);

  final _BackupData _self;
  final $Res Function(_BackupData) _then;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? metadata = null,
    Object? sharedPreferences = null,
    Object? databases = null,
  }) {
    return _then(_BackupData(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      sharedPreferences: null == sharedPreferences
          ? _self._sharedPreferences
          : sharedPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      databases: null == databases
          ? _self._databases
          : databases // ignore: cast_nullable_to_non_nullable
              as List<DatabaseFile>,
    ));
  }

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// @nodoc
mixin _$BackupMetadata {
  String get appVersion;
  String get buildNumber;
  int get timestamp;
  String get platform;
  int get backupCode;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<BackupMetadata> get copyWith =>
      _$BackupMetadataCopyWithImpl<BackupMetadata>(
          this as BackupMetadata, _$identity);

  /// Serializes this BackupMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupMetadata &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, appVersion, buildNumber, timestamp, platform, backupCode);

  @override
  String toString() {
    return 'BackupMetadata(appVersion: $appVersion, buildNumber: $buildNumber, timestamp: $timestamp, platform: $platform, backupCode: $backupCode)';
  }
}

/// @nodoc
abstract mixin class $BackupMetadataCopyWith<$Res> {
  factory $BackupMetadataCopyWith(
          BackupMetadata value, $Res Function(BackupMetadata) _then) =
      _$BackupMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String appVersion,
      String buildNumber,
      int timestamp,
      String platform,
      int backupCode});
}

/// @nodoc
class _$BackupMetadataCopyWithImpl<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  _$BackupMetadataCopyWithImpl(this._self, this._then);

  final BackupMetadata _self;
  final $Res Function(BackupMetadata) _then;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appVersion = null,
    Object? buildNumber = null,
    Object? timestamp = null,
    Object? platform = null,
    Object? backupCode = null,
  }) {
    return _then(_self.copyWith(
      appVersion: null == appVersion
          ? _self.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _self.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      platform: null == platform
          ? _self.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      backupCode: null == backupCode
          ? _self.backupCode
          : backupCode // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [BackupMetadata].
extension BackupMetadataPatterns on BackupMetadata {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String appVersion, String buildNumber, int timestamp,
            String platform, int backupCode)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(_that.appVersion, _that.buildNumber, _that.timestamp,
            _that.platform, _that.backupCode);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String appVersion, String buildNumber, int timestamp,
            String platform, int backupCode)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata():
        return $default(_that.appVersion, _that.buildNumber, _that.timestamp,
            _that.platform, _that.backupCode);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String appVersion, String buildNumber, int timestamp,
            String platform, int backupCode)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(_that.appVersion, _that.buildNumber, _that.timestamp,
            _that.platform, _that.backupCode);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BackupMetadata implements BackupMetadata {
  const _BackupMetadata(
      {required this.appVersion,
      required this.buildNumber,
      required this.timestamp,
      required this.platform,
      required this.backupCode});
  factory _BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);

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

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupMetadataCopyWith<_BackupMetadata> get copyWith =>
      __$BackupMetadataCopyWithImpl<_BackupMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BackupMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupMetadata &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, appVersion, buildNumber, timestamp, platform, backupCode);

  @override
  String toString() {
    return 'BackupMetadata(appVersion: $appVersion, buildNumber: $buildNumber, timestamp: $timestamp, platform: $platform, backupCode: $backupCode)';
  }
}

/// @nodoc
abstract mixin class _$BackupMetadataCopyWith<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  factory _$BackupMetadataCopyWith(
          _BackupMetadata value, $Res Function(_BackupMetadata) _then) =
      __$BackupMetadataCopyWithImpl;
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
class __$BackupMetadataCopyWithImpl<$Res>
    implements _$BackupMetadataCopyWith<$Res> {
  __$BackupMetadataCopyWithImpl(this._self, this._then);

  final _BackupMetadata _self;
  final $Res Function(_BackupMetadata) _then;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? appVersion = null,
    Object? buildNumber = null,
    Object? timestamp = null,
    Object? platform = null,
    Object? backupCode = null,
  }) {
    return _then(_BackupMetadata(
      appVersion: null == appVersion
          ? _self.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      buildNumber: null == buildNumber
          ? _self.buildNumber
          : buildNumber // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      platform: null == platform
          ? _self.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      backupCode: null == backupCode
          ? _self.backupCode
          : backupCode // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$DatabaseFile {
  String get name;
  String get relativePath;
  int get size;
  String get checksum;

  /// Create a copy of DatabaseFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DatabaseFileCopyWith<DatabaseFile> get copyWith =>
      _$DatabaseFileCopyWithImpl<DatabaseFile>(
          this as DatabaseFile, _$identity);

  /// Serializes this DatabaseFile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DatabaseFile &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, relativePath, size, checksum);

  @override
  String toString() {
    return 'DatabaseFile(name: $name, relativePath: $relativePath, size: $size, checksum: $checksum)';
  }
}

/// @nodoc
abstract mixin class $DatabaseFileCopyWith<$Res> {
  factory $DatabaseFileCopyWith(
          DatabaseFile value, $Res Function(DatabaseFile) _then) =
      _$DatabaseFileCopyWithImpl;
  @useResult
  $Res call({String name, String relativePath, int size, String checksum});
}

/// @nodoc
class _$DatabaseFileCopyWithImpl<$Res> implements $DatabaseFileCopyWith<$Res> {
  _$DatabaseFileCopyWithImpl(this._self, this._then);

  final DatabaseFile _self;
  final $Res Function(DatabaseFile) _then;

  /// Create a copy of DatabaseFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? size = null,
    Object? checksum = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _self.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _self.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [DatabaseFile].
extension DatabaseFilePatterns on DatabaseFile {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DatabaseFile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DatabaseFile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DatabaseFile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String name, String relativePath, int size, String checksum)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile() when $default != null:
        return $default(
            _that.name, _that.relativePath, _that.size, _that.checksum);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String name, String relativePath, int size, String checksum)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile():
        return $default(
            _that.name, _that.relativePath, _that.size, _that.checksum);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String name, String relativePath, int size, String checksum)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DatabaseFile() when $default != null:
        return $default(
            _that.name, _that.relativePath, _that.size, _that.checksum);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DatabaseFile implements DatabaseFile {
  const _DatabaseFile(
      {required this.name,
      required this.relativePath,
      required this.size,
      required this.checksum});
  factory _DatabaseFile.fromJson(Map<String, dynamic> json) =>
      _$DatabaseFileFromJson(json);

  @override
  final String name;
  @override
  final String relativePath;
  @override
  final int size;
  @override
  final String checksum;

  /// Create a copy of DatabaseFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DatabaseFileCopyWith<_DatabaseFile> get copyWith =>
      __$DatabaseFileCopyWithImpl<_DatabaseFile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DatabaseFileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DatabaseFile &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, relativePath, size, checksum);

  @override
  String toString() {
    return 'DatabaseFile(name: $name, relativePath: $relativePath, size: $size, checksum: $checksum)';
  }
}

/// @nodoc
abstract mixin class _$DatabaseFileCopyWith<$Res>
    implements $DatabaseFileCopyWith<$Res> {
  factory _$DatabaseFileCopyWith(
          _DatabaseFile value, $Res Function(_DatabaseFile) _then) =
      __$DatabaseFileCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String relativePath, int size, String checksum});
}

/// @nodoc
class __$DatabaseFileCopyWithImpl<$Res>
    implements _$DatabaseFileCopyWith<$Res> {
  __$DatabaseFileCopyWithImpl(this._self, this._then);

  final _DatabaseFile _self;
  final $Res Function(_DatabaseFile) _then;

  /// Create a copy of DatabaseFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? size = null,
    Object? checksum = null,
  }) {
    return _then(_DatabaseFile(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _self.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _self.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$BackupState {
  bool get isLoading;
  bool get isExporting;
  bool get isImporting;
  double get progress;
  String? get currentOperation;
  String? get error;
  String? get lastExportPath;
  BackupMetadata? get lastImportMetadata;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupStateCopyWith<BackupState> get copyWith =>
      _$BackupStateCopyWithImpl<BackupState>(this as BackupState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupState &&
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

  @override
  String toString() {
    return 'BackupState(isLoading: $isLoading, isExporting: $isExporting, isImporting: $isImporting, progress: $progress, currentOperation: $currentOperation, error: $error, lastExportPath: $lastExportPath, lastImportMetadata: $lastImportMetadata)';
  }
}

/// @nodoc
abstract mixin class $BackupStateCopyWith<$Res> {
  factory $BackupStateCopyWith(
          BackupState value, $Res Function(BackupState) _then) =
      _$BackupStateCopyWithImpl;
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
class _$BackupStateCopyWithImpl<$Res> implements $BackupStateCopyWith<$Res> {
  _$BackupStateCopyWithImpl(this._self, this._then);

  final BackupState _self;
  final $Res Function(BackupState) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExporting: null == isExporting
          ? _self.isExporting
          : isExporting // ignore: cast_nullable_to_non_nullable
              as bool,
      isImporting: null == isImporting
          ? _self.isImporting
          : isImporting // ignore: cast_nullable_to_non_nullable
              as bool,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentOperation: freezed == currentOperation
          ? _self.currentOperation
          : currentOperation // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastExportPath: freezed == lastExportPath
          ? _self.lastExportPath
          : lastExportPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastImportMetadata: freezed == lastImportMetadata
          ? _self.lastImportMetadata
          : lastImportMetadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
    ));
  }

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get lastImportMetadata {
    if (_self.lastImportMetadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_self.lastImportMetadata!, (value) {
      return _then(_self.copyWith(lastImportMetadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BackupState].
extension BackupStatePatterns on BackupState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupState():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool isLoading,
            bool isExporting,
            bool isImporting,
            double progress,
            String? currentOperation,
            String? error,
            String? lastExportPath,
            BackupMetadata? lastImportMetadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupState() when $default != null:
        return $default(
            _that.isLoading,
            _that.isExporting,
            _that.isImporting,
            _that.progress,
            _that.currentOperation,
            _that.error,
            _that.lastExportPath,
            _that.lastImportMetadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool isLoading,
            bool isExporting,
            bool isImporting,
            double progress,
            String? currentOperation,
            String? error,
            String? lastExportPath,
            BackupMetadata? lastImportMetadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupState():
        return $default(
            _that.isLoading,
            _that.isExporting,
            _that.isImporting,
            _that.progress,
            _that.currentOperation,
            _that.error,
            _that.lastExportPath,
            _that.lastImportMetadata);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool isLoading,
            bool isExporting,
            bool isImporting,
            double progress,
            String? currentOperation,
            String? error,
            String? lastExportPath,
            BackupMetadata? lastImportMetadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupState() when $default != null:
        return $default(
            _that.isLoading,
            _that.isExporting,
            _that.isImporting,
            _that.progress,
            _that.currentOperation,
            _that.error,
            _that.lastExportPath,
            _that.lastImportMetadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BackupState implements BackupState {
  const _BackupState(
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

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupStateCopyWith<_BackupState> get copyWith =>
      __$BackupStateCopyWithImpl<_BackupState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupState &&
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

  @override
  String toString() {
    return 'BackupState(isLoading: $isLoading, isExporting: $isExporting, isImporting: $isImporting, progress: $progress, currentOperation: $currentOperation, error: $error, lastExportPath: $lastExportPath, lastImportMetadata: $lastImportMetadata)';
  }
}

/// @nodoc
abstract mixin class _$BackupStateCopyWith<$Res>
    implements $BackupStateCopyWith<$Res> {
  factory _$BackupStateCopyWith(
          _BackupState value, $Res Function(_BackupState) _then) =
      __$BackupStateCopyWithImpl;
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
class __$BackupStateCopyWithImpl<$Res> implements _$BackupStateCopyWith<$Res> {
  __$BackupStateCopyWithImpl(this._self, this._then);

  final _BackupState _self;
  final $Res Function(_BackupState) _then;

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_BackupState(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExporting: null == isExporting
          ? _self.isExporting
          : isExporting // ignore: cast_nullable_to_non_nullable
              as bool,
      isImporting: null == isImporting
          ? _self.isImporting
          : isImporting // ignore: cast_nullable_to_non_nullable
              as bool,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentOperation: freezed == currentOperation
          ? _self.currentOperation
          : currentOperation // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastExportPath: freezed == lastExportPath
          ? _self.lastExportPath
          : lastExportPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastImportMetadata: freezed == lastImportMetadata
          ? _self.lastImportMetadata
          : lastImportMetadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
    ));
  }

  /// Create a copy of BackupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get lastImportMetadata {
    if (_self.lastImportMetadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_self.lastImportMetadata!, (value) {
      return _then(_self.copyWith(lastImportMetadata: value));
    });
  }
}

/// @nodoc
mixin _$CompatibilityInfo {
  CompatibilityLevel get level;
  String get message;
  List<String>? get warnings;
  List<String>? get errors;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CompatibilityInfoCopyWith<CompatibilityInfo> get copyWith =>
      _$CompatibilityInfoCopyWithImpl<CompatibilityInfo>(
          this as CompatibilityInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CompatibilityInfo &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other.warnings, warnings) &&
            const DeepCollectionEquality().equals(other.errors, errors));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      message,
      const DeepCollectionEquality().hash(warnings),
      const DeepCollectionEquality().hash(errors));

  @override
  String toString() {
    return 'CompatibilityInfo(level: $level, message: $message, warnings: $warnings, errors: $errors)';
  }
}

/// @nodoc
abstract mixin class $CompatibilityInfoCopyWith<$Res> {
  factory $CompatibilityInfoCopyWith(
          CompatibilityInfo value, $Res Function(CompatibilityInfo) _then) =
      _$CompatibilityInfoCopyWithImpl;
  @useResult
  $Res call(
      {CompatibilityLevel level,
      String message,
      List<String>? warnings,
      List<String>? errors});
}

/// @nodoc
class _$CompatibilityInfoCopyWithImpl<$Res>
    implements $CompatibilityInfoCopyWith<$Res> {
  _$CompatibilityInfoCopyWithImpl(this._self, this._then);

  final CompatibilityInfo _self;
  final $Res Function(CompatibilityInfo) _then;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? message = null,
    Object? warnings = freezed,
    Object? errors = freezed,
  }) {
    return _then(_self.copyWith(
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      warnings: freezed == warnings
          ? _self.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      errors: freezed == errors
          ? _self.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CompatibilityInfo].
extension CompatibilityInfoPatterns on CompatibilityInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CompatibilityInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CompatibilityInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CompatibilityInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(CompatibilityLevel level, String message,
            List<String>? warnings, List<String>? errors)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo() when $default != null:
        return $default(
            _that.level, _that.message, _that.warnings, _that.errors);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(CompatibilityLevel level, String message,
            List<String>? warnings, List<String>? errors)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo():
        return $default(
            _that.level, _that.message, _that.warnings, _that.errors);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(CompatibilityLevel level, String message,
            List<String>? warnings, List<String>? errors)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CompatibilityInfo() when $default != null:
        return $default(
            _that.level, _that.message, _that.warnings, _that.errors);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CompatibilityInfo implements CompatibilityInfo {
  const _CompatibilityInfo(
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

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CompatibilityInfoCopyWith<_CompatibilityInfo> get copyWith =>
      __$CompatibilityInfoCopyWithImpl<_CompatibilityInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CompatibilityInfo &&
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

  @override
  String toString() {
    return 'CompatibilityInfo(level: $level, message: $message, warnings: $warnings, errors: $errors)';
  }
}

/// @nodoc
abstract mixin class _$CompatibilityInfoCopyWith<$Res>
    implements $CompatibilityInfoCopyWith<$Res> {
  factory _$CompatibilityInfoCopyWith(
          _CompatibilityInfo value, $Res Function(_CompatibilityInfo) _then) =
      __$CompatibilityInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {CompatibilityLevel level,
      String message,
      List<String>? warnings,
      List<String>? errors});
}

/// @nodoc
class __$CompatibilityInfoCopyWithImpl<$Res>
    implements _$CompatibilityInfoCopyWith<$Res> {
  __$CompatibilityInfoCopyWithImpl(this._self, this._then);

  final _CompatibilityInfo _self;
  final $Res Function(_CompatibilityInfo) _then;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? level = null,
    Object? message = null,
    Object? warnings = freezed,
    Object? errors = freezed,
  }) {
    return _then(_CompatibilityInfo(
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      warnings: freezed == warnings
          ? _self._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      errors: freezed == errors
          ? _self._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
mixin _$ImportOptions {
  bool get importSharedPreferences;
  bool get importDatabases;
  bool get createBackup;
  bool get forceImport;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportOptionsCopyWith<ImportOptions> get copyWith =>
      _$ImportOptionsCopyWithImpl<ImportOptions>(
          this as ImportOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportOptions &&
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

  @override
  String toString() {
    return 'ImportOptions(importSharedPreferences: $importSharedPreferences, importDatabases: $importDatabases, createBackup: $createBackup, forceImport: $forceImport)';
  }
}

/// @nodoc
abstract mixin class $ImportOptionsCopyWith<$Res> {
  factory $ImportOptionsCopyWith(
          ImportOptions value, $Res Function(ImportOptions) _then) =
      _$ImportOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool importSharedPreferences,
      bool importDatabases,
      bool createBackup,
      bool forceImport});
}

/// @nodoc
class _$ImportOptionsCopyWithImpl<$Res>
    implements $ImportOptionsCopyWith<$Res> {
  _$ImportOptionsCopyWithImpl(this._self, this._then);

  final ImportOptions _self;
  final $Res Function(ImportOptions) _then;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? importSharedPreferences = null,
    Object? importDatabases = null,
    Object? createBackup = null,
    Object? forceImport = null,
  }) {
    return _then(_self.copyWith(
      importSharedPreferences: null == importSharedPreferences
          ? _self.importSharedPreferences
          : importSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      importDatabases: null == importDatabases
          ? _self.importDatabases
          : importDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _self.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      forceImport: null == forceImport
          ? _self.forceImport
          : forceImport // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ImportOptions].
extension ImportOptionsPatterns on ImportOptions {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ImportOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImportOptions() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ImportOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportOptions():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ImportOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportOptions() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(bool importSharedPreferences, bool importDatabases,
            bool createBackup, bool forceImport)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImportOptions() when $default != null:
        return $default(_that.importSharedPreferences, _that.importDatabases,
            _that.createBackup, _that.forceImport);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(bool importSharedPreferences, bool importDatabases,
            bool createBackup, bool forceImport)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportOptions():
        return $default(_that.importSharedPreferences, _that.importDatabases,
            _that.createBackup, _that.forceImport);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(bool importSharedPreferences, bool importDatabases,
            bool createBackup, bool forceImport)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportOptions() when $default != null:
        return $default(_that.importSharedPreferences, _that.importDatabases,
            _that.createBackup, _that.forceImport);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ImportOptions implements ImportOptions {
  const _ImportOptions(
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

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ImportOptionsCopyWith<_ImportOptions> get copyWith =>
      __$ImportOptionsCopyWithImpl<_ImportOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ImportOptions &&
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

  @override
  String toString() {
    return 'ImportOptions(importSharedPreferences: $importSharedPreferences, importDatabases: $importDatabases, createBackup: $createBackup, forceImport: $forceImport)';
  }
}

/// @nodoc
abstract mixin class _$ImportOptionsCopyWith<$Res>
    implements $ImportOptionsCopyWith<$Res> {
  factory _$ImportOptionsCopyWith(
          _ImportOptions value, $Res Function(_ImportOptions) _then) =
      __$ImportOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool importSharedPreferences,
      bool importDatabases,
      bool createBackup,
      bool forceImport});
}

/// @nodoc
class __$ImportOptionsCopyWithImpl<$Res>
    implements _$ImportOptionsCopyWith<$Res> {
  __$ImportOptionsCopyWithImpl(this._self, this._then);

  final _ImportOptions _self;
  final $Res Function(_ImportOptions) _then;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? importSharedPreferences = null,
    Object? importDatabases = null,
    Object? createBackup = null,
    Object? forceImport = null,
  }) {
    return _then(_ImportOptions(
      importSharedPreferences: null == importSharedPreferences
          ? _self.importSharedPreferences
          : importSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      importDatabases: null == importDatabases
          ? _self.importDatabases
          : importDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _self.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      forceImport: null == forceImport
          ? _self.forceImport
          : forceImport // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$RestoreOptions {
  bool get restoreSharedPreferences;
  bool get restoreDatabases;
  bool get forceRestore;

  /// Create a copy of RestoreOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RestoreOptionsCopyWith<RestoreOptions> get copyWith =>
      _$RestoreOptionsCopyWithImpl<RestoreOptions>(
          this as RestoreOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RestoreOptions &&
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

  @override
  String toString() {
    return 'RestoreOptions(restoreSharedPreferences: $restoreSharedPreferences, restoreDatabases: $restoreDatabases, forceRestore: $forceRestore)';
  }
}

/// @nodoc
abstract mixin class $RestoreOptionsCopyWith<$Res> {
  factory $RestoreOptionsCopyWith(
          RestoreOptions value, $Res Function(RestoreOptions) _then) =
      _$RestoreOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool restoreSharedPreferences,
      bool restoreDatabases,
      bool forceRestore});
}

/// @nodoc
class _$RestoreOptionsCopyWithImpl<$Res>
    implements $RestoreOptionsCopyWith<$Res> {
  _$RestoreOptionsCopyWithImpl(this._self, this._then);

  final RestoreOptions _self;
  final $Res Function(RestoreOptions) _then;

  /// Create a copy of RestoreOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? restoreSharedPreferences = null,
    Object? restoreDatabases = null,
    Object? forceRestore = null,
  }) {
    return _then(_self.copyWith(
      restoreSharedPreferences: null == restoreSharedPreferences
          ? _self.restoreSharedPreferences
          : restoreSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      restoreDatabases: null == restoreDatabases
          ? _self.restoreDatabases
          : restoreDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      forceRestore: null == forceRestore
          ? _self.forceRestore
          : forceRestore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [RestoreOptions].
extension RestoreOptionsPatterns on RestoreOptions {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RestoreOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RestoreOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RestoreOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(bool restoreSharedPreferences, bool restoreDatabases,
            bool forceRestore)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions() when $default != null:
        return $default(_that.restoreSharedPreferences, _that.restoreDatabases,
            _that.forceRestore);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(bool restoreSharedPreferences, bool restoreDatabases,
            bool forceRestore)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions():
        return $default(_that.restoreSharedPreferences, _that.restoreDatabases,
            _that.forceRestore);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(bool restoreSharedPreferences, bool restoreDatabases,
            bool forceRestore)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RestoreOptions() when $default != null:
        return $default(_that.restoreSharedPreferences, _that.restoreDatabases,
            _that.forceRestore);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RestoreOptions implements RestoreOptions {
  const _RestoreOptions(
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

  /// Create a copy of RestoreOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RestoreOptionsCopyWith<_RestoreOptions> get copyWith =>
      __$RestoreOptionsCopyWithImpl<_RestoreOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RestoreOptions &&
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

  @override
  String toString() {
    return 'RestoreOptions(restoreSharedPreferences: $restoreSharedPreferences, restoreDatabases: $restoreDatabases, forceRestore: $forceRestore)';
  }
}

/// @nodoc
abstract mixin class _$RestoreOptionsCopyWith<$Res>
    implements $RestoreOptionsCopyWith<$Res> {
  factory _$RestoreOptionsCopyWith(
          _RestoreOptions value, $Res Function(_RestoreOptions) _then) =
      __$RestoreOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool restoreSharedPreferences,
      bool restoreDatabases,
      bool forceRestore});
}

/// @nodoc
class __$RestoreOptionsCopyWithImpl<$Res>
    implements _$RestoreOptionsCopyWith<$Res> {
  __$RestoreOptionsCopyWithImpl(this._self, this._then);

  final _RestoreOptions _self;
  final $Res Function(_RestoreOptions) _then;

  /// Create a copy of RestoreOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? restoreSharedPreferences = null,
    Object? restoreDatabases = null,
    Object? forceRestore = null,
  }) {
    return _then(_RestoreOptions(
      restoreSharedPreferences: null == restoreSharedPreferences
          ? _self.restoreSharedPreferences
          : restoreSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      restoreDatabases: null == restoreDatabases
          ? _self.restoreDatabases
          : restoreDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      forceRestore: null == forceRestore
          ? _self.forceRestore
          : forceRestore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$BackupFileInfo {
  String get fileName;
  String get filePath;
  int get fileSize;
  DateTime get createdTime;
  BackupMetadata? get metadata;
  String? get description;

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupFileInfoCopyWith<BackupFileInfo> get copyWith =>
      _$BackupFileInfoCopyWithImpl<BackupFileInfo>(
          this as BackupFileInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupFileInfo &&
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

  @override
  String toString() {
    return 'BackupFileInfo(fileName: $fileName, filePath: $filePath, fileSize: $fileSize, createdTime: $createdTime, metadata: $metadata, description: $description)';
  }
}

/// @nodoc
abstract mixin class $BackupFileInfoCopyWith<$Res> {
  factory $BackupFileInfoCopyWith(
          BackupFileInfo value, $Res Function(BackupFileInfo) _then) =
      _$BackupFileInfoCopyWithImpl;
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
class _$BackupFileInfoCopyWithImpl<$Res>
    implements $BackupFileInfoCopyWith<$Res> {
  _$BackupFileInfoCopyWithImpl(this._self, this._then);

  final BackupFileInfo _self;
  final $Res Function(BackupFileInfo) _then;

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      createdTime: null == createdTime
          ? _self.createdTime
          : createdTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_self.metadata!, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BackupFileInfo].
extension BackupFileInfoPatterns on BackupFileInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupFileInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupFileInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupFileInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String fileName,
            String filePath,
            int fileSize,
            DateTime createdTime,
            BackupMetadata? metadata,
            String? description)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo() when $default != null:
        return $default(_that.fileName, _that.filePath, _that.fileSize,
            _that.createdTime, _that.metadata, _that.description);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String fileName, String filePath, int fileSize,
            DateTime createdTime, BackupMetadata? metadata, String? description)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo():
        return $default(_that.fileName, _that.filePath, _that.fileSize,
            _that.createdTime, _that.metadata, _that.description);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String fileName,
            String filePath,
            int fileSize,
            DateTime createdTime,
            BackupMetadata? metadata,
            String? description)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFileInfo() when $default != null:
        return $default(_that.fileName, _that.filePath, _that.fileSize,
            _that.createdTime, _that.metadata, _that.description);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BackupFileInfo implements BackupFileInfo {
  const _BackupFileInfo(
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

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupFileInfoCopyWith<_BackupFileInfo> get copyWith =>
      __$BackupFileInfoCopyWithImpl<_BackupFileInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupFileInfo &&
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

  @override
  String toString() {
    return 'BackupFileInfo(fileName: $fileName, filePath: $filePath, fileSize: $fileSize, createdTime: $createdTime, metadata: $metadata, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$BackupFileInfoCopyWith<$Res>
    implements $BackupFileInfoCopyWith<$Res> {
  factory _$BackupFileInfoCopyWith(
          _BackupFileInfo value, $Res Function(_BackupFileInfo) _then) =
      __$BackupFileInfoCopyWithImpl;
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
class __$BackupFileInfoCopyWithImpl<$Res>
    implements _$BackupFileInfoCopyWith<$Res> {
  __$BackupFileInfoCopyWithImpl(this._self, this._then);

  final _BackupFileInfo _self;
  final $Res Function(_BackupFileInfo) _then;

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileSize = null,
    Object? createdTime = null,
    Object? metadata = freezed,
    Object? description = freezed,
  }) {
    return _then(_BackupFileInfo(
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      createdTime: null == createdTime
          ? _self.createdTime
          : createdTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of BackupFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
      return null;
    }

    return $BackupMetadataCopyWith<$Res>(_self.metadata!, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// @nodoc
mixin _$BackupFilesState {
  bool get isLoading;
  List<BackupFileInfo> get backupFiles;
  String? get error;

  /// Create a copy of BackupFilesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupFilesStateCopyWith<BackupFilesState> get copyWith =>
      _$BackupFilesStateCopyWithImpl<BackupFilesState>(
          this as BackupFilesState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupFilesState &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other.backupFiles, backupFiles) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading,
      const DeepCollectionEquality().hash(backupFiles), error);

  @override
  String toString() {
    return 'BackupFilesState(isLoading: $isLoading, backupFiles: $backupFiles, error: $error)';
  }
}

/// @nodoc
abstract mixin class $BackupFilesStateCopyWith<$Res> {
  factory $BackupFilesStateCopyWith(
          BackupFilesState value, $Res Function(BackupFilesState) _then) =
      _$BackupFilesStateCopyWithImpl;
  @useResult
  $Res call({bool isLoading, List<BackupFileInfo> backupFiles, String? error});
}

/// @nodoc
class _$BackupFilesStateCopyWithImpl<$Res>
    implements $BackupFilesStateCopyWith<$Res> {
  _$BackupFilesStateCopyWithImpl(this._self, this._then);

  final BackupFilesState _self;
  final $Res Function(BackupFilesState) _then;

  /// Create a copy of BackupFilesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? backupFiles = null,
    Object? error = freezed,
  }) {
    return _then(_self.copyWith(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFiles: null == backupFiles
          ? _self.backupFiles
          : backupFiles // ignore: cast_nullable_to_non_nullable
              as List<BackupFileInfo>,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [BackupFilesState].
extension BackupFilesStatePatterns on BackupFilesState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupFilesState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupFilesState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupFilesState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool isLoading, List<BackupFileInfo> backupFiles, String? error)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState() when $default != null:
        return $default(_that.isLoading, _that.backupFiles, _that.error);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool isLoading, List<BackupFileInfo> backupFiles, String? error)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState():
        return $default(_that.isLoading, _that.backupFiles, _that.error);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool isLoading, List<BackupFileInfo> backupFiles, String? error)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupFilesState() when $default != null:
        return $default(_that.isLoading, _that.backupFiles, _that.error);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BackupFilesState implements BackupFilesState {
  const _BackupFilesState(
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

  /// Create a copy of BackupFilesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupFilesStateCopyWith<_BackupFilesState> get copyWith =>
      __$BackupFilesStateCopyWithImpl<_BackupFilesState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupFilesState &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other._backupFiles, _backupFiles) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading,
      const DeepCollectionEquality().hash(_backupFiles), error);

  @override
  String toString() {
    return 'BackupFilesState(isLoading: $isLoading, backupFiles: $backupFiles, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$BackupFilesStateCopyWith<$Res>
    implements $BackupFilesStateCopyWith<$Res> {
  factory _$BackupFilesStateCopyWith(
          _BackupFilesState value, $Res Function(_BackupFilesState) _then) =
      __$BackupFilesStateCopyWithImpl;
  @override
  @useResult
  $Res call({bool isLoading, List<BackupFileInfo> backupFiles, String? error});
}

/// @nodoc
class __$BackupFilesStateCopyWithImpl<$Res>
    implements _$BackupFilesStateCopyWith<$Res> {
  __$BackupFilesStateCopyWithImpl(this._self, this._then);

  final _BackupFilesState _self;
  final $Res Function(_BackupFilesState) _then;

  /// Create a copy of BackupFilesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isLoading = null,
    Object? backupFiles = null,
    Object? error = freezed,
  }) {
    return _then(_BackupFilesState(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFiles: null == backupFiles
          ? _self._backupFiles
          : backupFiles // ignore: cast_nullable_to_non_nullable
              as List<BackupFileInfo>,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$ExportOptions {
  bool get includeSharedPreferences;
  bool get includeDatabases;
  String? get customPath;
  String? get customFileName;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExportOptionsCopyWith<ExportOptions> get copyWith =>
      _$ExportOptionsCopyWithImpl<ExportOptions>(
          this as ExportOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExportOptions &&
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

  @override
  String toString() {
    return 'ExportOptions(includeSharedPreferences: $includeSharedPreferences, includeDatabases: $includeDatabases, customPath: $customPath, customFileName: $customFileName)';
  }
}

/// @nodoc
abstract mixin class $ExportOptionsCopyWith<$Res> {
  factory $ExportOptionsCopyWith(
          ExportOptions value, $Res Function(ExportOptions) _then) =
      _$ExportOptionsCopyWithImpl;
  @useResult
  $Res call(
      {bool includeSharedPreferences,
      bool includeDatabases,
      String? customPath,
      String? customFileName});
}

/// @nodoc
class _$ExportOptionsCopyWithImpl<$Res>
    implements $ExportOptionsCopyWith<$Res> {
  _$ExportOptionsCopyWithImpl(this._self, this._then);

  final ExportOptions _self;
  final $Res Function(ExportOptions) _then;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? includeSharedPreferences = null,
    Object? includeDatabases = null,
    Object? customPath = freezed,
    Object? customFileName = freezed,
  }) {
    return _then(_self.copyWith(
      includeSharedPreferences: null == includeSharedPreferences
          ? _self.includeSharedPreferences
          : includeSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      includeDatabases: null == includeDatabases
          ? _self.includeDatabases
          : includeDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      customPath: freezed == customPath
          ? _self.customPath
          : customPath // ignore: cast_nullable_to_non_nullable
              as String?,
      customFileName: freezed == customFileName
          ? _self.customFileName
          : customFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExportOptions].
extension ExportOptionsPatterns on ExportOptions {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ExportOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExportOptions() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ExportOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExportOptions():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ExportOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExportOptions() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(bool includeSharedPreferences, bool includeDatabases,
            String? customPath, String? customFileName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExportOptions() when $default != null:
        return $default(_that.includeSharedPreferences, _that.includeDatabases,
            _that.customPath, _that.customFileName);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(bool includeSharedPreferences, bool includeDatabases,
            String? customPath, String? customFileName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExportOptions():
        return $default(_that.includeSharedPreferences, _that.includeDatabases,
            _that.customPath, _that.customFileName);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(bool includeSharedPreferences, bool includeDatabases,
            String? customPath, String? customFileName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExportOptions() when $default != null:
        return $default(_that.includeSharedPreferences, _that.includeDatabases,
            _that.customPath, _that.customFileName);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ExportOptions implements ExportOptions {
  const _ExportOptions(
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

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExportOptionsCopyWith<_ExportOptions> get copyWith =>
      __$ExportOptionsCopyWithImpl<_ExportOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExportOptions &&
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

  @override
  String toString() {
    return 'ExportOptions(includeSharedPreferences: $includeSharedPreferences, includeDatabases: $includeDatabases, customPath: $customPath, customFileName: $customFileName)';
  }
}

/// @nodoc
abstract mixin class _$ExportOptionsCopyWith<$Res>
    implements $ExportOptionsCopyWith<$Res> {
  factory _$ExportOptionsCopyWith(
          _ExportOptions value, $Res Function(_ExportOptions) _then) =
      __$ExportOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool includeSharedPreferences,
      bool includeDatabases,
      String? customPath,
      String? customFileName});
}

/// @nodoc
class __$ExportOptionsCopyWithImpl<$Res>
    implements _$ExportOptionsCopyWith<$Res> {
  __$ExportOptionsCopyWithImpl(this._self, this._then);

  final _ExportOptions _self;
  final $Res Function(_ExportOptions) _then;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? includeSharedPreferences = null,
    Object? includeDatabases = null,
    Object? customPath = freezed,
    Object? customFileName = freezed,
  }) {
    return _then(_ExportOptions(
      includeSharedPreferences: null == includeSharedPreferences
          ? _self.includeSharedPreferences
          : includeSharedPreferences // ignore: cast_nullable_to_non_nullable
              as bool,
      includeDatabases: null == includeDatabases
          ? _self.includeDatabases
          : includeDatabases // ignore: cast_nullable_to_non_nullable
              as bool,
      customPath: freezed == customPath
          ? _self.customPath
          : customPath // ignore: cast_nullable_to_non_nullable
              as String?,
      customFileName: freezed == customFileName
          ? _self.customFileName
          : customFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$HashInfo {
  String get algorithm;
  String get hash;
  String get timestamp;

  /// Create a copy of HashInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HashInfoCopyWith<HashInfo> get copyWith =>
      _$HashInfoCopyWithImpl<HashInfo>(this as HashInfo, _$identity);

  /// Serializes this HashInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HashInfo &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, algorithm, hash, timestamp);

  @override
  String toString() {
    return 'HashInfo(algorithm: $algorithm, hash: $hash, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $HashInfoCopyWith<$Res> {
  factory $HashInfoCopyWith(HashInfo value, $Res Function(HashInfo) _then) =
      _$HashInfoCopyWithImpl;
  @useResult
  $Res call({String algorithm, String hash, String timestamp});
}

/// @nodoc
class _$HashInfoCopyWithImpl<$Res> implements $HashInfoCopyWith<$Res> {
  _$HashInfoCopyWithImpl(this._self, this._then);

  final HashInfo _self;
  final $Res Function(HashInfo) _then;

  /// Create a copy of HashInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithm = null,
    Object? hash = null,
    Object? timestamp = null,
  }) {
    return _then(_self.copyWith(
      algorithm: null == algorithm
          ? _self.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [HashInfo].
extension HashInfoPatterns on HashInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_HashInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HashInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_HashInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HashInfo():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_HashInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HashInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String algorithm, String hash, String timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HashInfo() when $default != null:
        return $default(_that.algorithm, _that.hash, _that.timestamp);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String algorithm, String hash, String timestamp) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HashInfo():
        return $default(_that.algorithm, _that.hash, _that.timestamp);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String algorithm, String hash, String timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HashInfo() when $default != null:
        return $default(_that.algorithm, _that.hash, _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HashInfo implements HashInfo {
  const _HashInfo(
      {required this.algorithm, required this.hash, required this.timestamp});
  factory _HashInfo.fromJson(Map<String, dynamic> json) =>
      _$HashInfoFromJson(json);

  @override
  final String algorithm;
  @override
  final String hash;
  @override
  final String timestamp;

  /// Create a copy of HashInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HashInfoCopyWith<_HashInfo> get copyWith =>
      __$HashInfoCopyWithImpl<_HashInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HashInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HashInfo &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, algorithm, hash, timestamp);

  @override
  String toString() {
    return 'HashInfo(algorithm: $algorithm, hash: $hash, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$HashInfoCopyWith<$Res>
    implements $HashInfoCopyWith<$Res> {
  factory _$HashInfoCopyWith(_HashInfo value, $Res Function(_HashInfo) _then) =
      __$HashInfoCopyWithImpl;
  @override
  @useResult
  $Res call({String algorithm, String hash, String timestamp});
}

/// @nodoc
class __$HashInfoCopyWithImpl<$Res> implements _$HashInfoCopyWith<$Res> {
  __$HashInfoCopyWithImpl(this._self, this._then);

  final _HashInfo _self;
  final $Res Function(_HashInfo) _then;

  /// Create a copy of HashInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithm = null,
    Object? hash = null,
    Object? timestamp = null,
  }) {
    return _then(_HashInfo(
      algorithm: null == algorithm
          ? _self.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$BackupPreviewInfo {
  BackupMetadata get metadata;
  Map<String, dynamic> get dataStatistics;
  List<String> get dataTypes;
  bool get hasHash;
  bool get hashValid;
  String? get hashError;
  CompatibilityInfo? get compatibilityInfo;

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupPreviewInfoCopyWith<BackupPreviewInfo> get copyWith =>
      _$BackupPreviewInfoCopyWithImpl<BackupPreviewInfo>(
          this as BackupPreviewInfo, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupPreviewInfo &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other.dataStatistics, dataStatistics) &&
            const DeepCollectionEquality().equals(other.dataTypes, dataTypes) &&
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
      const DeepCollectionEquality().hash(dataStatistics),
      const DeepCollectionEquality().hash(dataTypes),
      hasHash,
      hashValid,
      hashError,
      compatibilityInfo);

  @override
  String toString() {
    return 'BackupPreviewInfo(metadata: $metadata, dataStatistics: $dataStatistics, dataTypes: $dataTypes, hasHash: $hasHash, hashValid: $hashValid, hashError: $hashError, compatibilityInfo: $compatibilityInfo)';
  }
}

/// @nodoc
abstract mixin class $BackupPreviewInfoCopyWith<$Res> {
  factory $BackupPreviewInfoCopyWith(
          BackupPreviewInfo value, $Res Function(BackupPreviewInfo) _then) =
      _$BackupPreviewInfoCopyWithImpl;
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
class _$BackupPreviewInfoCopyWithImpl<$Res>
    implements $BackupPreviewInfoCopyWith<$Res> {
  _$BackupPreviewInfoCopyWithImpl(this._self, this._then);

  final BackupPreviewInfo _self;
  final $Res Function(BackupPreviewInfo) _then;

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      dataStatistics: null == dataStatistics
          ? _self.dataStatistics
          : dataStatistics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      dataTypes: null == dataTypes
          ? _self.dataTypes
          : dataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hasHash: null == hasHash
          ? _self.hasHash
          : hasHash // ignore: cast_nullable_to_non_nullable
              as bool,
      hashValid: null == hashValid
          ? _self.hashValid
          : hashValid // ignore: cast_nullable_to_non_nullable
              as bool,
      hashError: freezed == hashError
          ? _self.hashError
          : hashError // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityInfo: freezed == compatibilityInfo
          ? _self.compatibilityInfo
          : compatibilityInfo // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo?,
    ));
  }

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompatibilityInfoCopyWith<$Res>? get compatibilityInfo {
    if (_self.compatibilityInfo == null) {
      return null;
    }

    return $CompatibilityInfoCopyWith<$Res>(_self.compatibilityInfo!, (value) {
      return _then(_self.copyWith(compatibilityInfo: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BackupPreviewInfo].
extension BackupPreviewInfoPatterns on BackupPreviewInfo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BackupPreviewInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BackupPreviewInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BackupPreviewInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            BackupMetadata metadata,
            Map<String, dynamic> dataStatistics,
            List<String> dataTypes,
            bool hasHash,
            bool hashValid,
            String? hashError,
            CompatibilityInfo? compatibilityInfo)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo() when $default != null:
        return $default(
            _that.metadata,
            _that.dataStatistics,
            _that.dataTypes,
            _that.hasHash,
            _that.hashValid,
            _that.hashError,
            _that.compatibilityInfo);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            BackupMetadata metadata,
            Map<String, dynamic> dataStatistics,
            List<String> dataTypes,
            bool hasHash,
            bool hashValid,
            String? hashError,
            CompatibilityInfo? compatibilityInfo)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo():
        return $default(
            _that.metadata,
            _that.dataStatistics,
            _that.dataTypes,
            _that.hasHash,
            _that.hashValid,
            _that.hashError,
            _that.compatibilityInfo);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            BackupMetadata metadata,
            Map<String, dynamic> dataStatistics,
            List<String> dataTypes,
            bool hasHash,
            bool hashValid,
            String? hashError,
            CompatibilityInfo? compatibilityInfo)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupPreviewInfo() when $default != null:
        return $default(
            _that.metadata,
            _that.dataStatistics,
            _that.dataTypes,
            _that.hasHash,
            _that.hashValid,
            _that.hashError,
            _that.compatibilityInfo);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BackupPreviewInfo implements BackupPreviewInfo {
  const _BackupPreviewInfo(
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

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupPreviewInfoCopyWith<_BackupPreviewInfo> get copyWith =>
      __$BackupPreviewInfoCopyWithImpl<_BackupPreviewInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupPreviewInfo &&
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

  @override
  String toString() {
    return 'BackupPreviewInfo(metadata: $metadata, dataStatistics: $dataStatistics, dataTypes: $dataTypes, hasHash: $hasHash, hashValid: $hashValid, hashError: $hashError, compatibilityInfo: $compatibilityInfo)';
  }
}

/// @nodoc
abstract mixin class _$BackupPreviewInfoCopyWith<$Res>
    implements $BackupPreviewInfoCopyWith<$Res> {
  factory _$BackupPreviewInfoCopyWith(
          _BackupPreviewInfo value, $Res Function(_BackupPreviewInfo) _then) =
      __$BackupPreviewInfoCopyWithImpl;
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
class __$BackupPreviewInfoCopyWithImpl<$Res>
    implements _$BackupPreviewInfoCopyWith<$Res> {
  __$BackupPreviewInfoCopyWithImpl(this._self, this._then);

  final _BackupPreviewInfo _self;
  final $Res Function(_BackupPreviewInfo) _then;

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? metadata = null,
    Object? dataStatistics = null,
    Object? dataTypes = null,
    Object? hasHash = null,
    Object? hashValid = null,
    Object? hashError = freezed,
    Object? compatibilityInfo = freezed,
  }) {
    return _then(_BackupPreviewInfo(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as BackupMetadata,
      dataStatistics: null == dataStatistics
          ? _self._dataStatistics
          : dataStatistics // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      dataTypes: null == dataTypes
          ? _self._dataTypes
          : dataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hasHash: null == hasHash
          ? _self.hasHash
          : hasHash // ignore: cast_nullable_to_non_nullable
              as bool,
      hashValid: null == hashValid
          ? _self.hashValid
          : hashValid // ignore: cast_nullable_to_non_nullable
              as bool,
      hashError: freezed == hashError
          ? _self.hashError
          : hashError // ignore: cast_nullable_to_non_nullable
              as String?,
      compatibilityInfo: freezed == compatibilityInfo
          ? _self.compatibilityInfo
          : compatibilityInfo // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo?,
    ));
  }

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }

  /// Create a copy of BackupPreviewInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompatibilityInfoCopyWith<$Res>? get compatibilityInfo {
    if (_self.compatibilityInfo == null) {
      return null;
    }

    return $CompatibilityInfoCopyWith<$Res>(_self.compatibilityInfo!, (value) {
      return _then(_self.copyWith(compatibilityInfo: value));
    });
  }
}

/// @nodoc
mixin _$DataStatistics {
  int get countersCount;
  int get mahjongSessionsCount;
  int get poker50SessionsCount;
  int get templatesCount;
  int get sharedPreferencesCount;
  int get databaseFilesCount;

  /// Create a copy of DataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DataStatisticsCopyWith<DataStatistics> get copyWith =>
      _$DataStatisticsCopyWithImpl<DataStatistics>(
          this as DataStatistics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DataStatistics &&
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

  @override
  String toString() {
    return 'DataStatistics(countersCount: $countersCount, mahjongSessionsCount: $mahjongSessionsCount, poker50SessionsCount: $poker50SessionsCount, templatesCount: $templatesCount, sharedPreferencesCount: $sharedPreferencesCount, databaseFilesCount: $databaseFilesCount)';
  }
}

/// @nodoc
abstract mixin class $DataStatisticsCopyWith<$Res> {
  factory $DataStatisticsCopyWith(
          DataStatistics value, $Res Function(DataStatistics) _then) =
      _$DataStatisticsCopyWithImpl;
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
class _$DataStatisticsCopyWithImpl<$Res>
    implements $DataStatisticsCopyWith<$Res> {
  _$DataStatisticsCopyWithImpl(this._self, this._then);

  final DataStatistics _self;
  final $Res Function(DataStatistics) _then;

  /// Create a copy of DataStatistics
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      countersCount: null == countersCount
          ? _self.countersCount
          : countersCount // ignore: cast_nullable_to_non_nullable
              as int,
      mahjongSessionsCount: null == mahjongSessionsCount
          ? _self.mahjongSessionsCount
          : mahjongSessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      poker50SessionsCount: null == poker50SessionsCount
          ? _self.poker50SessionsCount
          : poker50SessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      templatesCount: null == templatesCount
          ? _self.templatesCount
          : templatesCount // ignore: cast_nullable_to_non_nullable
              as int,
      sharedPreferencesCount: null == sharedPreferencesCount
          ? _self.sharedPreferencesCount
          : sharedPreferencesCount // ignore: cast_nullable_to_non_nullable
              as int,
      databaseFilesCount: null == databaseFilesCount
          ? _self.databaseFilesCount
          : databaseFilesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [DataStatistics].
extension DataStatisticsPatterns on DataStatistics {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DataStatistics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DataStatistics() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DataStatistics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DataStatistics():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DataStatistics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DataStatistics() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int countersCount,
            int mahjongSessionsCount,
            int poker50SessionsCount,
            int templatesCount,
            int sharedPreferencesCount,
            int databaseFilesCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DataStatistics() when $default != null:
        return $default(
            _that.countersCount,
            _that.mahjongSessionsCount,
            _that.poker50SessionsCount,
            _that.templatesCount,
            _that.sharedPreferencesCount,
            _that.databaseFilesCount);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int countersCount,
            int mahjongSessionsCount,
            int poker50SessionsCount,
            int templatesCount,
            int sharedPreferencesCount,
            int databaseFilesCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DataStatistics():
        return $default(
            _that.countersCount,
            _that.mahjongSessionsCount,
            _that.poker50SessionsCount,
            _that.templatesCount,
            _that.sharedPreferencesCount,
            _that.databaseFilesCount);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int countersCount,
            int mahjongSessionsCount,
            int poker50SessionsCount,
            int templatesCount,
            int sharedPreferencesCount,
            int databaseFilesCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DataStatistics() when $default != null:
        return $default(
            _that.countersCount,
            _that.mahjongSessionsCount,
            _that.poker50SessionsCount,
            _that.templatesCount,
            _that.sharedPreferencesCount,
            _that.databaseFilesCount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DataStatistics implements DataStatistics {
  const _DataStatistics(
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

  /// Create a copy of DataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DataStatisticsCopyWith<_DataStatistics> get copyWith =>
      __$DataStatisticsCopyWithImpl<_DataStatistics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DataStatistics &&
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

  @override
  String toString() {
    return 'DataStatistics(countersCount: $countersCount, mahjongSessionsCount: $mahjongSessionsCount, poker50SessionsCount: $poker50SessionsCount, templatesCount: $templatesCount, sharedPreferencesCount: $sharedPreferencesCount, databaseFilesCount: $databaseFilesCount)';
  }
}

/// @nodoc
abstract mixin class _$DataStatisticsCopyWith<$Res>
    implements $DataStatisticsCopyWith<$Res> {
  factory _$DataStatisticsCopyWith(
          _DataStatistics value, $Res Function(_DataStatistics) _then) =
      __$DataStatisticsCopyWithImpl;
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
class __$DataStatisticsCopyWithImpl<$Res>
    implements _$DataStatisticsCopyWith<$Res> {
  __$DataStatisticsCopyWithImpl(this._self, this._then);

  final _DataStatistics _self;
  final $Res Function(_DataStatistics) _then;

  /// Create a copy of DataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? countersCount = null,
    Object? mahjongSessionsCount = null,
    Object? poker50SessionsCount = null,
    Object? templatesCount = null,
    Object? sharedPreferencesCount = null,
    Object? databaseFilesCount = null,
  }) {
    return _then(_DataStatistics(
      countersCount: null == countersCount
          ? _self.countersCount
          : countersCount // ignore: cast_nullable_to_non_nullable
              as int,
      mahjongSessionsCount: null == mahjongSessionsCount
          ? _self.mahjongSessionsCount
          : mahjongSessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      poker50SessionsCount: null == poker50SessionsCount
          ? _self.poker50SessionsCount
          : poker50SessionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      templatesCount: null == templatesCount
          ? _self.templatesCount
          : templatesCount // ignore: cast_nullable_to_non_nullable
              as int,
      sharedPreferencesCount: null == sharedPreferencesCount
          ? _self.sharedPreferencesCount
          : sharedPreferencesCount // ignore: cast_nullable_to_non_nullable
              as int,
      databaseFilesCount: null == databaseFilesCount
          ? _self.databaseFilesCount
          : databaseFilesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$PreviewState {
  bool get isLoading;
  bool get isAnalyzing;
  bool get isCheckingCompatibility;
  BackupPreviewInfo? get previewInfo;
  String? get error;
  String? get selectedFilePath;

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PreviewStateCopyWith<PreviewState> get copyWith =>
      _$PreviewStateCopyWithImpl<PreviewState>(
          this as PreviewState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PreviewState &&
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

  @override
  String toString() {
    return 'PreviewState(isLoading: $isLoading, isAnalyzing: $isAnalyzing, isCheckingCompatibility: $isCheckingCompatibility, previewInfo: $previewInfo, error: $error, selectedFilePath: $selectedFilePath)';
  }
}

/// @nodoc
abstract mixin class $PreviewStateCopyWith<$Res> {
  factory $PreviewStateCopyWith(
          PreviewState value, $Res Function(PreviewState) _then) =
      _$PreviewStateCopyWithImpl;
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
class _$PreviewStateCopyWithImpl<$Res> implements $PreviewStateCopyWith<$Res> {
  _$PreviewStateCopyWithImpl(this._self, this._then);

  final PreviewState _self;
  final $Res Function(PreviewState) _then;

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzing: null == isAnalyzing
          ? _self.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckingCompatibility: null == isCheckingCompatibility
          ? _self.isCheckingCompatibility
          : isCheckingCompatibility // ignore: cast_nullable_to_non_nullable
              as bool,
      previewInfo: freezed == previewInfo
          ? _self.previewInfo
          : previewInfo // ignore: cast_nullable_to_non_nullable
              as BackupPreviewInfo?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFilePath: freezed == selectedFilePath
          ? _self.selectedFilePath
          : selectedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupPreviewInfoCopyWith<$Res>? get previewInfo {
    if (_self.previewInfo == null) {
      return null;
    }

    return $BackupPreviewInfoCopyWith<$Res>(_self.previewInfo!, (value) {
      return _then(_self.copyWith(previewInfo: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PreviewState].
extension PreviewStatePatterns on PreviewState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PreviewState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PreviewState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PreviewState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PreviewState():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PreviewState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PreviewState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool isLoading,
            bool isAnalyzing,
            bool isCheckingCompatibility,
            BackupPreviewInfo? previewInfo,
            String? error,
            String? selectedFilePath)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PreviewState() when $default != null:
        return $default(
            _that.isLoading,
            _that.isAnalyzing,
            _that.isCheckingCompatibility,
            _that.previewInfo,
            _that.error,
            _that.selectedFilePath);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool isLoading,
            bool isAnalyzing,
            bool isCheckingCompatibility,
            BackupPreviewInfo? previewInfo,
            String? error,
            String? selectedFilePath)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PreviewState():
        return $default(
            _that.isLoading,
            _that.isAnalyzing,
            _that.isCheckingCompatibility,
            _that.previewInfo,
            _that.error,
            _that.selectedFilePath);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool isLoading,
            bool isAnalyzing,
            bool isCheckingCompatibility,
            BackupPreviewInfo? previewInfo,
            String? error,
            String? selectedFilePath)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PreviewState() when $default != null:
        return $default(
            _that.isLoading,
            _that.isAnalyzing,
            _that.isCheckingCompatibility,
            _that.previewInfo,
            _that.error,
            _that.selectedFilePath);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PreviewState implements PreviewState {
  const _PreviewState(
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

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PreviewStateCopyWith<_PreviewState> get copyWith =>
      __$PreviewStateCopyWithImpl<_PreviewState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PreviewState &&
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

  @override
  String toString() {
    return 'PreviewState(isLoading: $isLoading, isAnalyzing: $isAnalyzing, isCheckingCompatibility: $isCheckingCompatibility, previewInfo: $previewInfo, error: $error, selectedFilePath: $selectedFilePath)';
  }
}

/// @nodoc
abstract mixin class _$PreviewStateCopyWith<$Res>
    implements $PreviewStateCopyWith<$Res> {
  factory _$PreviewStateCopyWith(
          _PreviewState value, $Res Function(_PreviewState) _then) =
      __$PreviewStateCopyWithImpl;
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
class __$PreviewStateCopyWithImpl<$Res>
    implements _$PreviewStateCopyWith<$Res> {
  __$PreviewStateCopyWithImpl(this._self, this._then);

  final _PreviewState _self;
  final $Res Function(_PreviewState) _then;

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isLoading = null,
    Object? isAnalyzing = null,
    Object? isCheckingCompatibility = null,
    Object? previewInfo = freezed,
    Object? error = freezed,
    Object? selectedFilePath = freezed,
  }) {
    return _then(_PreviewState(
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzing: null == isAnalyzing
          ? _self.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckingCompatibility: null == isCheckingCompatibility
          ? _self.isCheckingCompatibility
          : isCheckingCompatibility // ignore: cast_nullable_to_non_nullable
              as bool,
      previewInfo: freezed == previewInfo
          ? _self.previewInfo
          : previewInfo // ignore: cast_nullable_to_non_nullable
              as BackupPreviewInfo?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedFilePath: freezed == selectedFilePath
          ? _self.selectedFilePath
          : selectedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of PreviewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupPreviewInfoCopyWith<$Res>? get previewInfo {
    if (_self.previewInfo == null) {
      return null;
    }

    return $BackupPreviewInfoCopyWith<$Res>(_self.previewInfo!, (value) {
      return _then(_self.copyWith(previewInfo: value));
    });
  }
}

// dart format on
