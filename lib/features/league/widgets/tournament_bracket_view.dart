import 'dart:math';

import 'package:collection/collection.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/features/player/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _cardWidth = 180.0;
const _cardHeight = 70.0;
const _roundSpacing = 50.0;
const _verticalCardSpacing = 32.0;
const _maxScale = 2.5;

class TournamentBracketView extends ConsumerStatefulWidget {
  final League league;
  final ValueChanged<bool> onFullscreenToggle;

  const TournamentBracketView(
      {super.key, required this.league, required this.onFullscreenToggle});

  @override
  ConsumerState<TournamentBracketView> createState() =>
      _TournamentBracketViewState();
}

class _TournamentBracketViewState extends ConsumerState<TournamentBracketView>
    with AutomaticKeepAliveClientMixin {
  double _minScale = 0.2;
  bool _isFullscreen = false;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerKey = GlobalKey();

  // Cache for calculated positions to avoid recalculation
  Map<String, Offset> _matchPositions = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _matchPositions = _calculateAllMatchPositions(widget.league.matches);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  @override
  void didUpdateWidget(covariant TournamentBracketView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.league != widget.league) {
      _matchPositions = _calculateAllMatchPositions(widget.league.matches);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    super.dispose();
  }

  void _centerView() {
    if (!mounted ||
        _interactiveViewerKey.currentContext == null ||
        _matchPositions.isEmpty) {
      return;
    }

    final RenderBox renderBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final viewSize = renderBox.size;

    final totalWidth = _matchPositions.values
            .map((p) => p.dx)
            .reduce((max, x) => x > max ? x : x) +
        _cardWidth;
    final totalHeight = _matchPositions.values
            .map((p) => p.dy)
            .reduce((max, y) => y > max ? y : max) +
        _cardHeight;

    final scaleX = viewSize.width / (totalWidth + 32);
    final scaleY = viewSize.height / (totalHeight + 32);
    final initialScale = (min(scaleX, scaleY) * 0.9).clamp(0.1, 1.0);

    if (mounted) {
      setState(() {
        _minScale = initialScale;
      });
    }

    final initialX = (viewSize.width - totalWidth * initialScale) / 2;
    final initialY = (viewSize.height - totalHeight * initialScale) / 2;

    final initialMatrix = Matrix4.identity()
      ..translate(initialX > 0 ? initialX : 0, initialY > 0 ? initialY : 0)
      ..scale(initialScale);

    _transformationController.value = initialMatrix;
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
    widget.onFullscreenToggle(_isFullscreen);
  }

  Map<String, Offset> _calculateAllMatchPositions(List<Match> allMatches) {
    final positions = <String, Offset>{};
    if (allMatches.isEmpty) return positions;

    // Separate matches by bracket
    // 关键修复：将 bracketType == null (普通淘汰赛) 的比赛也视作胜者组进行布局
    final winnerMatches = allMatches
        .where(
            (m) => m.bracketType == BracketType.winner || m.bracketType == null)
        .toList();
    final loserMatches =
        allMatches.where((m) => m.bracketType == BracketType.loser).toList();
    final finalMatches =
        allMatches.where((m) => m.bracketType == BracketType.finals).toList();

    final groupedWinner = groupBy(winnerMatches, (m) => m.round);
    final sortedWinnerRounds = groupedWinner.keys.toList()..sort();

    final groupedLoser = groupBy(loserMatches, (m) => m.round);
    final sortedLoserRounds = groupedLoser.keys.toList()..sort();

    // 1. Position Winner Bracket
    double winnerMaxY = 0;
    final Map<int, List<Offset>> winnerConnectorPoints = {};

    for (int i = 0; i < sortedWinnerRounds.length; i++) {
      final round = sortedWinnerRounds[i];
      final matchesInRound = groupedWinner[round]!;
      matchesInRound.sort((a, b) => a.mid.compareTo(b.mid));
      final double x = i * (_cardWidth + _roundSpacing);

      if (i == 0) {
        for (int j = 0; j < matchesInRound.length; j++) {
          final match = matchesInRound[j];
          final double y = j * (_cardHeight + _verticalCardSpacing);
          positions[match.mid] = Offset(x, y);
          if (y > winnerMaxY) winnerMaxY = y;
        }
      } else {
        final previousConnectors = winnerConnectorPoints[round - 1] ?? [];
        for (int j = 0; j < matchesInRound.length; j++) {
          if (j >= previousConnectors.length) continue;
          final match = matchesInRound[j];
          final double y = previousConnectors[j].dy - (_cardHeight / 2);
          positions[match.mid] = Offset(x, y);
          if (y > winnerMaxY) winnerMaxY = y;
        }
      }
      winnerConnectorPoints[round] =
          _calculateNextConnectorPoints(matchesInRound, positions, x);
    }

    // 2. Position Loser Bracket
    double loserMaxY = 0;
    final Map<int, List<Offset>> loserConnectorPoints = {};
    final double loserYOffset = winnerMaxY + _cardHeight + 100;

    for (int i = 0; i < sortedLoserRounds.length; i++) {
      final round = sortedLoserRounds[i];
      final matchesInRound = groupedLoser[round]!;
      matchesInRound.sort((a, b) => a.mid.compareTo(b.mid));

      // Align loser bracket rounds with winner bracket rounds
      final wbRoundIndex = (round / 2).floor();
      final double x = wbRoundIndex * (_cardWidth + _roundSpacing);

      if (i == 0) {
        for (int j = 0; j < matchesInRound.length; j++) {
          final match = matchesInRound[j];
          final double y =
              j * (_cardHeight + _verticalCardSpacing) + loserYOffset;
          positions[match.mid] = Offset(x, y);
          if (y > loserMaxY) loserMaxY = y;
        }
      } else {
        final previousConnectors = loserConnectorPoints[round - 1] ?? [];
        for (int j = 0; j < matchesInRound.length; j++) {
          if (j >= previousConnectors.length) continue;
          final match = matchesInRound[j];
          final double y = previousConnectors[j].dy - (_cardHeight / 2);
          positions[match.mid] = Offset(x, y);
          if (y > loserMaxY) loserMaxY = y;
        }
      }
      loserConnectorPoints[round] = _calculateNextConnectorPoints(
          matchesInRound, positions, x,
          round: round);
    }

    // 3. Position Final Bracket
    if (finalMatches.isNotEmpty) {
      final wbFinal = winnerMatches.last;
      final lbFinal = loserMatches.last;
      final wbFinalPos = positions[wbFinal.mid];
      final lbFinalPos = positions[lbFinal.mid];

      if (wbFinalPos != null && lbFinalPos != null) {
        final double x =
            (sortedWinnerRounds.length) * (_cardWidth + _roundSpacing);
        final double y = (wbFinalPos.dy + lbFinalPos.dy) / 2;
        positions[finalMatches.first.mid] = Offset(x, y);

        // Position for potential bracket reset match
        if (finalMatches.length > 1) {
          positions[finalMatches.last.mid] =
              Offset(x + _cardWidth + _roundSpacing, y);
        }
      }
    }

    return positions;
  }

  List<Offset> _calculateNextConnectorPoints(
      List<Match> matchesInRound, Map<String, Offset> positions, double x,
      {int round = 0}) {
    final List<Offset> nextConnectors = [];
    final isPaired = round == 0 || round % 2 != 0; // WB or LB odd rounds

    for (int j = 0; j < matchesInRound.length; j += (isPaired ? 2 : 1)) {
      final topMatch = matchesInRound[j];
      final bottomMatch = (isPaired && j + 1 < matchesInRound.length)
          ? matchesInRound[j + 1]
          : null;

      final topMatchPos = positions[topMatch.mid];
      if (topMatchPos == null) continue;

      final topWinnerOffset = _getWinnerYOffset(topMatch, positions);

      if (bottomMatch != null) {
        final bottomMatchPos = positions[bottomMatch.mid];
        if (bottomMatchPos == null) continue;
        final bottomWinnerOffset = _getWinnerYOffset(bottomMatch, positions);
        final midY = (topWinnerOffset + bottomWinnerOffset) / 2;
        nextConnectors.add(Offset(x + _cardWidth, midY));
      } else {
        nextConnectors.add(Offset(x + _cardWidth, topWinnerOffset));
      }
    }
    return nextConnectors;
  }

  double _getWinnerYOffset(Match match, Map<String, Offset> positions) {
    final pos = positions[match.mid];
    if (pos == null) return 0;
    if (match.status != MatchStatus.completed || match.winnerId == null) {
      return pos.dy + _cardHeight / 2;
    }
    if (match.winnerId == match.player1Id) {
      return pos.dy + _cardHeight * 0.25;
    }
    if (match.winnerId == match.player2Id) {
      return pos.dy + _cardHeight * 0.75;
    }
    return pos.dy + _cardHeight / 2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final playerState = ref.watch(playerProvider).value;
    if (playerState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final allMatches = widget.league.matches;
    if (allMatches.isEmpty || _matchPositions.isEmpty) {
      return const Center(child: Text('没有比赛信息可供显示'));
    }

    final totalWidth = _matchPositions.values
            .map((p) => p.dx)
            .reduce((max, x) => x > max ? x : x) +
        _cardWidth;
    final totalHeight = _matchPositions.values
            .map((p) => p.dy)
            .reduce((max, y) => y > max ? y : max) +
        _cardHeight;

    return Stack(
      children: [
        InteractiveViewer(
          key: _interactiveViewerKey,
          transformationController: _transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(totalWidth, totalHeight),
                    painter: _BracketLinePainter(
                      league: widget.league,
                      matchPositions: _matchPositions,
                      lineColor: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  ...allMatches.map((match) {
                    final position = _matchPositions[match.mid];
                    if (position == null) return const SizedBox.shrink();
                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: _MatchCard(
                          match: match, players: playerState.players),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'center_view',
                onPressed: _centerView,
                tooltip: '回到中心',
                child: const Icon(Icons.filter_center_focus),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'fullscreen_toggle',
                onPressed: _toggleFullscreen,
                tooltip: _isFullscreen ? '退出全屏' : '全屏',
                child: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final List<PlayerInfo> players;

  const _MatchCard({required this.match, required this.players});

  PlayerInfo _getPlayer(String? pid) {
    if (pid == null || pid == 'bye') {
      return PlayerInfo(name: '[轮空]', avatar: '');
    }
    return players.firstWhere((p) => p.pid == pid,
        orElse: () => PlayerInfo(name: 'TBD', avatar: ''));
  }

  @override
  Widget build(BuildContext context) {
    final player1 = _getPlayer(match.player1Id);
    final player2 = _getPlayer(match.player2Id);

    final p1Score = match.player1Score?.toString() ?? '-';
    final p2Score = (match.player2Id == 'bye')
        ? '-'
        : (match.player2Score?.toString() ?? '-');

    final p1Color = match.winnerId == match.player1Id
        ? Colors.green.shade700
        : (match.status == MatchStatus.completed && player2.pid != '轮空'
            ? Colors.red.shade300.withOpacity(0.4)
            : null);
    final p2Color = match.winnerId == match.player2Id
        ? Colors.green.shade700
        : (match.status == MatchStatus.completed && player1.pid != '轮空'
            ? Colors.red.shade300.withOpacity(0.4)
            : null);

    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(178),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(128)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PlayerRow(
            name: player1.name,
            score: p1Score,
            color: p1Color,
            isWinner: match.winnerId == match.player1Id,
          ),
          const Divider(height: 1, thickness: 1),
          _PlayerRow(
            name: player2.name,
            score: p2Score,
            color: p2Color,
            isWinner: match.winnerId == match.player2Id,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String name;
  final String score;
  final Color? color;
  final bool isWinner;

  const _PlayerRow(
      {required this.name,
      required this.score,
      this.color,
      this.isWinner = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isWinner)
          Transform.rotate(
            angle: -0.25,
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber.withOpacity(0.2),
              size: 32,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      color: color,
                      fontWeight: color != null ? FontWeight.bold : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                score,
                style: TextStyle(
                    color: color,
                    fontWeight: color != null ? FontWeight.bold : null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BracketLinePainter extends CustomPainter {
  final League league;
  final Map<String, Offset> matchPositions;
  final Color lineColor;

  _BracketLinePainter({required this.league,
      required this.matchPositions,
      required this.lineColor});

  double _getWinnerYOffset(Match match) {
    final pos = matchPositions[match.mid];
    if (pos == null) return 0;
    if (match.status != MatchStatus.completed || match.winnerId == null) {
      return pos.dy + _cardHeight / 2;
    }
    if (match.winnerId == match.player1Id) {
      return pos.dy + _cardHeight * 0.25;
    }
    if (match.winnerId == match.player2Id) {
      return pos.dy + _cardHeight * 0.75;
    }
    return pos.dy + _cardHeight / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    final matchesById = {for (var m in league.matches) m.mid: m};

    // A simplified drawing logic based on rounds, as we can't build a true graph
    final groupedMatches = groupBy(league.matches, (m) => m.bracketType);

    // 关键修复：将 bracketType == null (普通淘汰赛) 的比赛也视作胜者组进行绘制
    final List<Match> winnerMatches = [
      ...(groupedMatches[BracketType.winner] ?? []),
      ...(groupedMatches[null] ?? []),
    ];

    _drawConnectorsForBracket(canvas, paint, winnerMatches, matchesById);
    _drawConnectorsForBracket(
        canvas, paint, groupedMatches[BracketType.loser] ?? [], matchesById,
        isLoserBracket: true);
    _drawFinalsConnector(canvas, paint, groupedMatches, matchesById);
  }

  void _drawConnectorsForBracket(Canvas canvas, Paint paint,
      List<Match> bracketMatches, Map<String, Match> allMatches,
      {bool isLoserBracket = false}) {
    final grouped = groupBy(bracketMatches, (m) => m.round);
    final sortedRounds = grouped.keys.toList()..sort();

    for (int i = 0; i < sortedRounds.length - 1; i++) {
      final round = sortedRounds[i];
      final nextRound = sortedRounds[i + 1];
      final matchesInRound = grouped[round]!;
      final matchesInNextRound = grouped[nextRound]!;

      final isPaired = !isLoserBracket || round % 2 != 0;

      if (isPaired) {
        for (int j = 0; j < matchesInRound.length; j += 2) {
          final topMatch = matchesInRound[j];
          final bottomMatch =
              (j + 1 < matchesInRound.length) ? matchesInRound[j + 1] : null;
          final targetMatch = matchesInNextRound.length > (j / 2).floor()
              ? matchesInNextRound[(j / 2).floor()]
              : null;
          if (targetMatch == null) continue;

          _drawConnector(canvas, paint, topMatch, bottomMatch, targetMatch);
        }
      } else {
        // Loser bracket even rounds, one-to-one connection + one from winner bracket
        for (int j = 0; j < matchesInRound.length; j++) {
          final sourceMatch = matchesInRound[j];
          // This is where it gets tricky. We need to know which WB match drops down.
          // This info is not in the data model. We can only assume a one-to-one connection for now.
          final targetMatch =
              matchesInNextRound.length > j ? matchesInNextRound[j] : null;
          if (targetMatch == null) continue;
          _drawConnector(canvas, paint, sourceMatch, null, targetMatch);
        }
      }
    }
  }

  void _drawFinalsConnector(
      Canvas canvas,
      Paint paint,
      Map<BracketType?, List<Match>> groupedMatches,
      Map<String, Match> allMatches) {
    final winnerFinal = (groupedMatches[BracketType.winner] ?? []).lastOrNull;
    final loserFinal = (groupedMatches[BracketType.loser] ?? []).lastOrNull;
    final grandFinal = (groupedMatches[BracketType.finals] ?? []).firstOrNull;

    if (winnerFinal != null && loserFinal != null && grandFinal != null) {
      _drawConnector(canvas, paint, winnerFinal, loserFinal, grandFinal);
    }

    // Connector for bracket reset
    final bracketResetMatch =
        (groupedMatches[BracketType.finals] ?? []).length > 1
            ? (groupedMatches[BracketType.finals] ?? [])[1]
            : null;
    if (grandFinal != null && bracketResetMatch != null) {
      _drawConnector(canvas, paint, grandFinal, null, bracketResetMatch);
    }
  }

  void _drawConnector(
      Canvas canvas, Paint paint, Match? top, Match? bottom, Match target) {
    final targetPos = matchPositions[target.mid];
    if (targetPos == null) return;
    final targetY = targetPos.dy + _cardHeight / 2;
    final targetX = targetPos.dx;

    if (top != null && bottom != null) {
      final topPos = matchPositions[top.mid];
      if (topPos == null) return;
      final bottomPos = matchPositions[bottom.mid];
      if (bottomPos == null) return;

      final topWinnerY = _getWinnerYOffset(top);
      final bottomWinnerY = _getWinnerYOffset(bottom);
      final startX = topPos.dx + _cardWidth;
      final midX = startX + _roundSpacing / 2;

      canvas.drawLine(
          Offset(startX, topWinnerY), Offset(midX, topWinnerY), paint);
      canvas.drawLine(
          Offset(startX, bottomWinnerY), Offset(midX, bottomWinnerY), paint);
      canvas.drawLine(
          Offset(midX, topWinnerY), Offset(midX, bottomWinnerY), paint);
      canvas.drawLine(Offset(midX, targetY), Offset(targetX, targetY), paint);
    } else if (top != null) {
      final topPos = matchPositions[top.mid];
      if (topPos == null) return;
      final topWinnerY = _getWinnerYOffset(top);
      final startX = topPos.dx + _cardWidth;
      final midX = startX + _roundSpacing / 2;

      canvas.drawLine(
          Offset(startX, topWinnerY), Offset(midX, topWinnerY), paint);
      canvas.drawLine(Offset(midX, topWinnerY), Offset(midX, targetY), paint);
      canvas.drawLine(Offset(midX, targetY), Offset(targetX, targetY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
