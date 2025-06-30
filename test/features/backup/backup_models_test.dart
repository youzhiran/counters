import 'package:counters/features/backup/backup_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BackupModels', () {
    group('BackupMetadata', () {
      test('应该正确创建实例', () {
        // Arrange & Act
        final metadata = TestHelpers.createTestMetadata(
          appVersion: '1.0.0',
          buildNumber: '1',
          platform: 'android',
          backupCode: 1,
        );

        // Assert
        expect(metadata.appVersion, equals('1.0.0'));
        expect(metadata.buildNumber, equals('1'));
        expect(metadata.platform, equals('android'));
        expect(metadata.backupCode, equals(1));
        expect(metadata.timestamp, isA<int>());
      });

      test('应该正确序列化为JSON', () {
        // Arrange
        final metadata = TestHelpers.createTestMetadata(
          appVersion: '1.0.0',
          buildNumber: '1',
          timestamp: 1234567890,
          platform: 'android',
          backupCode: 1,
        );

        // Act
        final json = metadata.toJson();

        // Assert
        expect(json['appVersion'], equals('1.0.0'));
        expect(json['buildNumber'], equals('1'));
        expect(json['timestamp'], equals(1234567890));
        expect(json['platform'], equals('android'));
        expect(json['backupCode'], equals(1));
      });

      test('应该正确从JSON反序列化', () {
        // Arrange
        final json = {
          'appVersion': '1.0.0',
          'buildNumber': '1',
          'timestamp': 1234567890,
          'platform': 'android',
          'backupCode': 1,
        };

        // Act
        final metadata = BackupMetadata.fromJson(json);

        // Assert
        expect(metadata.appVersion, equals('1.0.0'));
        expect(metadata.buildNumber, equals('1'));
        expect(metadata.timestamp, equals(1234567890));
        expect(metadata.platform, equals('android'));
        expect(metadata.backupCode, equals(1));
      });

      test('应该支持copyWith', () {
        // Arrange
        final original = TestHelpers.createTestMetadata(appVersion: '1.0.0');

        // Act
        final updated = original.copyWith(appVersion: '2.0.0');

        // Assert
        expect(updated.appVersion, equals('2.0.0'));
        expect(updated.buildNumber, equals(original.buildNumber));
        expect(updated.timestamp, equals(original.timestamp));
      });
    });

    group('DatabaseFile', () {
      test('应该正确创建实例', () {
        // Arrange & Act
        final dbFile = TestHelpers.createTestDatabaseFile(
          name: 'test.db',
          relativePath: 'databases/test.db',
          size: 1024,
          checksum: 'abc123',
        );

        // Assert
        expect(dbFile.name, equals('test.db'));
        expect(dbFile.relativePath, equals('databases/test.db'));
        expect(dbFile.size, equals(1024));
        expect(dbFile.checksum, equals('abc123'));
      });

      test('应该正确序列化为JSON', () {
        // Arrange
        final dbFile = TestHelpers.createTestDatabaseFile(
          name: 'test.db',
          relativePath: 'databases/test.db',
          size: 1024,
          checksum: 'abc123',
        );

        // Act
        final json = dbFile.toJson();

        // Assert
        expect(json['name'], equals('test.db'));
        expect(json['relativePath'], equals('databases/test.db'));
        expect(json['size'], equals(1024));
        expect(json['checksum'], equals('abc123'));
      });

      test('应该正确从JSON反序列化', () {
        // Arrange
        final json = {
          'name': 'test.db',
          'relativePath': 'databases/test.db',
          'size': 1024,
          'checksum': 'abc123',
        };

        // Act
        final dbFile = DatabaseFile.fromJson(json);

        // Assert
        expect(dbFile.name, equals('test.db'));
        expect(dbFile.relativePath, equals('databases/test.db'));
        expect(dbFile.size, equals(1024));
        expect(dbFile.checksum, equals('abc123'));
      });
    });

    group('BackupData', () {
      test('应该正确创建实例', () {
        // Arrange
        final metadata = TestHelpers.createTestMetadata();
        final sharedPrefs = {'key1': 'value1', 'key2': 42};
        final databases = [TestHelpers.createTestDatabaseFile()];

        // Act
        final backupData = BackupData(
          metadata: metadata,
          sharedPreferences: sharedPrefs,
          databases: databases,
        );

        // Assert
        expect(backupData.metadata, equals(metadata));
        expect(backupData.sharedPreferences, equals(sharedPrefs));
        expect(backupData.databases, equals(databases));
      });

      test('应该正确序列化为JSON', () {
        // Arrange
        final backupData = TestHelpers.createTestBackupData();

        // Act
        final json = backupData.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('metadata'), isTrue);
        expect(json.containsKey('sharedPreferences'), isTrue);
        expect(json.containsKey('databases'), isTrue);
        expect(json['sharedPreferences'], isA<Map<String, dynamic>>());
        expect(json['databases'], isA<List>());
      });

      test('应该正确从JSON反序列化', () {
        // Arrange
        final metadata = TestHelpers.createTestMetadata();
        final sharedPrefs = {'key1': 'value1', 'key2': 42};
        final databases = [TestHelpers.createTestDatabaseFile()];

        final json = {
          'metadata': metadata.toJson(),
          'sharedPreferences': sharedPrefs,
          'databases': databases.map((db) => db.toJson()).toList(),
        };

        // Act
        final deserializedData = BackupData.fromJson(json);

        // Assert
        expect(
            deserializedData.metadata.appVersion, equals(metadata.appVersion));
        expect(deserializedData.sharedPreferences, equals(sharedPrefs));
        expect(deserializedData.databases.length, equals(databases.length));
      });
    });

    group('BackupState', () {
      test('应该正确创建默认实例', () {
        // Act
        const state = BackupState();

        // Assert
        expect(state.isLoading, isFalse);
        expect(state.isExporting, isFalse);
        expect(state.isImporting, isFalse);
        expect(state.progress, equals(0.0));
        expect(state.currentOperation, isNull);
        expect(state.error, isNull);
        expect(state.lastExportPath, isNull);
        expect(state.lastImportMetadata, isNull);
      });

      test('应该支持copyWith', () {
        // Arrange
        const original = BackupState();

        // Act
        final updated = original.copyWith(
          isLoading: true,
          progress: 0.5,
          currentOperation: '正在导出...',
        );

        // Assert
        expect(updated.isLoading, isTrue);
        expect(updated.progress, equals(0.5));
        expect(updated.currentOperation, equals('正在导出...'));
        expect(updated.isExporting, equals(original.isExporting));
      });
    });

    group('CompatibilityInfo', () {
      test('应该正确创建实例', () {
        // Act
        final info = TestHelpers.createTestCompatibilityInfo(
          level: CompatibilityLevel.warning,
          message: '版本较旧',
          warnings: ['警告1', '警告2'],
          errors: ['错误1'],
        );

        // Assert
        expect(info.level, equals(CompatibilityLevel.warning));
        expect(info.message, equals('版本较旧'));
        expect(info.warnings, equals(['警告1', '警告2']));
        expect(info.errors, equals(['错误1']));
      });

      test('应该支持不同的兼容性级别', () {
        // Act & Assert
        final compatible = TestHelpers.createTestCompatibilityInfo(
          level: CompatibilityLevel.compatible,
        );
        expect(compatible.level, equals(CompatibilityLevel.compatible));

        final warning = TestHelpers.createTestCompatibilityInfo(
          level: CompatibilityLevel.warning,
        );
        expect(warning.level, equals(CompatibilityLevel.warning));

        final incompatible = TestHelpers.createTestCompatibilityInfo(
          level: CompatibilityLevel.incompatible,
        );
        expect(incompatible.level, equals(CompatibilityLevel.incompatible));
      });
    });

    group('HashInfo', () {
      test('应该正确创建实例', () {
        // Act
        final hashInfo = TestHelpers.createTestHashInfo(
          algorithm: 'SHA-256',
          hash: 'abc123',
          timestamp: '1234567890',
        );

        // Assert
        expect(hashInfo.algorithm, equals('SHA-256'));
        expect(hashInfo.hash, equals('abc123'));
        expect(hashInfo.timestamp, equals('1234567890'));
      });

      test('应该正确序列化为JSON', () {
        // Arrange
        final hashInfo = TestHelpers.createTestHashInfo(
          algorithm: 'SHA-256',
          hash: 'abc123',
          timestamp: '1234567890',
        );

        // Act
        final json = hashInfo.toJson();

        // Assert
        expect(json['algorithm'], equals('SHA-256'));
        expect(json['hash'], equals('abc123'));
        expect(json['timestamp'], equals('1234567890'));
      });

      test('应该正确从JSON反序列化', () {
        // Arrange
        final json = {
          'algorithm': 'SHA-256',
          'hash': 'abc123',
          'timestamp': '1234567890',
        };

        // Act
        final hashInfo = HashInfo.fromJson(json);

        // Assert
        expect(hashInfo.algorithm, equals('SHA-256'));
        expect(hashInfo.hash, equals('abc123'));
        expect(hashInfo.timestamp, equals('1234567890'));
      });
    });

    group('ExportOptions', () {
      test('应该正确创建默认实例', () {
        // Act
        const options = ExportOptions();

        // Assert
        expect(options.includeSharedPreferences, isTrue);
        expect(options.includeDatabases, isTrue);
        expect(options.customPath, isNull);
        expect(options.customFileName, isNull);
      });

      test('应该支持自定义选项', () {
        // Act
        final options = TestHelpers.createTestExportOptions(
          includeSharedPreferences: false,
          includeDatabases: true,
          customPath: '/custom/path',
          customFileName: 'custom.zip',
        );

        // Assert
        expect(options.includeSharedPreferences, isFalse);
        expect(options.includeDatabases, isTrue);
        expect(options.customPath, equals('/custom/path'));
        expect(options.customFileName, equals('custom.zip'));
      });

      test('应该支持copyWith', () {
        // Arrange
        const original = ExportOptions();

        // Act
        final updated = original.copyWith(
          includeSharedPreferences: false,
          customPath: '/new/path',
        );

        // Assert
        expect(updated.includeSharedPreferences, isFalse);
        expect(updated.customPath, equals('/new/path'));
        expect(updated.includeDatabases, equals(original.includeDatabases));
      });
    });

    group('ImportOptions', () {
      test('应该正确创建默认实例', () {
        // Act
        const options = ImportOptions();

        // Assert
        expect(options.importSharedPreferences, isTrue);
        expect(options.importDatabases, isTrue);
        expect(options.createBackup, isTrue);
        expect(options.forceImport, isFalse);
      });

      test('应该支持自定义选项', () {
        // Act
        final options = TestHelpers.createTestImportOptions(
          importSharedPreferences: false,
          importDatabases: true,
          createBackup: false,
          forceImport: true,
        );

        // Assert
        expect(options.importSharedPreferences, isFalse);
        expect(options.importDatabases, isTrue);
        expect(options.createBackup, isFalse);
        expect(options.forceImport, isTrue);
      });

      test('应该支持copyWith', () {
        // Arrange
        const original = ImportOptions();

        // Act
        final updated = original.copyWith(
          forceImport: true,
          createBackup: false,
        );

        // Assert
        expect(updated.forceImport, isTrue);
        expect(updated.createBackup, isFalse);
        expect(updated.importSharedPreferences,
            equals(original.importSharedPreferences));
      });
    });
  });
}
