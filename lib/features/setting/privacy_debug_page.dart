import 'package:counters/common/providers/privacy_version_provider.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/common/utils/privacy.dart';
import 'package:counters/common/widgets/message_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 隐私政策调试页面
class PrivacyDebugPage extends ConsumerStatefulWidget {
  const PrivacyDebugPage({super.key});

  @override
  ConsumerState<PrivacyDebugPage> createState() => _PrivacyDebugPageState();
}

class _PrivacyDebugPageState extends ConsumerState<PrivacyDebugPage> {
  Map<String, dynamic>? _privacyStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyStatus();
  }

  Future<void> _loadPrivacyStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await PrivacyUtil.getPrivacyStatus();
      setState(() {
        _privacyStatus = status;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasUpdate = await ref.read(privacyVersionProvider.notifier).checkForUpdate();
      ref.showSuccess(hasUpdate ? '检测到隐私政策更新' : '隐私政策已是最新版本');
      await _loadPrivacyStatus();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _manualCheck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasUpdate = await PrivacyUtil.checkPrivacyUpdate();
      ref.showSuccess(hasUpdate ? '检测到隐私政策更新' : '隐私政策已是最新版本');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showPrivacyDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PrivacyUtil.initWithPrivacy(context);
      Log.i('隐私政策弹窗已显示');
      await _loadPrivacyStatus();
    } catch (e) {
      ref.showWarning('显示隐私政策弹窗失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPrivacyAgreed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacy_agreed');
      ref.showSuccess('已删除 privacy_agreed 键');
      await _loadPrivacyStatus();
    } catch (e) {
      ref.showWarning('删除失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPrivacyTime() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacy_time');
      ref.showSuccess('已删除 privacy_time 键');
      await _loadPrivacyStatus();
    } catch (e) {
      ref.showWarning('删除失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllPrivacyKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacy_agreed');
      await prefs.remove('privacy_time');
      ref.showSuccess('已删除所有隐私政策相关键');
      await _loadPrivacyStatus();
    } catch (e) {
      ref.showWarning('删除失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyState = ref.watch(privacyVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策调试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_privacyStatus != null) ...[
                      Text('privacy_agreed键: ${_privacyStatus!['hasAgreedKey']}'),
                      Text('privacy_time键: ${_privacyStatus!['hasTimeKey']}'),
                      Text('已同意: ${_privacyStatus!['agreed']}'),
                      Text('同意状态类型: ${_privacyStatus!['agreedType']}'),
                      Text('时间戳: ${_privacyStatus!['timestamp']}'),
                      Text('时间戳类型: ${_privacyStatus!['timeType']}'),
                      if (_privacyStatus!['error'] != null)
                        Text('错误: ${_privacyStatus!['error']}',
                             style: const TextStyle(color: Colors.red)),
                    ] else
                      const Text('加载失败'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 远程状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('加载中: ${privacyState.isLoading}'),
                    Text('有更新: ${privacyState.hasUpdate}'),
                    Text('本地时间戳: ${privacyState.localTimestamp ?? '无'}'),
                    Text('错误: ${privacyState.error ?? '无'}'),
                    if (privacyState.remoteVersion != null) ...[
                      Text('远程版本: ${privacyState.remoteVersion!.version}'),
                      Text('远程时间戳: ${privacyState.remoteVersion!.timestamp}'),
                      Text('生成时间: ${privacyState.remoteVersion!.generatedAt}'),
                    ] else
                      const Text('远程版本: 未获取'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadPrivacyStatus,
                  child: const Text('刷新本地状态'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkUpdate,
                  child: const Text('检查更新(Provider)'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _manualCheck,
                  child: const Text('手动检查更新'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showPrivacyDialog,
                  child: const Text('显示隐私政策弹窗'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 删除操作按钮
            Text(
              '危险操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearPrivacyAgreed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('删除 privacy_agreed'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearPrivacyTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('删除 privacy_time'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearAllPrivacyKeys,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('删除所有隐私政策键'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
