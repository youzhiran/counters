import 'package:flutter/material.dart';

/// 自定义页面转换动画集合
class CustomPageTransitions {
  /// 获取优化的动画时长（基于设备性能）
  static Duration _getOptimizedDuration(Duration baseDuration) {
    // 简化的性能检测
    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final isLowEndDevice = devicePixelRatio < 2.0;

    if (isLowEndDevice) {
      return Duration(
          milliseconds: (baseDuration.inMilliseconds * 0.7).round());
    }
    return baseDuration;
  }

  /// 滑动转换动画 - 从右到左（性能优化版）
  static Route<T> slideFromRight<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250), // 减少默认时长
    Curve curve = Curves.easeInOut,
  }) {
    final optimizedDuration = _getOptimizedDuration(duration);

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        // 添加安全包装，确保页面在布局完成后再显示
        return RepaintBoundary(
          child: Builder(
            builder: (context) {
              // 使用 LayoutBuilder 确保页面有正确的约束
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
                    return page;
                  } else {
                    // 如果约束无效，显示占位符
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              );
            },
          ),
        );
      },
      transitionDuration: optimizedDuration,
      reverseTransitionDuration: optimizedDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return RepaintBoundary(
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// 滑动转换动画 - 从左到右（性能优化版）
  static Route<T> slideFromLeft<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    final optimizedDuration = _getOptimizedDuration(duration);

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          RepaintBoundary(child: page),
      transitionDuration: optimizedDuration,
      reverseTransitionDuration: optimizedDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return RepaintBoundary(
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// 滑动转换动画 - 从下到上
  static Route<T> slideFromBottom<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// 滑动转换动画 - 从上到下
  static Route<T> slideFromTop<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// 淡入淡出转换动画
  static Route<T> fadeTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: curve)),
          child: child,
        );
      },
    );
  }

  /// 缩放转换动画
  static Route<T> scaleTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(CurveTween(curve: curve)),
          child: child,
        );
      },
    );
  }

  /// 组合动画 - 滑动 + 淡入淡出
  static Route<T> slideAndFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;
        final slideTween = Tween(begin: begin, end: end);
        final slideAnimation = animation.drive(slideTween.chain(
          CurveTween(curve: curve),
        ));

        final fadeAnimation = animation.drive(CurveTween(curve: curve));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// 旋转转换动画
  static Route<T> rotationTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: animation.drive(CurveTween(curve: curve)),
          child: child,
        );
      },
    );
  }
}

/// 扩展Navigator类，添加便捷的动画导航方法
extension NavigatorExtensions on NavigatorState {
  /// 使用滑动动画推送页面
  Future<T?> pushWithSlide<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    Route<T> route;
    switch (direction) {
      case SlideDirection.fromRight:
        route = CustomPageTransitions.slideFromRight<T>(page,
            duration: duration, curve: curve);
        break;
      case SlideDirection.fromLeft:
        route = CustomPageTransitions.slideFromLeft<T>(page,
            duration: duration, curve: curve);
        break;
      case SlideDirection.fromBottom:
        route = CustomPageTransitions.slideFromBottom<T>(page,
            duration: duration, curve: curve);
        break;
      case SlideDirection.fromTop:
        route = CustomPageTransitions.slideFromTop<T>(page,
            duration: duration, curve: curve);
        break;
    }
    return push(route);
  }

  /// 使用淡入淡出动画推送页面
  Future<T?> pushWithFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return push(CustomPageTransitions.fadeTransition<T>(page,
        duration: duration, curve: curve));
  }

  /// 使用缩放动画推送页面
  Future<T?> pushWithScale<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return push(CustomPageTransitions.scaleTransition<T>(page,
        duration: duration, curve: curve));
  }

  /// 使用组合动画推送页面
  Future<T?> pushWithSlideAndFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return push(CustomPageTransitions.slideAndFade<T>(page,
        duration: duration, curve: curve, begin: begin));
  }
}

/// 滑动方向枚举
enum SlideDirection {
  fromRight,
  fromLeft,
  fromBottom,
  fromTop,
}
