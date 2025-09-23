// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupDataImpl _$$BackupDataImplFromJson(Map<String, dynamic> json) =>
    _$BackupDataImpl(
      metadata:
          BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      sharedPreferences: json['sharedPreferences'] as Map<String, dynamic>,
      databases: (json['databases'] as List<dynamic>)
          .map((e) => DatabaseFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BackupDataImplToJson(_$BackupDataImpl instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'sharedPreferences': instance.sharedPreferences,
      'databases': instance.databases,
    };

_$BackupMetadataImpl _$$BackupMetadataImplFromJson(Map<String, dynamic> json) =>
    _$BackupMetadataImpl(
      appVersion: json['appVersion'] as String,
      buildNumber: json['buildNumber'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      platform: json['platform'] as String,
      backupCode: (json['backupCode'] as num).toInt(),
    );

Map<String, dynamic> _$$BackupMetadataImplToJson(
        _$BackupMetadataImpl instance) =>
    <String, dynamic>{
      'appVersion': instance.appVersion,
      'buildNumber': instance.buildNumber,
      'timestamp': instance.timestamp,
      'platform': instance.platform,
      'backupCode': instance.backupCode,
    };

_$DatabaseFileImpl _$$DatabaseFileImplFromJson(Map<String, dynamic> json) =>
    _$DatabaseFileImpl(
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      size: (json['size'] as num).toInt(),
      checksum: json['checksum'] as String,
    );

Map<String, dynamic> _$$DatabaseFileImplToJson(_$DatabaseFileImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'relativePath': instance.relativePath,
      'size': instance.size,
      'checksum': instance.checksum,
    };

_$HashInfoImpl _$$HashInfoImplFromJson(Map<String, dynamic> json) =>
    _$HashInfoImpl(
      algorithm: json['algorithm'] as String,
      hash: json['hash'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$$HashInfoImplToJson(_$HashInfoImpl instance) =>
    <String, dynamic>{
      'algorithm': instance.algorithm,
      'hash': instance.hash,
      'timestamp': instance.timestamp,
    };
