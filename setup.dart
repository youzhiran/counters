import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// 构建目标，后续若扩展更多平台可以继续追加枚举值
enum BuildTarget {
  android,
  windows,
}

/// 构建配置，记录用户指定的目标与清理策略
class BuildConfig {
  const BuildConfig({
    required this.targets,
    required this.clean,
  });

  final List<BuildTarget> targets;
  final bool clean;
}

void main(List<String> args) {
  final config = _parseArguments(args);
  final pubspecVersion = _generateVersionFile();

  final distDir = Directory('dist');
  if (!distDir.existsSync()) {
    distDir.createSync(recursive: true);
  }

  try {
    for (final target in config.targets) {
      switch (target) {
        case BuildTarget.windows:
          _buildWindows(pubspecVersion, clean: config.clean);
          break;
        case BuildTarget.android:
          _buildAndroid(pubspecVersion, clean: config.clean);
          break;
      }
    }
  } catch (e) {
    _logError('发生错误: $e');
    exitCode = 1;
  }
}

BuildConfig _parseArguments(List<String> args) {
  if (!(Platform.isWindows || Platform.isLinux)) {
    _fail('错误：当前平台暂不支持该脚本');
  }

  final positional = <String>[];
  var clean = true;

  for (final arg in args) {
    if (arg == '--skip-clean') {
      clean = false;
      continue;
    }
    if (arg.startsWith('--')) {
      _fail('未知参数: $arg');
    }
    positional.add(arg.toLowerCase());
  }

  final targets = <BuildTarget>[];

  void addTarget(BuildTarget target) {
    if (!targets.contains(target)) {
      targets.add(target);
    }
  }

  if (positional.isEmpty) {
    if (Platform.isWindows) {
      addTarget(BuildTarget.windows);
    } else {
      addTarget(BuildTarget.android);
    }
  } else {
    for (final value in positional) {
      switch (value) {
        case 'win':
        case 'windows':
          if (!Platform.isWindows) {
            _fail('错误：非 Windows 平台无法构建 Windows 包');
          }
          addTarget(BuildTarget.windows);
          break;
        case 'android':
        case 'arm64':
          addTarget(BuildTarget.android);
          break;
        case 'all':
          if (!Platform.isWindows) {
            _fail('错误："all" 参数仅在 Windows 平台可用');
          }
          addTarget(BuildTarget.windows);
          addTarget(BuildTarget.android);
          break;
        default:
          _fail('错误：不支持的平台参数 "$value"');
      }
    }
  }

  if (targets.isEmpty) {
    _fail('错误：未识别到有效的构建目标');
  }

  _logInfo('构建目标: ${targets.map(_targetDisplayName).join(', ')}');
  _logInfo('是否执行 flutter clean: ${clean ? '是' : '否'}');

  return BuildConfig(targets: targets, clean: clean);
}

String _generateVersionFile() {
  final versionFile = File(p.join('lib', 'version.dart'));
  final gitCommit = _runCommand(['git', 'rev-parse', '--short', 'HEAD']);

  // 构建时间统一使用东八区并去掉毫秒，方便对照发布记录
  final buildTime = DateTime.now()
      .toUtc()
      .add(const Duration(hours: 8))
      .toIso8601String()
      .split('.')
      .first
      .replaceFirst('T', ' ');

  var pubspecVersion = '读取版本出错';

  try {
    final yamlContent = File('pubspec.yaml').readAsStringSync();
    final yamlMap = loadYaml(yamlContent) as YamlMap;
    final rawVersion = yamlMap['version']?.toString();
    if (rawVersion != null) {
      pubspecVersion = rawVersion.split('+').first;
      _logInfo('基础版本号: $pubspecVersion');
    } else {
      _logWarn('警告：pubspec.yaml 未声明 version 字段');
    }
  } catch (e) {
    _logError('读取 pubspec.yaml 失败: $e');
  }

  final content = '''
// Generated file - DO NOT EDIT. The information in this file may be out of date.
const String gitCommit = '$gitCommit';
const String buildTime = '$buildTime';
const String appVersion = '$pubspecVersion';
''';

  versionFile.writeAsStringSync(content);
  _logInfo('已生成版本信息: v$pubspecVersion @ $gitCommit ($buildTime)');

  return pubspecVersion;
}

void _buildAndroid(String version, {required bool clean}) {
  if (clean) {
    _logInfo('\n开始清理 Android 构建产物...');
    _runFlutterCommand(['clean']);
  }

  _logInfo('\n构建 Android 多架构安装包...');
  _runFlutterCommand(['build', 'apk', '--split-per-abi']);

  final releaseDir = Directory('build/app/outputs/apk/release');
  if (!releaseDir.existsSync()) {
    throw Exception('未找到 Android 构建输出目录: ${releaseDir.path}');
  }

  final apkFiles = releaseDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.apk'))
      .toList();

  if (apkFiles.isEmpty) {
    throw Exception('未在 ${releaseDir.path} 中发现 APK 文件');
  }

  final pattern = RegExp(r'app-([\w-]+)-release\.apk');

  for (final apkFile in apkFiles) {
    final filename = p.basename(apkFile.path);
    final match = pattern.firstMatch(filename);
    if (match == null) {
      _logWarn('跳过未识别文件: $filename');
      continue;
    }
    final abi = match.group(1);
    if (abi == 'universal') {
      _logWarn('跳过 universal 架构安装包: $filename');
      continue;
    }
    final dest = File(p.join('dist', 'counters-$version-android-$abi.apk'));
    _copyAndRename(apkFile, dest);
  }
}

void _buildWindows(String version, {required bool clean}) {
  if (!Platform.isWindows) {
    _logWarn('\n请在 Windows 环境下构建 Windows 包');
    return;
  }

  if (clean) {
    _logInfo('\n开始清理 Windows 构建产物...');
    _runFlutterCommand(['clean']);
  }

  _logInfo('\n构建 Windows x64 版本...');
  _runFlutterCommand(['build', 'windows', '--release']);

  final releaseDir = Directory('build/windows/x64/runner/Release');
  if (!releaseDir.existsSync()) {
    throw Exception('未找到 Windows 构建输出目录: ${releaseDir.path}');
  }

  final zipFile = File(p.join('dist', 'counters-$version-windows-x64.zip'));

  _logInfo('打包 Windows 构建结果...');
  if (zipFile.existsSync()) {
    zipFile.deleteSync();
  }

  _runCommand([
    'powershell',
    '-NoProfile',
    '-Command',
    'Compress-Archive -Path "${releaseDir.path}\\*" -DestinationPath "${zipFile.path}" -Force',
  ]);
  _logInfo('Windows 构建压缩完成: ${zipFile.path}');
}

void _copyAndRename(File source, File destination) {
  if (!source.existsSync()) {
    throw Exception('未找到源文件: ${source.path}');
  }

  if (destination.existsSync()) {
    destination.deleteSync();
  }

  source.copySync(destination.path);
  _logInfo('已生成: ${destination.path}');
}

void _runFlutterCommand(List<String> arguments) {
  final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  _runCommand([flutterCmd, ...arguments]);
}

String _runCommand(List<String> command, {String? workingDirectory}) {
  if (command.isEmpty) {
    throw ArgumentError('命令参数不能为空');
  }

  final executable = command.first;
  final args = command.length > 1 ? command.sublist(1) : const <String>[];

  _logInfo('==> 执行命令: ${[executable, ...args].join(' ')}');

  final result = Process.runSync(
    executable,
    args,
    workingDirectory: workingDirectory,
  );

  if (result.exitCode != 0) {
    throw Exception(
      '命令执行失败: ${[executable, ...args].join(' ')}\n'
      '退出码: ${result.exitCode}\n'
      '错误输出: ${result.stderr}',
    );
  }

  return result.stdout.toString().trim();
}

Never _fail(String message) {
  _logError(message);
  exit(1);
}

String _targetDisplayName(BuildTarget target) {
  switch (target) {
    case BuildTarget.android:
      return 'android';
    case BuildTarget.windows:
      return 'windows';
  }
}

void _logInfo(String message) {
  stdout.writeln(message);
}

void _logWarn(String message) {
  stdout.writeln(message);
}

void _logError(String message) {
  stderr.writeln(message);
}
