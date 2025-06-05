import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 性能优化的列表组件
///
/// 提供了多种优化策略：
/// 1. 自动RepaintBoundary包装
/// 2. 智能缓存
/// 3. 延迟加载
/// 4. 内存优化
class OptimizedListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  const OptimizedListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView> {
  final Map<int, Widget> _cachedItems = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _cachedItems.clear();
    super.dispose();
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    // 检查缓存
    if (_cachedItems.containsKey(index)) {
      return _cachedItems[index]!;
    }

    // 构建新项目
    Widget item = widget.itemBuilder(context, index);

    // 添加RepaintBoundary优化
    if (widget.addRepaintBoundaries) {
      item = RepaintBoundary(child: item);
    }

    // 缓存项目（限制缓存大小）
    if (_cachedItems.length < 50) {
      _cachedItems[index] = item;
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount,
      itemBuilder: _buildOptimizedItem,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: false,
      // 我们手动管理RepaintBoundary
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
    );
  }
}

/// 性能优化的网格组件
class OptimizedGridView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  const OptimizedGridView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  State<OptimizedGridView> createState() => _OptimizedGridViewState();
}

class _OptimizedGridViewState extends State<OptimizedGridView> {
  final Map<int, Widget> _cachedItems = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _cachedItems.clear();
    super.dispose();
  }

  Widget _buildOptimizedItem(BuildContext context, int index) {
    // 检查缓存
    if (_cachedItems.containsKey(index)) {
      return _cachedItems[index]!;
    }

    // 构建新项目
    Widget item = widget.itemBuilder(context, index);

    // 添加RepaintBoundary优化
    if (widget.addRepaintBoundaries) {
      item = RepaintBoundary(child: item);
    }

    // 缓存项目（限制缓存大小）
    if (_cachedItems.length < 50) {
      _cachedItems[index] = item;
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount,
      itemBuilder: _buildOptimizedItem,
      gridDelegate: widget.gridDelegate,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: false,
      // 我们手动管理RepaintBoundary
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
    );
  }
}

/// 智能列表项包装器
/// 自动添加性能优化
class SmartListItem extends StatelessWidget {
  final Widget child;
  final bool enableRepaintBoundary;
  final bool enableKeepAlive;
  final String? debugLabel;

  const SmartListItem({
    super.key,
    required this.child,
    this.enableRepaintBoundary = true,
    this.enableKeepAlive = false,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // 添加RepaintBoundary
    if (enableRepaintBoundary) {
      result = RepaintBoundary(child: result);
    }

    // 添加AutomaticKeepAlive
    if (enableKeepAlive) {
      result = AutomaticKeepAlive(
        child: result,
      );
    }

    // 在调试模式下添加性能监控
    if (kDebugMode && debugLabel != null) {
      result = _PerformanceWrapper(
        label: debugLabel!,
        child: result,
      );
    }

    return result;
  }
}

/// 性能监控包装器（仅调试模式）
class _PerformanceWrapper extends StatefulWidget {
  final String label;
  final Widget child;

  const _PerformanceWrapper({
    required this.label,
    required this.child,
  });

  @override
  State<_PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<_PerformanceWrapper> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildCount++;
      final now = DateTime.now();

      if (_lastBuildTime != null) {
        final timeSinceLastBuild = now.difference(_lastBuildTime!);
        if (timeSinceLastBuild.inMilliseconds < 16) {
          debugPrint(
              'Performance Warning: ${widget.label} rebuilt too frequently '
              '(${timeSinceLastBuild.inMilliseconds}ms since last build)');
        }
      }

      _lastBuildTime = now;

      if (_buildCount % 10 == 0) {
        debugPrint('${widget.label} has been built $_buildCount times');
      }
    }

    return widget.child;
  }
}

/// 延迟加载列表
/// 适用于大量数据的场景
class LazyLoadingListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataLoader;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final int pageSize;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const LazyLoadingListView({
    super.key,
    required this.dataLoader,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.pageSize = 20,
    this.padding,
    this.controller,
  });

  @override
  State<LazyLoadingListView<T>> createState() => _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  Object? _error;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.dataLoader(_currentPage, widget.pageSize);

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return RepaintBoundary(
            child: widget.itemBuilder(context, _items[index], index),
          );
        } else {
          // 加载指示器
          if (_error != null) {
            return widget.errorBuilder?.call(context, _error!) ??
                Center(
                  child: Column(
                    children: [
                      Text('加载失败: $_error'),
                      ElevatedButton(
                        onPressed: _loadNextPage,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
          }

          return widget.loadingBuilder?.call(context) ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
        }
      },
    );
  }
}
