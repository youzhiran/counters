import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:counters/app/config.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/port_manager.dart';
import 'package:counters/features/setting/port_config_provider.dart';

class PortTestPage extends ConsumerStatefulWidget {
  const PortTestPage({super.key});

  @override
  ConsumerState<PortTestPage> createState() => _PortTestPageState();
}

class _PortTestPageState extends ConsumerState<PortTestPage> {
  int? _customDiscoveryPort;
  int? _customWebSocketPort;
  int? _availableDiscoveryPort;
  int? _availableWebSocketPort;
  bool _isLoading = false;
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final discoveryPort = await PortManager.getCustomDiscoveryPort();
      final webSocketPort = await PortManager.getCustomWebSocketPort();
      setState(() {
        _customDiscoveryPort = discoveryPort;
        _customWebSocketPort = webSocketPort;
      });
    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '加载端口设置失败');
    }
  }

  Future<void> _testPortAvailability() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    try {
      // 测试默认广播端口
      final defaultDiscoveryAvailable = !await PortManager.isUdpPortOccupied(Config.discoveryPort);
      _testResults.add('默认广播端口 ${Config.discoveryPort}: ${defaultDiscoveryAvailable ? "可用" : "被占用"}');

      // 测试默认服务端口
      final defaultWebSocketAvailable = !await PortManager.isTcpPortOccupied(Config.webSocketPort);
      _testResults.add('默认服务端口 ${Config.webSocketPort}: ${defaultWebSocketAvailable ? "可用" : "被占用"}');

      // 测试自定义端口
      if (_customDiscoveryPort != null) {
        final customDiscoveryAvailable = !await PortManager.isUdpPortOccupied(_customDiscoveryPort!);
        _testResults.add('自定义广播端口 $_customDiscoveryPort: ${customDiscoveryAvailable ? "可用" : "被占用"}');
      }

      if (_customWebSocketPort != null) {
        final customWebSocketAvailable = !await PortManager.isTcpPortOccupied(_customWebSocketPort!);
        _testResults.add('自定义服务端口 $_customWebSocketPort: ${customWebSocketAvailable ? "可用" : "被占用"}');
      }

      // 获取当前配置的端口
      final currentDiscoveryPort = await PortManager.getCurrentDiscoveryPort();
      final currentWebSocketPort = await PortManager.getCurrentWebSocketPort();

      setState(() {
        _availableDiscoveryPort = currentDiscoveryPort;
        _availableWebSocketPort = currentWebSocketPort;
      });

      _testResults.add('当前配置的广播端口: $currentDiscoveryPort');
      _testResults.add('当前配置的服务端口: $currentWebSocketPort');

      // 测试广播端口范围内的所有端口
      _testResults.add('\n广播端口范围测试:');
      for (int port = Config.discoveryPortMin; port <= Config.discoveryPortMax; port++) {
        final isOccupied = await PortManager.isUdpPortOccupied(port);
        _testResults.add('UDP端口 $port: ${isOccupied ? "被占用" : "可用"}');
      }

      // 测试服务端口范围内的所有端口
      _testResults.add('\n服务端口范围测试:');
      for (int port = Config.webSocketPortMin; port <= Config.webSocketPortMax; port++) {
        final isOccupied = await PortManager.isTcpPortOccupied(port);
        _testResults.add('TCP端口 $port: ${isOccupied ? "被占用" : "可用"}');
      }

    } catch (e) {
      ErrorHandler.handle(e, StackTrace.current, prefix: '端口测试失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final portConfig = ref.watch(portConfigProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('端口管理测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前设置信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前设置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('默认广播端口: ${Config.discoveryPort}'),
                    Text('广播端口范围: ${Config.discoveryPortMin}-${Config.discoveryPortMax}'),
                    Text('自定义广播端口: ${_customDiscoveryPort ?? "未设置"}'),
                    Text('当前配置的广播端口: ${_availableDiscoveryPort ?? "未检测"}'),
                    const SizedBox(height: 8),
                    Text('默认服务端口: ${Config.webSocketPort}'),
                    Text('服务端口范围: ${Config.webSocketPortMin}-${Config.webSocketPortMax}'),
                    Text('自定义服务端口: ${_customWebSocketPort ?? "未设置"}'),
                    Text('当前配置的服务端口: ${_availableWebSocketPort ?? "未检测"}'),
                    const SizedBox(height: 8),
                    Text('Provider状态: 广播端口=${portConfig.discoveryPort}, 服务端口=${portConfig.webSocketPort}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 测试按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _testPortAvailability,
              child: _isLoading 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('测试中...'),
                    ],
                  )
                : const Text('测试端口可用性'),
            ),
            
            const SizedBox(height: 16),
            
            // 测试结果
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '测试结果',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _testResults.isEmpty
                          ? const Center(
                              child: Text(
                                '点击上方按钮开始测试',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _testResults.length,
                              itemBuilder: (context, index) {
                                final result = _testResults[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    result,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: result.contains('被占用') 
                                        ? Colors.red 
                                        : result.contains('可用') 
                                          ? Colors.green 
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
