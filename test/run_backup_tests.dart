#!/usr/bin/env dart

import 'dart:io';

import 'package:test/test.dart';

/// 备份功能测试运行脚本
///
/// 这是一个测试套件，用于运行所有备份相关的测试
///
/// 使用方法:
/// flutter test test/run_backup_tests.dart
///
/// 或者直接运行脚本:
/// dart test/run_backup_tests.dart [选项]
///
/// 选项:
/// --all          运行所有测试
/// --unit         仅运行单元测试
/// --integration  仅运行集成测试
/// --widget       仅运行Widget测试
/// --coverage     生成覆盖率报告
/// --verbose      详细输出
/// --help         显示帮助信息

void main() async {
  // 当作为 flutter test 运行时，使用测试框架
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    group('备份功能测试套件', () {
      test('验证测试文件存在', () async {
        final testFiles = [
          'test/features/backup/backup_models_test.dart',
          'test/features/backup/services/hash_service_test.dart',
          'test/features/backup/backup_service_test.dart',
          'test/features/backup/backup_provider_test.dart',
          'test/features/backup/backup_preview_provider_test.dart',
          'test/features/backup/backup_integration_test.dart',
          'test/features/backup/widget/backup_page_test.dart',
        ];

        for (final testFile in testFiles) {
          final file = File(testFile);
          expect(await file.exists(), isTrue, reason: '测试文件不存在: $testFile');
        }
      });

      test('验证测试目录结构', () async {
        final testDir = Directory('test/features/backup');
        expect(await testDir.exists(), isTrue, reason: '备份测试目录不存在');

        final servicesDir = Directory('test/features/backup/services');
        expect(await servicesDir.exists(), isTrue, reason: '服务测试目录不存在');

        final widgetDir = Directory('test/features/backup/widget');
        expect(await widgetDir.exists(), isTrue, reason: 'Widget测试目录不存在');
      });
    });
    return;
  }

  // 当作为独立脚本运行时，解析命令行参数
  final args = Platform.environment['DART_VM_OPTIONS']?.split(' ') ?? [];
  await _runAsScript(args);
}

Future<void> _runAsScript(List<String> args) async {
  final options = parseArguments(args);

  if (options['help'] == true) {
    printHelp();
    return;
  }

  print('🧪 开始运行备份功能测试...\n');

  try {
    if (options['all'] == true || args.isEmpty) {
      await runAllTests(options);
    } else {
      if (options['unit'] == true) {
        await runUnitTests(options);
      }
      if (options['integration'] == true) {
        await runIntegrationTests(options);
      }
      if (options['widget'] == true) {
        await runWidgetTests(options);
      }
    }

    if (options['coverage'] == true) {
      await generateCoverageReport();
    }

    print('\n✅ 所有测试完成！');
  } catch (e) {
    print('\n❌ 测试运行失败: $e');
    exit(1);
  }
}

Map<String, bool> parseArguments(List<String> args) {
  return {
    'all': args.contains('--all'),
    'unit': args.contains('--unit'),
    'integration': args.contains('--integration'),
    'widget': args.contains('--widget'),
    'coverage': args.contains('--coverage'),
    'verbose': args.contains('--verbose'),
    'help': args.contains('--help') || args.contains('-h'),
  };
}

void printHelp() {
  print('''
备份功能测试运行脚本

使用方法:
  dart test/run_backup_tests.dart [选项]

选项:
  --all          运行所有测试 (默认)
  --unit         仅运行单元测试
  --integration  仅运行集成测试
  --widget       仅运行Widget测试
  --coverage     生成覆盖率报告
  --verbose      详细输出
  --help, -h     显示此帮助信息

示例:
  dart test/run_backup_tests.dart --all --coverage
  dart test/run_backup_tests.dart --unit --verbose
  dart test/run_backup_tests.dart --integration
''');
}

Future<void> runAllTests(Map<String, bool> options) async {
  print('📋 运行所有备份功能测试...');
  
  await runTestCommand([
    'test/features/backup/',
  ], options);
}

Future<void> runUnitTests(Map<String, bool> options) async {
  print('🔬 运行单元测试...');
  
  final unitTestFiles = [
    'test/features/backup/backup_models_test.dart',
    'test/features/backup/services/hash_service_test.dart',
    'test/features/backup/backup_service_test.dart',
    'test/features/backup/backup_provider_test.dart',
    'test/features/backup/backup_preview_provider_test.dart',
  ];

  for (final testFile in unitTestFiles) {
    print('  📄 运行: $testFile');
    await runTestCommand([testFile], options);
  }
}

Future<void> runIntegrationTests(Map<String, bool> options) async {
  print('🔗 运行集成测试...');
  
  await runTestCommand([
    'test/features/backup/backup_integration_test.dart',
  ], options);
}

Future<void> runWidgetTests(Map<String, bool> options) async {
  print('🎨 运行Widget测试...');
  
  await runTestCommand([
    'test/features/backup/widget/backup_page_test.dart',
  ], options);
}

Future<void> runTestCommand(List<String> testPaths, Map<String, bool> options) async {
  final args = ['test'];
  
  if (options['coverage'] == true) {
    args.add('--coverage');
  }
  
  if (options['verbose'] == true) {
    args.add('--verbose');
  }
  
  args.addAll(testPaths);

  final result = await Process.run('flutter', args);
  
  if (result.exitCode != 0) {
    print('❌ 测试失败:');
    print(result.stdout);
    print(result.stderr);
    throw Exception('测试执行失败，退出码: ${result.exitCode}');
  } else {
    if (options['verbose'] == true) {
      print(result.stdout);
    }
    print('✅ 测试通过');
  }
}

Future<void> generateCoverageReport() async {
  print('\n📊 生成覆盖率报告...');
  
  // 检查是否安装了lcov
  final lcovCheck = await Process.run('which', ['genhtml']);
  if (lcovCheck.exitCode != 0) {
    print('⚠️  警告: 未找到genhtml命令，跳过HTML覆盖率报告生成');
    print('   安装方法: brew install lcov (macOS) 或 apt-get install lcov (Ubuntu)');
    return;
  }

  // 生成HTML覆盖率报告
  final genhtmlResult = await Process.run('genhtml', [
    'coverage/lcov.info',
    '-o',
    'coverage/html',
    '--title',
    '备份功能测试覆盖率报告',
  ]);

  if (genhtmlResult.exitCode == 0) {
    print('✅ 覆盖率报告已生成: coverage/html/index.html');
    
    // 尝试打开覆盖率报告
    if (Platform.isMacOS) {
      await Process.run('open', ['coverage/html/index.html']);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', ['coverage/html/index.html']);
    } else if (Platform.isWindows) {
      await Process.run('start', ['coverage/html/index.html'], runInShell: true);
    }
  } else {
    print('❌ 覆盖率报告生成失败:');
    print(genhtmlResult.stderr);
  }

  // 显示覆盖率摘要
  await showCoverageSummary();
}

Future<void> showCoverageSummary() async {
  try {
    final lcovFile = File('coverage/lcov.info');
    if (!await lcovFile.exists()) {
      print('⚠️  未找到覆盖率数据文件');
      return;
    }

    final lcovContent = await lcovFile.readAsString();
    final lines = lcovContent.split('\n');
    
    int totalLines = 0;
    int coveredLines = 0;
    
    for (final line in lines) {
      if (line.startsWith('LF:')) {
        totalLines += int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        coveredLines += int.parse(line.substring(3));
      }
    }
    
    if (totalLines > 0) {
      final coverage = (coveredLines / totalLines * 100).toStringAsFixed(1);
      print('\n📈 覆盖率摘要:');
      print('   总行数: $totalLines');
      print('   覆盖行数: $coveredLines');
      print('   覆盖率: $coverage%');
      
      if (double.parse(coverage) >= 90) {
        print('   🎉 优秀的覆盖率！');
      } else if (double.parse(coverage) >= 80) {
        print('   👍 良好的覆盖率');
      } else {
        print('   ⚠️  覆盖率需要提升');
      }
    }
  } catch (e) {
    print('⚠️  无法解析覆盖率数据: $e');
  }
}
