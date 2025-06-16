import 'package:counters/features/lan/ping_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ping值显示组件
/// 在联机状态下显示与主机的ping值
class PingWidget extends ConsumerStatefulWidget {
  const PingWidget({super.key});

  @override
  ConsumerState<PingWidget> createState() => _PingWidgetState();
}

class _PingWidgetState extends ConsumerState<PingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pingState = ref.watch(pingProvider);

    // 如果ping不活跃，不显示组件
    if (!pingState.isActive) {
      return const SizedBox.shrink();
    }

    // 控制动画
    _controlAnimation(pingState);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPingBackgroundColor(pingState.status),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 控制动画状态
  void _controlAnimation(PingState pingState) {
    switch (pingState.status) {
      case PingStatus.error:
      case PingStatus.poor:
        // 错误或较差状态时闪烁
        if (!_animationController.isAnimating) {
          _animationController.repeat(reverse: true);
        }
        break;
      case PingStatus.unknown:
        // 未知状态时缓慢闪烁
        if (!_animationController.isAnimating) {
          _animationController.repeat(
            reverse: true,
            period: const Duration(milliseconds: 2000),
          );
        }
        break;
      default:
        // 正常状态时停止动画，保持完全不透明
        _animationController.stop();
        _animationController.value = 1.0;
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
