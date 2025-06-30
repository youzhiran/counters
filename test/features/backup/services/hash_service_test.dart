import 'dart:typed_data';

import 'package:counters/features/backup/backup_models.dart';
import 'package:counters/features/backup/services/hash_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('HashService', () {
    late Uint8List testData;
    late String expectedHash;

    setUp(() {
      testData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      expectedHash = sha256.convert(testData).toString();
    });

    group('generateHash', () {
      test('应该生成正确的哈希信息', () {
        // Arrange & Act
        final hashInfo = HashService.generateHash(testData);

        // Assert
        expect(hashInfo.algorithm, equals('SHA-256'));
        expect(hashInfo.hash, equals(expectedHash));
        expect(hashInfo.timestamp, isNotEmpty);
        expect(int.tryParse(hashInfo.timestamp), isNotNull);
      });

      test('应该为不同数据生成不同哈希', () {
        // Arrange
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6]);

        // Act
        final hash1 = HashService.generateHash(data1);
        final hash2 = HashService.generateHash(data2);

        // Assert
        expect(hash1.hash, isNot(equals(hash2.hash)));
        expect(hash1.algorithm, equals(hash2.algorithm));
      });

      test('应该为相同数据生成相同哈希', () {
        // Arrange
        final data1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final data2 = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Act
        final hash1 = HashService.generateHash(data1);
        final hash2 = HashService.generateHash(data2);

        // Assert
        expect(hash1.hash, equals(hash2.hash));
        expect(hash1.algorithm, equals(hash2.algorithm));
      });

      test('应该处理空数据', () {
        // Arrange
        final emptyData = Uint8List(0);

        // Act
        final hashInfo = HashService.generateHash(emptyData);

        // Assert
        expect(hashInfo.algorithm, equals('SHA-256'));
        expect(hashInfo.hash, isNotEmpty);
        expect(hashInfo.timestamp, isNotEmpty);
      });

      test('应该处理大数据', () {
        // Arrange
        final largeData = Uint8List(1024 * 1024); // 1MB
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        // Act
        final hashInfo = HashService.generateHash(largeData);

        // Assert
        expect(hashInfo.algorithm, equals('SHA-256'));
        expect(hashInfo.hash, isNotEmpty);
        expect(hashInfo.hash.length, equals(64)); // SHA-256 hex length
      });
    });

    group('verifyHash', () {
      test('应该验证正确的哈希', () {
        // Arrange
        final hashInfo = TestHelpers.createTestHashInfo(hash: expectedHash);

        // Act
        final isValid = HashService.verifyHash(testData, hashInfo);

        // Assert
        expect(isValid, isTrue);
      });

      test('应该拒绝错误的哈希', () {
        // Arrange
        final wrongHash = TestHelpers.createTestHashInfo(hash: 'wrong_hash');

        // Act
        final isValid = HashService.verifyHash(testData, wrongHash);

        // Assert
        expect(isValid, isFalse);
      });

      test('应该处理空哈希', () {
        // Arrange
        final emptyHash = TestHelpers.createTestHashInfo(hash: '');

        // Act
        final isValid = HashService.verifyHash(testData, emptyHash);

        // Assert
        expect(isValid, isFalse);
      });

      test('应该处理不同算法的哈希', () {
        // Arrange
        final hashInfo = HashInfo(
          algorithm: 'MD5',
          hash: expectedHash,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        // Act
        final isValid = HashService.verifyHash(testData, hashInfo);

        // Assert
        expect(isValid, isTrue); // 算法字段不影响验证，只验证哈希值
      });

      test('应该验证空数据的哈希', () {
        // Arrange
        final emptyData = Uint8List(0);
        final emptyDataHash = sha256.convert(emptyData).toString();
        final hashInfo = TestHelpers.createTestHashInfo(hash: emptyDataHash);

        // Act
        final isValid = HashService.verifyHash(emptyData, hashInfo);

        // Assert
        expect(isValid, isTrue);
      });
    });

    group('calculateFileHash', () {
      test('应该计算正确的文件哈希', () {
        // Act
        final hash = HashService.calculateFileHash(testData);

        // Assert
        expect(hash, equals(expectedHash));
        expect(hash.length, equals(64)); // SHA-256 hex length
      });

      test('应该为不同数据计算不同哈希', () {
        // Arrange
        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6]);

        // Act
        final hash1 = HashService.calculateFileHash(data1);
        final hash2 = HashService.calculateFileHash(data2);

        // Assert
        expect(hash1, isNot(equals(hash2)));
      });

      test('应该处理空数据', () {
        // Arrange
        final emptyData = Uint8List(0);

        // Act
        final hash = HashService.calculateFileHash(emptyData);

        // Assert
        expect(hash, isNotEmpty);
        expect(hash.length, equals(64));
      });
    });

    group('verifyFileIntegrity', () {
      test('应该验证正确的文件完整性', () {
        // Act
        final isValid = HashService.verifyFileIntegrity(testData, expectedHash);

        // Assert
        expect(isValid, isTrue);
      });

      test('应该拒绝错误的哈希', () {
        // Arrange
        const wrongHash = 'wrong_hash_value';

        // Act
        final isValid = HashService.verifyFileIntegrity(testData, wrongHash);

        // Assert
        expect(isValid, isFalse);
      });

      test('应该处理空哈希', () {
        // Act
        final isValid = HashService.verifyFileIntegrity(testData, '');

        // Assert
        expect(isValid, isFalse);
      });

      test('应该验证修改后的数据', () {
        // Arrange
        final modifiedData =
            Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 11]); // 最后一个字节不同

        // Act
        final isValid =
            HashService.verifyFileIntegrity(modifiedData, expectedHash);

        // Assert
        expect(isValid, isFalse);
      });

      test('应该验证空数据的完整性', () {
        // Arrange
        final emptyData = Uint8List(0);
        final emptyHash = sha256.convert(emptyData).toString();

        // Act
        final isValid = HashService.verifyFileIntegrity(emptyData, emptyHash);

        // Assert
        expect(isValid, isTrue);
      });
    });

    group('错误处理', () {
      test('generateHash 应该处理异常情况', () {
        // 这里我们无法直接模拟 sha256.convert 的异常，
        // 但可以测试正常的边界情况
        expect(() => HashService.generateHash(Uint8List(0)), returnsNormally);
      });

      test('verifyHash 应该处理异常情况', () {
        // Arrange
        final hashInfo = TestHelpers.createTestHashInfo();

        // Act & Assert
        expect(() => HashService.verifyHash(Uint8List(0), hashInfo),
            returnsNormally);
      });

      test('calculateFileHash 应该处理异常情况', () {
        // Act & Assert
        expect(
            () => HashService.calculateFileHash(Uint8List(0)), returnsNormally);
      });

      test('verifyFileIntegrity 应该处理异常情况', () {
        // Act & Assert
        expect(() => HashService.verifyFileIntegrity(Uint8List(0), ''),
            returnsNormally);
      });
    });
  });
}
