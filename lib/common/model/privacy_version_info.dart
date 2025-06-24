import 'dart:convert';

/// 隐私政策版本信息模型
class PrivacyVersionInfo {
  final String version;
  final String date;
  final String isoDate;
  final int timestamp;
  final String generatedAt;

  const PrivacyVersionInfo({
    required this.version,
    required this.date,
    required this.isoDate,
    required this.timestamp,
    required this.generatedAt,
  });

  /// 从JSON创建实例
  factory PrivacyVersionInfo.fromJson(Map<String, dynamic> json) {
    return PrivacyVersionInfo(
      version: json['version'] as String,
      date: json['date'] as String,
      isoDate: json['isoDate'] as String,
      timestamp: json['timestamp'] as int,
      generatedAt: json['generatedAt'] as String,
    );
  }

  /// 从JSON字符串创建实例
  factory PrivacyVersionInfo.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return PrivacyVersionInfo.fromJson(json);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'date': date,
      'isoDate': isoDate,
      'timestamp': timestamp,
      'generatedAt': generatedAt,
    };
  }

  /// 转换为JSON字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return 'PrivacyVersionInfo(version: $version, date: $date, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacyVersionInfo &&
        other.version == version &&
        other.date == date &&
        other.isoDate == isoDate &&
        other.timestamp == timestamp &&
        other.generatedAt == generatedAt;
  }

  @override
  int get hashCode {
    return version.hashCode ^
        date.hashCode ^
        isoDate.hashCode ^
        timestamp.hashCode ^
        generatedAt.hashCode;
  }
}
