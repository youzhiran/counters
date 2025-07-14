import 'dart:async';

import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/ping_provider.dart';
import 'package:counters/features/setting/ping_display_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ping值显示组件
/// 仅在客户端模式下显示与主机的ping值，主机端不显示
/// 支持拖动和智能透明度调节
class PingWidget extends ConsumerStatefulWidget {
  const PingWidget({super.key});

  @override
  ConsumerState<PingWidget> createState() => _PingWidgetState();
}

class _PingWidgetState extends ConsumerState<PingWidget>
    with TickerProviderStateMixin {
  // 原有的ping状态动画控制器（用于闪烁效果）
  late AnimationController _pingAnimationController;
  late Animation<double> _pingOpacityAnimation;

  // 新增：智能透明度动画控制器
  late AnimationController _smartOpacityController;
  late Animation<double> _smartOpacityAnimation;

  // 新增：拖动相关状态
  Offset _position = const Offset(16, 100); // 默认位置
  bool _isDragging = false;
  Timer? _inactivityTimer;

  // 新增：拖动视觉反馈动画控制器
  late AnimationController _dragFeedbackController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化ping状态动画控制器（原有功能）
    _pingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pingOpacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pingAnimationController,
      curve: Curves.easeInOut,
    ));

    // 初始化智能透明度控制器
    _smartOpacityController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _smartOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _smartOpacityController,
      curve: Curves.easeInOut,
    ));

    // 初始化拖动反馈动画控制器
    _dragFeedbackController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _dragFeedbackController,
      curve: Curves.easeOut,
    ));
    _shadowAnimation = Tween<double>(
      begin: 4.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _dragFeedbackController,
      curve: Curves.easeOut,
    ));

    // 启动不活跃计时器
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _pingAnimationController.dispose();
    _smartOpacityController.dispose();
    _dragFeedbackController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// 启动不活跃计时器
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isDragging) {
        final pingState = ref.read(pingProvider);
        // 只有在网络状态良好时才降低透明度
        if (_shouldReduceOpacity(pingState)) {
          _smartOpacityController.forward();
        }
      }
    });
  }

  /// 重置不活跃计时器
  void _resetInactivityTimer() {
    _smartOpacityController.reverse();
    _startInactivityTimer();
  }

  /// 判断是否应该降低透明度
  bool _shouldReduceOpacity(PingState pingState) {
    if (pingState.error != null) return false;
    if (pingState.pingMs == null) return false;
    // 网络状态为excellent或good时才降低透明度
    return pingState.status == PingStatus.excellent || pingState.status == PingStatus.good;
  }

  /// 确保位置在屏幕边界内
  Offset _clampPosition(Offset position, Size screenSize, Size widgetSize) {
    final double maxX = screenSize.width - widgetSize.width;
    final double maxY = screenSize.height - widgetSize.height;

    return Offset(
      position.dx.clamp(0.0, maxX),
      position.dy.clamp(MediaQuery.of(context).padding.top, maxY),
    );
  }

  /// 检测并调整位置，确保组件在屏幕范围内
  void _ensurePositionInBounds(Size screenSize) {
    Log.v('PingWidget: 检测并调整位置，确保组件在屏幕范围内');
    // 估算组件大小（与拖动时使用的估算值一致）
    const Size estimatedWidgetSize = Size(100, 30);

    // 计算调整后的位置
    final Offset adjustedPosition = _clampPosition(_position, screenSize, estimatedWidgetSize);

    // 如果位置需要调整，更新位置
    if (adjustedPosition != _position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _position = adjustedPosition;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pingState = ref.watch(pingProvider);
    final showPingWidget = ref.watch(pingDisplaySettingProvider);

    // 如果ping不活跃或用户设置不显示，不显示组件
    if (!pingState.isActive || !showPingWidget) {
      return const SizedBox.shrink();
    }

    // 控制ping状态动画（原有功能）
    _controlPingAnimation(pingState);

    // 管理智能透明度
    _manageSmartOpacity(pingState);

    final screenSize = MediaQuery.of(context).size;

    // 检测并调整位置，确保组件在屏幕范围内
    _ensurePositionInBounds(screenSize);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
          _resetInactivityTimer();
          _dragFeedbackController.forward();
        },
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
            // 实时约束位置（粗略估算widget大小）
            _position = _clampPosition(_position, screenSize, const Size(100, 30));
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
          _dragFeedbackController.reverse();
          _resetInactivityTimer();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pingOpacityAnimation,
            _smartOpacityAnimation,
            _scaleAnimation,
            _shadowAnimation,
          ]),
          builder: (context, child) {
            // 计算最终透明度：ping动画透明度 * 智能透明度
            final double finalOpacity = _pingOpacityAnimation.value * _smartOpacityAnimation.value;

            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: finalOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPingBackgroundColor(pingState.status),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: _shadowAnimation.value,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPingIcon(pingState.status),
                        size: 14,
                        color: _getPingTextColor(pingState.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pingState.displayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getPingTextColor(pingState.status),
                          decoration: TextDecoration.none, // 明确移除下划线装饰
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 管理智能透明度
  void _manageSmartOpacity(PingState pingState) {
    // 如果网络状态变差或正在拖动，立即恢复正常透明度
    if (_isDragging || !_shouldReduceOpacity(pingState)) {
      _smartOpacityController.reverse();
    }
  }

  /// 控制ping状态动画（原有功能，重命名以避免混淆）
  void _controlPingAnimation(PingState pingState) {
    switch (pingState.status) {
      case PingStatus.error:
      case PingStatus.poor:
        // 错误或较差状态时闪烁
        if (!_pingAnimationController.isAnimating) {
          _pingAnimationController.repeat(reverse: true);
        }
        break;
      case PingStatus.unknown:
        // 未知状态时缓慢闪烁
        if (!_pingAnimationController.isAnimating) {
          _pingAnimationController.repeat(
            reverse: true,
            period: const Duration(milliseconds: 2000),
          );
        }
        break;
      default:
        // 正常状态时停止动画，保持完全不透明
        _pingAnimationController.stop();
        _pingAnimationController.value = 1.0;
        break;
    }
  }

  /// 获取ping状态对应的图标
  IconData _getPingIcon(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return Icons.signal_wifi_4_bar;
      case PingStatus.good:
        return Icons.signal_wifi_4_bar;
      case PingStatus.fair:
        return Icons.network_wifi_3_bar;
      case PingStatus.poor:
        return Icons.network_wifi_2_bar;
      case PingStatus.error:
        return Icons.signal_wifi_off;
      case PingStatus.unknown:
        return Icons.network_wifi_1_bar;
    }
  }

  /// 获取ping状态对应的背景颜色
  Color _getPingBackgroundColor(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return Colors.green.withValues(alpha: 0.9);
      case PingStatus.good:
        return Colors.lightGreen.withValues(alpha: 0.9);
      case PingStatus.fair:
        return Colors.orange.withValues(alpha: 0.9);
      case PingStatus.poor:
        return Colors.red.withValues(alpha: 0.9);
      case PingStatus.error:
        return Colors.red.withValues(alpha: 0.9);
      case PingStatus.unknown:
        return Colors.grey.withValues(alpha: 0.9);
    }
  }

  /// 获取ping状态对应的文字颜色
  Color _getPingTextColor(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
      case PingStatus.good:
      case PingStatus.fair:
      case PingStatus.poor:
      case PingStatus.error:
        return Colors.white;
      case PingStatus.unknown:
        return Colors.white70;
    }
  }
}
