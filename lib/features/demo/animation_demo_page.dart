import 'package:counters/common/widgets/page_transitions.dart';
import 'package:flutter/material.dart';

class AnimationDemoPage extends StatelessWidget {
  const AnimationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面动画演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '点击按钮体验不同的页面切换动画效果',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildAnimationButton(
                    context,
                    '从右滑入',
                    Colors.blue,
                    () => _navigateWithAnimation(
                      context,
                      SlideDirection.fromRight,
                      '从右滑入动画',
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '从左滑入',
                    Colors.green,
                    () => _navigateWithAnimation(
                      context,
                      SlideDirection.fromLeft,
                      '从左滑入动画',
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '从下滑入',
                    Colors.orange,
                    () => _navigateWithAnimation(
                      context,
                      SlideDirection.fromBottom,
                      '从下滑入动画',
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '从上滑入',
                    Colors.purple,
                    () => _navigateWithAnimation(
                      context,
                      SlideDirection.fromTop,
                      '从上滑入动画',
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '淡入淡出',
                    Colors.teal,
                    () => Navigator.of(context).pushWithFade(
                      _buildDemoPage('淡入淡出动画', Colors.teal),
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '缩放动画',
                    Colors.red,
                    () => Navigator.of(context).pushWithScale(
                      _buildDemoPage('缩放动画', Colors.red),
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '滑动+淡入',
                    Colors.indigo,
                    () => Navigator.of(context).pushWithSlideAndFade(
                      _buildDemoPage('滑动+淡入动画', Colors.indigo),
                      begin: const Offset(1.0, 0.0),
                    ),
                  ),
                  _buildAnimationButton(
                    context,
                    '旋转动画',
                    Colors.brown,
                    () => Navigator.of(context).push(
                      CustomPageTransitions.rotationTransition(
                        _buildDemoPage('旋转动画', Colors.brown),
                        duration: const Duration(milliseconds: 600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '动画参数说明：',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 动画时长：300-600毫秒'),
                    const Text('• 缓动曲线：easeInOut'),
                    const Text('• 支持自定义方向和参数'),
                    const Text('• 可组合多种动画效果'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationButton(
    BuildContext context,
    String title,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _navigateWithAnimation(
    BuildContext context,
    SlideDirection direction,
    String title,
  ) {
    Color color;
    switch (direction) {
      case SlideDirection.fromRight:
        color = Colors.blue;
        break;
      case SlideDirection.fromLeft:
        color = Colors.green;
        break;
      case SlideDirection.fromBottom:
        color = Colors.orange;
        break;
      case SlideDirection.fromTop:
        color = Colors.purple;
        break;
    }

    Navigator.of(context).pushWithSlide(
      _buildDemoPage(title, color),
      direction: direction,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildDemoPage(String title, Color color) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.animation,
                size: 80,
                color: color,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '这是一个演示页面\n展示了 $title 效果',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('返回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
