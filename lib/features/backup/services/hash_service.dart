import 'dart:typed_data';

import 'package:counters/common/utils/log.dart';
import 'package:counters/features/backup/backup_models.dart';
import 'package:crypto/crypto.dart';

/// 文件哈希服务
class HashService {
  /// 为ZIP文件内容生成哈希信息
  static HashInfo generateHash(Uint8List zipData) {
    try {
      Log.v('HashService: 开始生成文件哈希');

      // 计算文件哈希
      final fileHash = sha256.convert(zipData).toString();
      Log.v('HashService: 文件哈希计算完成');

      // 生成时间戳
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      Log.i('HashService: 文件哈希生成成功');

      return HashInfo(
        algorithm: 'SHA-256',
        hash: fileHash,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      Log.e('HashService: 生成文件哈希失败 - $e');
      Log.e('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 验证ZIP文件的哈希
  static bool verifyHash(Uint8List zipData, HashInfo hashInfo) {
    try {
      Log.v('HashService: 开始验证文件哈希');
      Log.v('HashService: ZIP数据长度: ${zipData.length} 字节');

      // 重新计算文件哈希
      final currentFileHash = sha256.convert(zipData).toString();
      Log.v('HashService: 当前文件哈希: $currentFileHash');
      Log.v('HashService: 存储的哈希: ${hashInfo.hash}');

      // 检查文件哈希是否匹配
      final isValid = currentFileHash == hashInfo.hash;

      if (isValid) {
        Log.i('HashService: 文件哈希验证成功');
      } else {
        Log.w('HashService: 文件哈希不匹配，文件可能已被修改');
      }

      return isValid;
    } catch (e, stackTrace) {
      Log.e('HashService: 验证文件哈希失败 - $e');
      Log.e('StackTrace: $stackTrace');
      return false;
    }
  }

  /// 计算文件的SHA-256哈希值
  static String calculateFileHash(Uint8List data) {
    try {
      Log.v('HashService: 计算文件哈希值');
      final hash = sha256.convert(data).toString();
      Log.v('HashService: 哈希值计算完成: $hash');
      return hash;
    } catch (e, stackTrace) {
      Log.e('HashService: 计算文件哈希失败 - $e');
      Log.e('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 验证文件完整性（仅检查哈希值）
  static bool verifyFileIntegrity(Uint8List data, String expectedHash) {
    try {
      Log.v('HashService: 验证文件完整性');
      final currentHash = calculateFileHash(data);
      final isValid = currentHash == expectedHash;

      if (isValid) {
        Log.i('HashService: 文件完整性验证成功');
      } else {
        Log.w('HashService: 文件完整性验证失败');
        Log.w('HashService: 期望哈希: $expectedHash');
        Log.w('HashService: 实际哈希: $currentHash');
      }

      return isValid;
    } catch (e, stackTrace) {
      Log.e('HashService: 验证文件完整性失败 - $e');
      Log.e('StackTrace: $stackTrace');
      return false;
    }
  }
}
