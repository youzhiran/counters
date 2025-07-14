import 'package:counters/features/lan/lan_provider.dart';
import 'package:counters/features/lan/widgets/lan_status_sheet.dart';
import 'package:counters/features/lan/widgets/lan_status_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 可复用的LAN状态按钮组件
/// 包含图标、动画、点击事件等完整功能
class LanStatusButton extends ConsumerStatefulWidget {
  const LanStatusButton({super.key});

  @override
  ConsumerState<LanStatusButton> createState() => _LanStatusButtonState();
}

class _LanStatusButtonState extends ConsumerState<LanStatusButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  bool _hasInitializedAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画控制器
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lanState = ref.watch(lanProvider);

    // 监听LAN状态变化以控制动画
    ref.listen<LanState>(lanProvider, (previous, next) {
      _handleAnimationStateChange(previous, next);
    });

    // 检查当前状态是否需要动画（用于初始状态）
    if (!_hasInitializedAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasInitializedAnimation = true;
          _handleAnimationStateChange(null, lanState);
        }
      });
    }

    // 如果不应该显示按钮，返回空容器
    if (!LanStatusUtils.shouldShowLanButton(lanState)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: _buildLanIcon(lanState),
      tooltip: LanStatusUtils.getLanTooltip(lanState),
      onPressed: () => _showLanStatus(context),
    );
  }

  /// 构建LAN状态图标，包含动画效果
  Widget _buildLanIcon(LanState lanState) {
    final icon = Icon(
      LanStatusUtils.getLanIcon(lanState),
      color: LanStatusUtils.getLanIconColor(lanState),
    );

    // 如果需要动画效果，使用闪烁动画
    if (LanStatusUtils.needsAnimation(lanState)) {
      return FadeTransition(
        opacity: _opacityAnimation,
        child: icon,
      );
    }

    // 其他状态不使用动画
    return icon;
  }

  /// 处理动画状态变化
  void _handleAnimationStateChange(LanState? previous, LanState next) {
    if (!mounted) return;

    final wasAnimating = previous != null && LanStatusUtils.needsAnimation(previous);
    final shouldAnimate = LanStatusUtils.needsAnimation(next);

    if (shouldAnimate && !wasAnimating) {
      // 开始动画
      _animationController.repeat(reverse: true);
    } else if (!shouldAnimate && wasAnimating) {
      // 停止动画
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  /// 显示LAN状态对话框
  void _showLanStatus(BuildContext context) {
    showLanStatusSheet();
  }
}
