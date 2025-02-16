import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main() {
  // 生成版本信息文件
  final pubspecVersion = _generateVersionFile();

  // 创建dist目录
  final distDir = Directory('dist');
  if (!distDir.existsSync()) {
    distDir.createSync(recursive: true);
  }

  try {
    if (Platform.isWindows) {
      // 构建Windows版本并打包
      _buildWindows(pubspecVersion);
    } else {
      // 构建Android各架构版本
      _buildAndroid(pubspecVersion, 'android-arm', 'armeabi-v7a');
      _buildAndroid(pubspecVersion, 'android-arm64', 'arm64-v8a');
      _buildAndroid(pubspecVersion, 'android-x64', 'x86_64');
    }
  } catch (e) {
    print('Error occurred: $e');
    exitCode = 1;
  }
}

String _generateVersionFile() {
  final versionFile = File(p.join('lib', 'version.dart'));
  final gitCommit = _runCommand('git rev-parse --short HEAD');
  final buildTime = DateTime.now()
      .toUtc() // 获取当前 UTC 时间
      .add(const Duration(hours: 8)) // 手动加上 8 小时
      .toString()
      .split('.')[0]; // 移除毫秒部分

  var pubspecVersion = "读取版本出错";

  // 读取 pubspec.yaml 中的版本号
  try {
    // 读取 YAML 文件内容
    final file = File('pubspec.yaml');
    final yamlContent = file.readAsStringSync();

    // 解析 YAML
    final yamlMap = loadYaml(yamlContent) as YamlMap;

    // 获取 version 字段
    final version = yamlMap['version']?.toString();

    if (version != null) {
      // 分割版本号，提取 "+" 前的内容
      final versionParts = version.split('+');
      pubspecVersion = versionParts[0];
      print('Base version: $pubspecVersion');
    } else {
      print('Error: Version field not found');
    }
  } catch (e) {
    print('Error reading YAML file: $e');
  }

  final content = '''
// Generated file - DO NOT EDIT
const String gitCommit = '$gitCommit';
const String buildTime = '$buildTime';
const String appVersion = '$pubspecVersion';
''';

  versionFile.writeAsStringSync(content);
  print('Generated version.dart with: '
      'v$pubspecVersion @ $gitCommit ($buildTime)');

  return pubspecVersion;
}

void _buildAndroid(String version, String platform, String arch) {
  print('\nBuilding Android $arch...');
  _runFlutterCommand('build apk --target-platform $platform');

  final source = File('build/app/outputs/apk/release/app-release.apk');
  final dest = File(p.join('dist', 'counters-$version-android-$arch.apk'));

  _copyAndRename(source, dest);
}

void _buildWindows(String pubspecVersion) {
  print('\nCleaning Windows build...');
  _runFlutterCommand('clean');

  print('\nBuilding Windows...');
  _runFlutterCommand('build windows --release');

  final pwd = Directory('.');
  final releaseDir = Directory('build/windows/x64/runner/Release');
  final zipFile = File(p.join('./dist', 'counters-$pubspecVersion-windows-x64.zip'));

  print('Compressing Windows build...');
  if (zipFile.existsSync()) zipFile.deleteSync();

  if (Platform.isWindows) {
    _runCommand(
      'powershell Compress-Archive -Path "${releaseDir.path}\\*" '
      '-DestinationPath "${zipFile.path}" -Force',
      workingDirectory: pwd.path,
    );
  } else {
    print('\n请使用Windows打包Windows版程序！');
  }

  print('Windows build compressed to ${zipFile.path}');
}

void _copyAndRename(File source, File destination) {
  if (!source.existsSync()) {
    throw Exception('Source file not found: ${source.path}');
  }

  if (destination.existsSync()) {
    destination.deleteSync();
  }

  source.copySync(destination.path);
  print('Created: ${destination.path}');
}

void _runFlutterCommand(String arguments) {
  final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  _runCommand('$flutterCmd $arguments');
}

String _runCommand(String command, {String? workingDirectory}) {
  final parts = command.split(' ');
  final executable = parts.first;
  final args = parts.sublist(1);

  final result = Process.runSync(
    executable,
    args,
    workingDirectory: workingDirectory,
  );

  if (result.exitCode != 0) {
    throw Exception(
      'Command failed: $command\n'
      'Exit code: ${result.exitCode}\n'
      'Error: ${result.stderr}',
    );
  }

  return result.stdout.toString().trim();
}
