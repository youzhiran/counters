import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  // 解析命令行参数
  final buildAll = _parseArguments(args);

  final pubspecVersion = _generateVersionFile();

  final distDir = Directory('dist');
  if (!distDir.existsSync()) {
    distDir.createSync(recursive: true);
  }

  try {
    if (buildAll) {
      _buildWindows(pubspecVersion);
      _buildAndroid(pubspecVersion);
    } else {
      // 根据当前平台构建
      if (Platform.isWindows) {
        _buildWindows(pubspecVersion);
      } else {
        _buildAndroid(pubspecVersion);
      }
    }
  } catch (e) {
    print('发生错误: $e');
    exitCode = 1;
  }
}

bool _parseArguments(List<String> args) {
  if (args.isEmpty) {
    return false;
  }

  if (args.length == 1 && args[0] == 'all') {
    if (Platform.isWindows) {
      return true;
    } else {
      print('错误："all" 参数仅在 Windows 系统下有效');
      exit(1);
    }
  }

  print('无效参数，请使用 "all" 或留空');
  exit(1);
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

void _buildAndroid(String version) {
  print('\nCleaning Android build...');
  _runFlutterCommand('clean');

  print('\nBuilding Android with all ABIs...');
  _runFlutterCommand('build apk --split-per-abi'); // 使用split-per-abi

  final releaseDir = Directory('build/app/outputs/apk/release');
  final apkFiles = releaseDir.listSync().whereType<File>().where((file) {
    return file.path.endsWith('.apk') &&
        p.basename(file.path).startsWith('app-');
  }).toList();

  final pattern = RegExp(r'app-([\w-]+)-release\.apk');

  for (final apkFile in apkFiles) {
    final filename = p.basename(apkFile.path);
    final match = pattern.firstMatch(filename);
    if (match != null) {
      final abi = match.group(1);
      // 仅排除精确匹配 universal 的架构
      if (abi != 'universal') {
        final dest = File(p.join('dist', 'counters-$version-android-$abi.apk'));
        _copyAndRename(apkFile, dest);
      } else {
        print('跳过 universal 架构安装包: $filename');
      }
    }
  }
}

void _buildWindows(String version) {
  if (!Platform.isWindows) {
    print('\n请使用Windows打包Windows版程序！');
    return;
  }

  print('\nCleaning Windows build...');
  _runFlutterCommand('clean');

  print('\nBuilding Windows amd64...');
  _runFlutterCommand('build windows --release');

  final releaseDir = Directory('build/windows/x64/runner/Release');
  final zipFile = File(p.join('./dist', 'counters-$version-windows-x64.zip'));

  print('Compressing Windows build...');
  if (zipFile.existsSync()) zipFile.deleteSync();

  _runCommand(
    'powershell Compress-Archive -Path "${releaseDir.path}\\*" '
        '-DestinationPath "${zipFile.path}" -Force',
    workingDirectory: Directory.current.path,
  );
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

  print('==>Command:'+command);

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
