import 'package:counters/common/providers/message_provider.dart';
import 'package:counters/common/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 消息覆盖层组件
/// 用于在应用顶层显示消息，支持多消息垂直堆叠显示
class MessageOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const MessageOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends ConsumerState<MessageOverlay> {
  final Map<String, OverlayEntry> _overlayEntries = {}; // 管理多个OverlayEntry
  final Map<String, GlobalKey> _messageKeys = {}; // 用于测量消息高度
  final Map<String, GlobalKey<_MessageCardState>> _messageCardKeys =
      {}; // 用于控制消息卡片动画
  static const double _messageSpacing = 8.0; // 消息间距
  static const double _topPadding = 16.0; // 顶部间距

  @override
  void dispose() {
    _hideAllMessages();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保在依赖变化时重新建立监听
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveMessages();
    });
  }

  /// 同步活跃消息显示
  void _syncActiveMessages() {
    final activeMessages = ref.read(messageManagerProvider).activeMessages;

    // 移除不再活跃的消息
    final currentIds = _overlayEntries.keys.toSet();
    final activeIds = activeMessages.map((msg) => msg.id).toSet();

    for (final id in currentIds) {
      if (!activeIds.contains(id)) {
        _hideMessage(id);
      }
    }

    // 检查消息状态变化，触发退出动画
    for (final message in activeMessages) {
      if (message.status == MessageStatus.exiting) {
        _triggerMessageExit(message.id);
      } else if (!_overlayEntries.containsKey(message.id)) {
        _showMessage(message);
      }
    }
  }

  /// 触发消息退出动画
  void _triggerMessageExit(String messageId) {
    final messageCardKey = _messageCardKeys[messageId];
    if (messageCardKey?.currentState != null) {
      // Log.v('MessageOverlay: 触发消息退出动画 - ID: $messageId');
      messageCardKey!.currentState!.startExitAnimation();
    }
  }

  /// 显示单个消息
  void _showMessage(AppMessage message) {
    try {
      if (_overlayEntries.containsKey(message.id)) {
        Log.v('MessageOverlay: 消息已在显示中，跳过 - ${message.content}');
        return;
      }

      // 创建消息的GlobalKey用于高度测量
      final messageKey = GlobalKey();
      _messageKeys[message.id] = messageKey;

      // 创建消息卡片的GlobalKey用于控制动画
      final messageCardKey = GlobalKey<_MessageCardState>();
      _messageCardKeys[message.id] = messageCardKey;

      final overlayEntry = OverlayEntry(
        builder: (context) => _MessagePositioned(
          messageId: message.id,
          messageKey: messageKey,
          messageCardKey: messageCardKey,
          message: message,
          onDismiss: () {
            ref
                .read(messageManagerProvider.notifier)
                .dismissMessage(message.id);
          },
          positionCalculator: () => _calculateMessagePosition(message),
        ),
      );

      _overlayEntries[message.id] = overlayEntry;

      try {
        // 使用 Overlay 在最顶层显示消息
        final overlay = Overlay.of(context, rootOverlay: true);
        overlay.insert(overlayEntry);
        // Log.v('MessageOverlay: 成功显示消息 [ID:${message.id}] - ${message.content}');

        // 显示后重新计算所有消息位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAllMessagePositions();
        });
      } catch (e) {
        Log.e('MessageOverlay: 插入Overlay失败 - $e');
        _overlayEntries.remove(message.id);
        _messageKeys.remove(message.id);
        _messageCardKeys.remove(message.id);
      }
    } catch (e, stackTrace) {
      Log.e('MessageOverlay: 显示消息失败 - $e');
      Log.e('StackTrace: $stackTrace');
    }
  }

  /// 隐藏指定消息
  void _hideMessage(String messageId) {
    final overlayEntry = _overlayEntries[messageId];
    if (overlayEntry == null) return;

    try {
      // 立即移除OverlayEntry，因为退出动画已经在_MessageCard中处理
      overlayEntry.remove();
      _overlayEntries.remove(messageId);
      _messageKeys.remove(messageId);
      _messageCardKeys.remove(messageId);
      // Log.v('MessageOverlay: 成功隐藏消息 - ID: $messageId');

      // 隐藏后重新计算剩余消息位置
      if (mounted) {
        _updateAllMessagePositions();
      }
    } catch (e) {
      // Log.e('MessageOverlay: 隐藏消息失败 - $e');
      _overlayEntries.remove(messageId);
      _messageKeys.remove(messageId);
      _messageCardKeys.remove(messageId);
    }
  }

  /// 隐藏所有消息
  void _hideAllMessages() {
    for (final messageId in _overlayEntries.keys.toList()) {
      final overlayEntry = _overlayEntries[messageId];
      try {
        overlayEntry?.remove();
      } catch (e) {
        Log.e('MessageOverlay: 移除Overlay失败 - $e');
      }
    }
    _overlayEntries.clear();
    _messageKeys.clear();
    _messageCardKeys.clear();
  }

  /// 计算消息的垂直位置
  double _calculateMessagePosition(AppMessage message) {
    try {
      final activeMessages = ref.read(messageManagerProvider).activeMessages;
      final messageIndex =
          activeMessages.indexWhere((msg) => msg.id == message.id);

      if (messageIndex == -1) {
        return _calculateSafeTopPosition();
      }

      double position = _calculateSafeTopPosition();

      // 累加前面消息的高度
      for (int i = 0; i < messageIndex; i++) {
        final prevMessage = activeMessages[i];
        final prevKey = _messageKeys[prevMessage.id];

        if (prevKey?.currentContext != null) {
          final renderBox =
              prevKey!.currentContext!.findRenderObject() as RenderBox?;
          // 检查RenderBox是否已完成布局且有有效尺寸
          if (renderBox != null && renderBox.hasSize) {
            position += renderBox.size.height + _messageSpacing;
          } else {
            // 如果RenderBox未完成布局或无法获取实际高度，使用估算高度
            position += 80.0 + _messageSpacing; // 估算的消息卡片高度
          }
        } else {
          // 如果无法获取实际高度，使用估算高度
          position += 80.0 + _messageSpacing;
        }
      }

      return position;
    } catch (e, stackTrace) {
      // 使用ErrorHandler处理错误，但不显示用户消息以避免递归
      Log.e('MessageOverlay: 计算消息位置失败 - $e');
      Log.e('StackTrace: $stackTrace');
      // 返回安全的默认位置
      return _calculateSafeTopPosition();
    }
  }

  /// 计算安全的顶部位置，避开AppBar区域
  double _calculateSafeTopPosition() {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    // 尝试检测当前页面是否有AppBar
    double appBarHeight = 0;
    bool hasAppBar = false;

    try {
      // 查找当前页面的Scaffold
      final scaffoldContext = Scaffold.maybeOf(context);
      if (scaffoldContext != null) {
        // 检查是否有AppBar - 通过查找AppBar widget
        context.visitAncestorElements((element) {
          if (element.widget is AppBar) {
            hasAppBar = true;
            return false; // 找到AppBar，停止遍历
          }
          return true; // 继续遍历
        });

        if (hasAppBar) {
          // 获取AppBar的默认高度
          appBarHeight = kToolbarHeight;

          // 检查是否有多行标题（subtitle）
          context.visitAncestorElements((element) {
            if (element.widget is AppBar) {
              final appBar = element.widget as AppBar;
              // 如果AppBar的title是Column，说明可能有subtitle，需要更多空间
              if (appBar.title is Column) {
                appBarHeight += 20; // 为subtitle预留额外空间
              }
              return false;
            }
            return true;
          });
        }
      }
    } catch (e) {
      Log.w('MessageOverlay: 检测AppBar失败，使用默认配置 - $e');
      // 发生错误时，保守地假设有AppBar
      hasAppBar = true;
      appBarHeight = kToolbarHeight;
    }

    // 计算安全位置
    final safeTop =
        statusBarHeight + (hasAppBar ? appBarHeight : 0) + _topPadding;

    // Log.v(
    //     'MessageOverlay: 计算安全位置 - 状态栏:${statusBarHeight}px, AppBar:${hasAppBar ? appBarHeight : 0}px (检测到:$hasAppBar), 总计:${safeTop}px');

    return safeTop;
  }

  /// 更新所有消息的位置
  void _updateAllMessagePositions() {
    if (!mounted) return;

    final activeMessages = ref.read(messageManagerProvider).activeMessages;

    for (final message in activeMessages) {
      final overlayEntry = _overlayEntries[message.id];

      if (overlayEntry != null) {
        // 通过markNeedsBuild触发重建，_MessagePositioned会重新计算位置
        overlayEntry.markNeedsBuild();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听消息状态变化
    ref.listen<MessageState>(messageManagerProvider, (previous, next) {
      // Log.v(
      //     'MessageOverlay: 活跃消息变化 ${previous?.activeMessages.length ?? 0} -> ${next.activeMessages.length}');
      _syncActiveMessages();
    });

    return widget.child;
  }
}

/// 消息定位组件 - 处理动态位置计算
class _MessagePositioned extends StatefulWidget {
  final String messageId;
  final GlobalKey messageKey;
  final GlobalKey<_MessageCardState> messageCardKey;
  final AppMessage message;
  final VoidCallback onDismiss;
  final double Function() positionCalculator;

  const _MessagePositioned({
    required this.messageId,
    required this.messageKey,
    required this.messageCardKey,
    required this.message,
    required this.onDismiss,
    required this.positionCalculator,
  });

  @override
  State<_MessagePositioned> createState() => _MessagePositionedState();
}

class _MessagePositionedState extends State<_MessagePositioned>
    with SingleTickerProviderStateMixin {
  late AnimationController _positionController;
  late Animation<double> _positionAnimation;
  double _currentTop = 0;

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 延迟位置计算到下一帧，确保所有RenderBox都已完成布局
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _currentTop = widget.positionCalculator();
          _positionAnimation = Tween<double>(
            begin: _currentTop,
            end: _currentTop,
          ).animate(CurvedAnimation(
            parent: _positionController,
            curve: Curves.easeInOut,
          ));
          // 触发重建以应用新的位置
          if (mounted) {
            setState(() {});
          }
        } catch (e, stackTrace) {
          // 使用ErrorHandler处理错误
          Log.e('MessagePositioned: 初始化位置计算失败 - $e');
          Log.e('StackTrace: $stackTrace');
          // 使用默认位置
          _currentTop = 100.0; // 安全的默认位置
          _positionAnimation = Tween<double>(
            begin: _currentTop,
            end: _currentTop,
          ).animate(CurvedAnimation(
            parent: _positionController,
            curve: Curves.easeInOut,
          ));
          if (mounted) {
            setState(() {});
          }
        }
      }
    });

    // 初始化时使用安全的默认位置
    _currentTop = 100.0; // 临时默认位置，将在postFrameCallback中更新
    _positionAnimation = Tween<double>(
      begin: _currentTop,
      end: _currentTop,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  /// 更新位置
  void updatePosition() {
    try {
      final newTop = widget.positionCalculator();
      if (newTop != _currentTop) {
        _positionAnimation = Tween<double>(
          begin: _currentTop,
          end: newTop,
        ).animate(CurvedAnimation(
          parent: _positionController,
          curve: Curves.easeInOut,
        ));

        _positionController.reset();
        _positionController.forward();
        _currentTop = newTop;
      }
    } catch (e, stackTrace) {
      // 使用ErrorHandler处理错误
      Log.e('MessagePositioned: 更新位置失败 - $e');
      Log.e('StackTrace: $stackTrace');
      // 位置更新失败时保持当前位置不变
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, child) {
        return Positioned(
          top: _positionAnimation.value,
          left: 16,
          right: 16,
          child: _MessageCard(
            key: widget.messageCardKey,
            messageKey: widget.messageKey,
            message: widget.message,
            onDismiss: widget.onDismiss,
          ),
        );
      },
    );
  }
}

/// 滑动删除方向枚举
enum SwipeDismissDirection {
  up,
  left,
  right,
}

/// 滑动状态枚举
enum SwipeState {
  idle,      // 空闲状态
  dragging,  // 拖拽中
  dismissing, // 正在删除
}

/// 消息卡片组件
class _MessageCard extends StatefulWidget {
  final GlobalKey messageKey;
  final AppMessage message;
  final VoidCallback onDismiss;

  const _MessageCard({
    super.key,
    required this.messageKey,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExiting = false;

  // 滑动删除相关状态
  SwipeState _swipeState = SwipeState.idle;
  Offset _totalDragOffset = Offset.zero; // 累计滑动偏移量
  SwipeDismissDirection? _detectedDirection; // 检测到的滑动方向

  // 滑动阈值配置
  static const double _swipeThreshold = 120.0; // 滑动删除阈值（像素）
  static const double _velocityThreshold = 300.0; // 速度阈值（像素/秒）
  static const double _directionDetectionThreshold = 30.0; // 方向检测阈值（像素）

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _setupEnterAnimation();
    _animationController.forward();
  }

  /// 设置进入动画
  void _setupEnterAnimation() {
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  /// 设置退出动画
  void _setupExitAnimation({SwipeDismissDirection? direction}) {
    Offset endOffset;

    // 根据滑动方向设置不同的退出动画
    if (direction != null) {
      switch (direction) {
        case SwipeDismissDirection.up:
          endOffset = const Offset(0, -2); // 向上退出
          break;
        case SwipeDismissDirection.left:
          endOffset = const Offset(-2, 0); // 向左退出
          break;
        case SwipeDismissDirection.right:
          endOffset = const Offset(2, 0); // 向右退出
          break;
      }
    } else {
      // 默认向上退出（兼容原有逻辑）
      endOffset = const Offset(0, -1);
    }

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero, // 从原位置开始
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
      case MessageType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon(MessageType type) {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.error:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
    }
  }

  /// 外部调用的退出动画方法
  void startExitAnimation() {
    if (_isExiting) return; // 防止重复调用
    _dismiss();
  }

  void _dismiss({SwipeDismissDirection? direction}) async {
    if (_isExiting) return; // 防止重复调用

    // Log.v(
    //     'MessageCard [ID:${widget.message.id}]: 开始关闭动画 - ${widget.message.content}');

    setState(() {
      _isExiting = true;
      _swipeState = SwipeState.dismissing;
    });

    // 设置退出动画
    _setupExitAnimation(direction: direction);

    // 重置动画控制器并播放退出动画
    _animationController.reset();
    await _animationController.forward();

    if (mounted) {
      // Log.v('MessageCard [ID:${widget.message.id}]: 动画完成，触发关闭回调');
      widget.onDismiss();
    }
  }

  /// 处理滑动开始
  void _onPanStart(DragStartDetails details) {
    if (_isExiting || _swipeState == SwipeState.dismissing) return;

    setState(() {
      _swipeState = SwipeState.dragging;
      _totalDragOffset = Offset.zero;
      _detectedDirection = null; // 重置检测到的方向
    });
  }

  /// 处理滑动更新
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isExiting || _swipeState != SwipeState.dragging) return;

    // 累计滑动偏移量
    _totalDragOffset += details.delta;

    // 如果还没有检测到方向，检查是否需要确定方向
    if (_detectedDirection == null) {
      final dx = _totalDragOffset.dx.abs();
      final dy = _totalDragOffset.dy.abs();

      // 达到方向检测阈值时确定滑动方向
      if (dx > _directionDetectionThreshold || dy > _directionDetectionThreshold) {
        if (dx > dy) {
          // 水平滑动
          _detectedDirection = _totalDragOffset.dx > 0 ? SwipeDismissDirection.right : SwipeDismissDirection.left;
        } else if (_totalDragOffset.dy < 0) {
          // 只允许向上的垂直滑动
          _detectedDirection = SwipeDismissDirection.up;
        } else {
          // 向下滑动不允许，重置状态
          _resetToIdle();
          return;
        }
      }
    }

    // 检查是否达到删除阈值
    if (_detectedDirection != null) {
      bool shouldDismiss = false;

      switch (_detectedDirection!) {
        case SwipeDismissDirection.up:
          shouldDismiss = _totalDragOffset.dy < -_swipeThreshold;
          break;
        case SwipeDismissDirection.left:
          shouldDismiss = _totalDragOffset.dx < -_swipeThreshold;
          break;
        case SwipeDismissDirection.right:
          shouldDismiss = _totalDragOffset.dx > _swipeThreshold;
          break;
      }

      if (shouldDismiss) {
        // 立即触发删除动画
        _dismiss(direction: _detectedDirection);
        return;
      }
    }
  }

  /// 处理滑动结束
  void _onPanEnd(DragEndDetails details) {
    if (_isExiting || _swipeState != SwipeState.dragging) return;

    final velocity = details.velocity.pixelsPerSecond;

    // 如果已经检测到方向，检查速度是否达到删除条件
    if (_detectedDirection != null) {
      bool shouldDismiss = false;

      switch (_detectedDirection!) {
        case SwipeDismissDirection.up:
          shouldDismiss = velocity.dy < -_velocityThreshold;
          break;
        case SwipeDismissDirection.left:
          shouldDismiss = velocity.dx < -_velocityThreshold;
          break;
        case SwipeDismissDirection.right:
          shouldDismiss = velocity.dx > _velocityThreshold;
          break;
      }

      if (shouldDismiss) {
        // 触发滑动删除
        _dismiss(direction: _detectedDirection);
        return;
      }
    }

    // 没有达到删除条件，重置状态
    _resetToIdle();
  }

  /// 重置到空闲状态
  void _resetToIdle() {
    setState(() {
      _swipeState = SwipeState.idle;
      _totalDragOffset = Offset.zero;
      _detectedDirection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            // 根据fade动画的值动态调整Material elevation
            // 当opacity接近0时，elevation也接近0，避免阴影残留
            final dynamicElevation = _fadeAnimation.value * 3.0;

            return Transform.translate(
              offset: _slideAnimation.value, // 只使用slideAnimation的值
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Material(
                  color: Colors.transparent,
                  elevation: dynamicElevation, // 动态elevation，与fade动画同步
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    key: widget.messageKey, // 使用传入的messageKey用于高度测量
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(widget.message.type),
                      borderRadius: BorderRadius.circular(12),
                      // 使用柔和的自定义阴影，符合Material 3设计规范
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08 * _fadeAnimation.value), // 阴影透明度也与动画同步
                          blurRadius: 6, // 减少模糊半径
                          spreadRadius: 0, // 不扩散，避免"脏"的效果
                          offset: const Offset(0, 2), // 轻微向下偏移，自然的投影
                        ),
                        // 添加第二层更淡的阴影，增加层次感但不突兀
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04 * _fadeAnimation.value), // 阴影透明度也与动画同步
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIcon(widget.message.type),
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 使用InkWell替代GestureDetector，提供更好的触摸反馈
                        InkWell(
                          onTap: () => _dismiss(),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(8), // 增大触摸区域
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 全局消息显示工具类
class GlobalMsgManager {
  static ProviderContainer? _container;

  /// 设置全局容器
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// 通用消息显示方法
  static void _showMessage(String content, MessageType type, String typeName) {
    try {
      if (_container != null) {
        switch (type) {
          case MessageType.success:
            _container!
                .read(messageManagerProvider.notifier)
                .showSuccess(content);
            Log.i('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.error:
            _container!
                .read(messageManagerProvider.notifier)
                .showError(content);
            Log.e('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.warning:
            _container!
                .read(messageManagerProvider.notifier)
                .showWarning(content);
            Log.w('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
          case MessageType.info:
            _container!
                .read(messageManagerProvider.notifier)
                .showMessage(content, type: type);
            Log.i('GlobalMsgManager: 显示$typeName消息 - $content');
            break;
        }
      } else {
        Log.w('GlobalMsgManager: 容器未设置，无法显示消息');
      }
    } catch (e, stackTrace) {
      Log.e('GlobalMsgManager: 显示消息失败 - $e');
      Log.e('StackTrace: $stackTrace');
    }
  }

  ///
  static void showMessage(String content) {
    _showMessage(content, MessageType.info, '信息');
  }

  /// 显示成功消息
  static void showSuccess(String content) {
    _showMessage(content, MessageType.success, '成功');
  }

  /// 显示错误消息
  static void showError(String content) {
    _showMessage(content, MessageType.error, '错误');
  }

  /// 显示警告消息
  static void showWarn(String content) {
    _showMessage(content, MessageType.warning, '警告');
  }
}

/// 消息管理器的便捷扩展
extension MessageManagerExtension on WidgetRef {
  /// 通用消息显示方法
  void _showMessageWithFallback(
      String content, MessageType type, String typeName) {
    try {
      read(messageManagerProvider.notifier).showMessage(content, type: type);
      // 根据消息类型使用相应的日志级别
      switch (type) {
        case MessageType.success:
          Log.i('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.error:
          Log.e('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.warning:
          Log.w('Extension: 显示$typeName消息 - $content');
          break;
        case MessageType.info:
          Log.i('Extension: 显示$typeName消息 - $content');
          break;
      }
    } catch (e) {
      Log.e('Extension: 显示$typeName消息失败，使用全局方法 - $e');
      // 备用方案：使用全局方法
      switch (type) {
        case MessageType.success:
          GlobalMsgManager.showSuccess(content);
          break;
        case MessageType.error:
          GlobalMsgManager.showError(content);
          break;
        case MessageType.warning:
          GlobalMsgManager.showWarn(content);
          break;
        case MessageType.info:
          GlobalMsgManager.showSuccess(content); // 默认使用成功样式
          break;
      }
    }
  }

  /// 显示消息
  void showMessage(String content, {MessageType type = MessageType.info}) {
    _showMessageWithFallback(content, type, '信息');
  }

  /// 显示成功消息
  void showSuccess(String content) {
    _showMessageWithFallback(content, MessageType.success, '成功');
  }

  /// 显示警告消息
  void showWarning(String content) {
    _showMessageWithFallback(content, MessageType.warning, '警告');
  }

  /// 显示错误消息
  void showError(String content) {
    _showMessageWithFallback(content, MessageType.error, '错误');
  }
}
