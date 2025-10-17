import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:counters/common/utils/error_handler.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/lan/resources/score_http_templates.dart';
import 'package:counters/features/score/score_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 提供 ScoreState 的函数签名
typedef ScoreStateSupplier = AsyncValue<ScoreState> Function();

/// 局域网实时计分 HTTP 服务，用于在浏览器中查看比分
class ScoreHttpServer {
  final ScoreStateSupplier _scoreStateSupplier;
  final int _port;
  final String _templateAssetPath;
  final String _qrAssetPath;
  HttpServer? _server;
  String? _cachedTemplate;
  String? _cachedQrSvg;

  ScoreHttpServer({
    required ScoreStateSupplier scoreStateSupplier,
    required int port,
    String templateAssetPath = ScoreHttpTemplates.defaultTemplateAsset,
    String qrAssetPath = ScoreHttpTemplates.downloadQrAsset,
  })  : _scoreStateSupplier = scoreStateSupplier,
        _port = port,
        _templateAssetPath = templateAssetPath,
        _qrAssetPath = qrAssetPath;

  /// 判断服务是否已经启动
  bool get isRunning => _server != null;

  /// 启动 HTTP 服务
  Future<void> start() async {
    if (isRunning) {
      Log.w('HTTP计分服务已在运行，无需重复启动');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      Log.i('HTTP计分服务已启动: http://${_server!.address.address}:$_port');

      _server!.listen(
        _handleRequest,
        onError: (error, stackTrace) {
          ErrorHandler.handle(error, stackTrace, prefix: 'HTTP计分服务请求处理失败');
        },
        cancelOnError: false,
      );
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '启动HTTP计分服务失败');
      rethrow;
    }
  }

  /// 停止 HTTP 服务
  Future<void> stop() async {
    if (!isRunning) {
      return;
    }
    try {
      await _server?.close(force: true);
      Log.i('HTTP计分服务已停止');
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '停止HTTP计分服务失败');
    } finally {
      _server = null;
    }
  }

  /// 统一处理进入的 HTTP 请求
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // 简单处理 CORS
      _writeCorsHeaders(request.response);

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }

      final path = request.uri.path;
      if (path == '/' || path == '/index.html') {
        await _serveHtml(request);
      } else if (path == '/api/score') {
        await _serveScoreJson(request);
      } else if (path == '/assets/qr-download.svg') {
        await _serveQrSvg(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('未找到资源');
        await request.response.close();
      }
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: 'HTTP计分服务内部错误');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('服务器内部错误');
      } catch (_) {}
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  /// 返回实时计分页面
  Future<void> _serveHtml(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType =
        ContentType('text', 'html', charset: 'utf-8');
    final html = await _getScoreboardHtml();
    response.write(html);
    await response.close();
  }

  Future<void> _serveQrSvg(HttpRequest request) async {
    try {
      final response = request.response;
      response.headers.contentType =
          ContentType('image', 'svg+xml', charset: 'utf-8');
      final svg = await _getQrSvg();
      response.write(svg);
      await response.close();
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '加载HTTP二维码资源失败');
      try {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('资源未找到');
        await request.response.close();
      } catch (_) {}
    }
  }

  /// 返回JSON格式的比分数据
  Future<void> _serveScoreJson(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType =
        ContentType('application', 'json', charset: 'utf-8');

    final payload = _buildScorePayload();
    response.write(jsonEncode(payload));
    await response.close();
  }

  Future<String> _getQrSvg() async {
    if (_cachedQrSvg != null) {
      return _cachedQrSvg!;
    }

    try {
      final svgString = await rootBundle.loadString(_qrAssetPath);
      _cachedQrSvg = svgString;
      return svgString;
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '加载二维码资源失败');
      rethrow;
    }
  }

  /// 加载模板 HTML 内容（带缓存）
  Future<String> _getScoreboardHtml() async {
    if (_cachedTemplate != null) {
      return _cachedTemplate!;
    }

    try {
      final template = await rootBundle.loadString(_templateAssetPath);
      _cachedTemplate = template;
      return template;
    } catch (e, s) {
      ErrorHandler.handle(e, s, prefix: '加载HTTP计分模板失败');
      _cachedTemplate = ScoreHttpTemplates.fallbackHtml;
      return _cachedTemplate!;
    }
  }

  /// 构建比分数据的JSON结构
  Map<String, dynamic> _buildScorePayload() {
    final asyncScoreState = _scoreStateSupplier();

    if (asyncScoreState.isLoading) {
      return {
        'status': 'loading',
        'message': '计分数据加载中，请稍候...',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    if (asyncScoreState.hasError) {
      return {
        'status': 'error',
        'message': '获取计分数据时出错：${asyncScoreState.error}',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    final scoreState = asyncScoreState.valueOrNull;
    if (scoreState == null) {
      return {
        'status': 'empty',
        'message': '暂无计分数据',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    final session = scoreState.currentSession;
    final players = scoreState.players;
    final templateName = scoreState.template?.templateName ?? '未选择模板';

    final preparedPlayers = players.map((player) {
      final sessionScore = session?.scores
          .firstWhereOrNull((item) => item.playerId == player.pid);
      final roundScores =
          List<int?>.from(sessionScore?.roundScores ?? const <int?>[]);
      final totalScore = sessionScore?.totalScore ?? 0;

      return {
        'playerId': player.pid,
        'name': player.name,
        'totalScore': totalScore,
        'roundScores': roundScores,
      };
    }).toList();

    // 若没有玩家信息，返回提示
    if (preparedPlayers.isEmpty) {
      return {
        'status': 'no_player',
        'message': '当前模板未配置玩家，请在主机端添加玩家后重试',
        'meta': {
          'templateName': templateName,
        },
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }

    final roundCount = preparedPlayers.fold<int>(
        0,
        (previousValue, element) =>
            math.max(previousValue, (element['roundScores'] as List).length));

    final sortedPlayers = List<Map<String, dynamic>>.from(preparedPlayers)
      ..sort(
          (a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));

    int currentRank = 0;
    int? previousScore;
    for (var i = 0; i < sortedPlayers.length; i++) {
      final score = sortedPlayers[i]['totalScore'] as int;
      if (previousScore == null || score != previousScore) {
        currentRank = i + 1;
        previousScore = score;
      }
      sortedPlayers[i]['rank'] = currentRank;
    }

    return {
      'status': 'ok',
      'meta': {
        'templateName': templateName,
        'currentRound': scoreState.currentRound,
        'roundCount': roundCount,
        'isCompleted': session?.isCompleted ?? false,
        'sessionId': session?.sid,
      },
      'players': sortedPlayers,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 写入通用的CORS响应头
  void _writeCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  }
}
