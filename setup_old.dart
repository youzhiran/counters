import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  // 解析命令行参数
  final architectures = _parseArguments(args);

  // 生成版本信息文件
  final pubspecVersion = _generateVersionFile();

  // 创建dist目录
  final distDir = Directory('dist');
  if (!distDir.existsSync()) {
    distDir.createSync(recursive: true);
  }

  print('打包架构名：$architectures');

  try {
    _buildWindows(pubspecVersion, architectures);
    _buildAndroid(pubspecVersion, architectures);
  } catch (e) {
    print('Error occurred: $e');
    exitCode = 1;
  }
}

// 解析命令行参数
Set<String> _parseArguments(List<String> args) {
  const supportedArches = {'arm', 'arm64', 'x64', 'amd64', 'all'};
  final architectures = <String>{};

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '-a' || args[i] == '--arch') {
      if (i + 1 >= args.length) {
        _printHelp('Missing value for ${args[i]}');
        exit(1);
      }

      // 分割逗号分隔的架构参数
      final archValues = args[++i].toLowerCase().split(',');

      for (final arch in archValues) {
        if (arch == 'all') {
          // 添加所有实际架构（排除 all 自身）
          architectures.addAll({'arm', 'arm64', 'x64', 'amd64'});
        } else if (!supportedArches.contains(arch)) {
          _printHelp('Unsupported architecture: $arch');
          exit(1);
        } else {
          architectures.add(arch);
        }
      }
    } else if (args[i] == '-h' || args[i] == '--help') {
      _printHelp();
      exit(0);
    }
  }

  // 默认构建逻辑
  if (architectures.isEmpty) {
    return Platform.isWindows ? {'amd64'} : {'arm', 'arm64', 'x64'};
  }

  // 过滤保留实际架构（兼容可能误输入的 all）
  return architectures.where((a) => a != 'all').toSet();
}

// 帮助信息
void _printHelp([String? error]) {
  final message = '''
Usage: dart build.dart [options]

Options:
  --arch <architecture>  Specify build architectures (comma-separated)
                             Available: arm, arm64, x64, amd64, all
  --help                 Show this help message

Platform defaults:
  Android: arm, arm64, x64
  Windows: amd64
''';

  if (error != null) {
    print('Error: $error\n');
  }
  print(message);
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
// Generated file - DO NOT EDIT. The information in this file may be out of date.
const String gitCommit = '$gitCommit';
const String buildTime = '$buildTime';
const String appVersion = '$pubspecVersion';
''';

  versionFile.writeAsStringSync(content);
  print('Generated version.dart with: '
      'v$pubspecVersion @ $gitCommit ($buildTime)');

  return pubspecVersion;
}

void _buildAndroid(String version, Set<String> architectures) {
  const platformMap = {
    'arm': {'platform': 'android-arm', 'arch': 'armeabi-v7a'},
    'arm64': {'platform': 'android-arm64', 'arch': 'arm64-v8a'},
    'x64': {'platform': 'android-x64', 'arch': 'x86_64'},
  };


  print('\nCleaning Android build...');
  _runFlutterCommand('clean');

  for (final arch in architectures) {
    final config = platformMap[arch];
    if (config == null) continue;

    print('\nBuilding Android ${config['arch']}...');
    _runFlutterCommand('build apk --target-platform ${config['platform']}');

    final source = File('build/app/outputs/apk/release/app-release.apk');
    final dest =
        File(p.join('dist', 'counters-$version-android-${config['arch']}.apk'));
    _copyAndRename(source, dest);
  }
}

void _buildWindows(String version, Set<String> architectures) {
  if (!Platform.isWindows) {
    print('\n请使用Windows打包Windows版程序！');
  } else {
    if (architectures.contains('amd64')) {
      print('\nCleaning Windows build...');
      _runFlutterCommand('clean');

      print('\nBuilding Windows amd64...');
      _runFlutterCommand('build windows --release');

      final releaseDir = Directory('build/windows/x64/runner/Release');
      final zipFile =
          File(p.join('./dist', 'counters-$version-windows-x64.zip'));

      print('Compressing Windows build...');
      if (zipFile.existsSync()) zipFile.deleteSync();

      _runCommand(
        'powershell Compress-Archive -Path "${releaseDir.path}\\*" '
        '-DestinationPath "${zipFile.path}" -Force',
        workingDirectory: Directory.current.path,
      );
      print('Windows build compressed to ${zipFile.path}');
    }
  }
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
