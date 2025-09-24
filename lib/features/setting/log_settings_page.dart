import 'package:counters/app/state.dart';
import 'package:counters/common/providers/log_export_provider.dart';
import 'package:counters/common/providers/log_provider.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:counters/common/widgets/setting_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日志设置页面
class LogSettingsPage extends ConsumerStatefulWidget {
  const LogSettingsPage({super.key});

  @override
  ConsumerState<LogSettingsPage> createState() => _LogSettingsPageState();
}

class _LogSettingsPageState extends ConsumerState<LogSettingsPage> {
  bool _enableProviderLogger = false;
  bool _enableVerboseLog = false;
  bool _enableClarityDebug = false;

  // SharedPreferences 键值常量
  static const String _keyEnableProviderLogger = 'enable_provider_logger';
  static const String _keyEnableVerboseLog = 'enable_verbose_log';
  static const String _keyEnableClarityDebug = 'enable_clarity_debug';

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        children: [
          _buildSectionHeader('日志查看'),
          SettingListTile(
            icon: Icons.article,
            title: '查看程序日志',
            subtitle: '查看应用运行日志和局域网状态',
            onTap: () {
              Navigator.of(context).pushNamed('/log_test');
            },
          ),
          _buildSectionHeader('日志导出设置'),
          SettingSwitchListTile(
            icon: Icons.file_download,
            title: '启用日志导出',
            subtitle: '开启后将持续监听日志并定时导出',
            value: ref.watch(logExportProvider).isEnabled,
            onChanged: (value) {
              ref.read(logExportProvider.notifier).toggleLogExport(value);
            },
          ),
          if (ref.watch(logExportProvider).isEnabled) ...[
            SettingListTile(
              icon: Icons.upload_file,
              title: '手动导出日志',
              subtitle: '立即导出当前日志缓冲区的内容',
              onTap: () {
                ref.read(logExportProvider.notifier).exportLogs();
              },
            ),
            SettingListTile(
              icon: Icons.delete_sweep,
              title: '清理日志缓冲区',
              subtitle: '清空当前缓存的日志内容',
              onTap: () {
                _showClearBufferDialog();
              },
            ),
            _buildLogExportStatus(),
          ],
          _buildSectionHeader('日志级别设置'),
          SettingSwitchListTile(
            icon: Icons.bug_report,
            title: '启用 Verbose 级别日志',
            subtitle: '显示最详细的日志信息，包括UI组件调试信息',
            value: _enableVerboseLog,
            onChanged: _saveVerboseLogSetting,
          ),
          _buildSectionHeader('调试日志设置'),
          SettingSwitchListTile(
            icon: Icons.article,
            title: '启用 Provider 调试日志',
            subtitle: '重启应用后生效，仅在控制台输出',
            value: _enableProviderLogger,
            onChanged: _saveProviderLoggerSetting,
          ),
          SettingSwitchListTile(
            icon: Icons.analytics,
            title: '启用 Clarity 调试日志',
            subtitle: '显示 Clarity 分析工具的详细日志信息[D]，重启应用后生效',
            value: _enableClarityDebug,
            onChanged: _saveClarityDebugSetting,
          ),
          _buildSectionHeader('日志测试'),
          SettingListTile(
            icon: Icons.science,
            title: '测试日志级别',
            subtitle: '测试各个级别的日志输出',
            onTap: _testLogLevels,
          ),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// 加载所有设置
  Future<void> _loadAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _enableProviderLogger =
            prefs.getBool(_keyEnableProviderLogger) ?? false;
        _enableVerboseLog = prefs.getBool(_keyEnableVerboseLog) ?? false;
        _enableClarityDebug = prefs.getBool(_keyEnableClarityDebug) ?? false;
      });
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载日志设置失败');
    }
  }

  /// 保存Provider调试设置
  Future<void> _saveProviderLoggerSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableProviderLogger, value);
      setState(() {
        _enableProviderLogger = value;
      });
      GlobalMsgManager.showMessage('设置已保存，重启应用后生效');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存Provider调试设置失败');
    }
  }

  /// 保存Verbose日志设置
  Future<void> _saveVerboseLogSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableVerboseLog, value);
      setState(() {
        _enableVerboseLog = value;
      });

      // 同时更新Provider中的状态
      ref.read(verboseLogProvider.notifier).setVerboseLogEnabled(value);

      GlobalMsgManager.showMessage('Verbose日志已${value ? '启用' : '禁用'}');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存Verbose日志设置失败');
    }
  }

  /// 保存Clarity调试设置
  Future<void> _saveClarityDebugSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnableClarityDebug, value);
      setState(() {
        _enableClarityDebug = value;
      });
      GlobalMsgManager.showMessage(
          'Clarity调试日志已${value ? '启用' : '禁用'}，重启应用后生效');
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '保存Clarity调试设置失败');
    }
  }

  /// 测试日志级别
  void _testLogLevels() {
    // 先输出当前日志级别信息
    final verboseEnabled = ref.read(verboseLogProvider);
    Log.i('=== 日志级别测试开始 ===');
    Log.i('当前Verbose日志状态: ${verboseEnabled ? '启用' : '禁用'}');
    Log.i(
        '当前日志级别: ${verboseEnabled ? 'Trace (包含Verbose)' : 'Debug (不包含Verbose)'}');

    // 输出各级别日志
    Log.v('这是Verbose级别日志 - 最详细的调试信息 ${verboseEnabled ? '(应该显示)' : '(应该被过滤)'}');
    Log.d('这是Debug级别日志 - 调试信息 (应该显示)');
    Log.i('这是Info级别日志 - 一般信息 (应该显示)');
    Log.w('这是Warning级别日志 - 警告信息 (应该显示)');
    Log.e('这是Error级别日志 - 错误信息 (应该显示)');

    // 也测试带颜色的verbose日志
    Log.verbose('这是带颜色的Verbose日志 ${verboseEnabled ? '(应该显示)' : '(应该被过滤)'}',
        color: Colors.grey);

    Log.i('=== 日志级别测试结束 ===');

    GlobalMsgManager.showMessage(
        '已输出各级别日志，请查看程序日志页面\n当前Verbose: ${verboseEnabled ? '启用' : '禁用'}');
  }

  /// 显示清理缓冲区确认对话框
  void _showClearBufferDialog() {
    globalState.showCommonDialog(
      child: AlertDialog(
        title: const Text('确认清理'),
        content: const Text('确定要清空日志缓冲区吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(logExportProvider.notifier).clearLogBuffer();
              GlobalMsgManager.showMessage('日志缓冲区已清理');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建日志导出状态显示
  Widget _buildLogExportStatus() {
    final state = ref.watch(logExportProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '日志导出状态',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              _buildStatusRow('监听状态', state.isListening ? '正在监听' : '已停止',
                  state.isListening ? Colors.green : Colors.grey),
              _buildStatusRow('缓冲区大小', '${state.bufferSize} 条日志', Colors.blue),
              if (state.lastExportTime != null)
                _buildStatusRow(
                    '最后导出',
                    '${state.lastExportTime!.year}-${state.lastExportTime!.month.toString().padLeft(2, '0')}-${state.lastExportTime!.day.toString().padLeft(2, '0')} ${state.lastExportTime!.hour.toString().padLeft(2, '0')}:${state.lastExportTime!.minute.toString().padLeft(2, '0')}',
                    Colors.orange),
              if (state.isExporting)
                _buildStatusRow('导出状态', '正在导出...', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态行
  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
