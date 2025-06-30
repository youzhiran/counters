// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackupData _$BackupDataFromJson(Map<String, dynamic> json) => _BackupData(
      metadata:
          BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      sharedPreferences: json['sharedPreferences'] as Map<String, dynamic>,
      databases: (json['databases'] as List<dynamic>)
          .map((e) => DatabaseFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BackupDataToJson(_BackupData instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'sharedPreferences': instance.sharedPreferences,
      'databases': instance.databases,
    };

_BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) =>
    _BackupMetadata(
      appVersion: json['appVersion'] as String,
      buildNumber: json['buildNumber'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      platform: json['platform'] as String,
      backupCode: (json['backupCode'] as num).toInt(),
    );

Map<String, dynamic> _$BackupMetadataToJson(_BackupMetadata instance) =>
    <String, dynamic>{
      'appVersion': instance.appVersion,
      'buildNumber': instance.buildNumber,
      'timestamp': instance.timestamp,
      'platform': instance.platform,
      'backupCode': instance.backupCode,
    };

_DatabaseFile _$DatabaseFileFromJson(Map<String, dynamic> json) =>
    _DatabaseFile(
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      size: (json['size'] as num).toInt(),
      checksum: json['checksum'] as String,
    );

Map<String, dynamic> _$DatabaseFileToJson(_DatabaseFile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'relativePath': instance.relativePath,
      'size': instance.size,
      'checksum': instance.checksum,
    };

_HashInfo _$HashInfoFromJson(Map<String, dynamic> json) => _HashInfo(
      algorithm: json['algorithm'] as String,
      hash: json['hash'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$HashInfoToJson(_HashInfo instance) => <String, dynamic>{
      'algorithm': instance.algorithm,
      'hash': instance.hash,
      'timestamp': instance.timestamp,
    };
