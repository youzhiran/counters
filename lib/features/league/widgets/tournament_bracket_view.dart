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
const _verticalCardSpacing = 32.0; // Spacing between cards in the same round
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
  double _minScale = 0.2; // Default value, will be updated dynamically.
  bool _isFullscreen = false;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 保证在第一帧渲染完成后，只执行一次居中操作
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  @override
  void dispose() {
    // Ensure we exit fullscreen when the widget is disposed.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    super.dispose();
  }

  void _centerView() {
    if (!mounted || _interactiveViewerKey.currentContext == null) return;

    final RenderBox renderBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final viewSize = renderBox.size;

    final groupedMatches =
        groupBy<Match, int>(widget.league.matches, (match) => match.round);
    final sortedRounds = groupedMatches.keys.toList()..sort();
    if (sortedRounds.isEmpty) return;

    final matchPositions =
        _calculateMatchPositions(groupedMatches, sortedRounds);
    if (matchPositions.isEmpty) return;

    final totalWidth = sortedRounds.length * _cardWidth +
        (sortedRounds.length - 1) * _roundSpacing;
    final totalHeight = matchPositions.values
            .map((p) => p.dy)
            .reduce((max, y) => y > max ? y : max) +
        _cardHeight;

    final scaleX = viewSize.width / (totalWidth + 32);
    final scaleY = viewSize.height / (totalHeight + 32);
    final initialScale = (min(scaleX, scaleY) * 0.8).clamp(0.1, 1.0);

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final playerState = ref.watch(playerProvider).value;
    if (playerState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedMatches =
        groupBy<Match, int>(widget.league.matches, (match) => match.round);
    final sortedRounds = groupedMatches.keys.toList()..sort();

    final matchPositions =
        _calculateMatchPositions(groupedMatches, sortedRounds);

    if (matchPositions.isEmpty) {
      return const Center(child: Text('没有比赛信息可供显示'));
    }

    final totalWidth = sortedRounds.length * _cardWidth +
        (sortedRounds.length - 1) * _roundSpacing;
    final totalHeight = matchPositions.values
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
                children: _buildBracketWidgets(context, groupedMatches,
                    sortedRounds, playerState.players, matchPositions),
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

  Map<String, Offset> _calculateMatchPositions(
      Map<int, List<Match>> groupedMatches, List<int> sortedRounds) {
    final Map<String, Offset> positions = {};
    final Map<int, List<Offset>> roundConnectorPoints = {};

    for (int i = 0; i < sortedRounds.length; i++) {
      final round = sortedRounds[i];
      final matchesInRound = groupedMatches[round]!;
      // 关键改动：根据 mid 对当前轮次的比赛进行排序，确保布局稳定性
      matchesInRound.sort((a, b) => a.mid.compareTo(b.mid));
      final double x = i * (_cardWidth + _roundSpacing);

      if (i == 0) {
        // First round positions are fixed
        for (int j = 0; j < matchesInRound.length; j++) {
          final match = matchesInRound[j];
          final double y = j * (_cardHeight + _verticalCardSpacing);
          positions[match.mid] = Offset(x, y);
        }
      } else {
        // Subsequent rounds are positioned based on the previous round's connectors
        final previousConnectors = roundConnectorPoints[round - 1] ?? [];
        for (int j = 0; j < matchesInRound.length; j++) {
          if (j >= previousConnectors.length) continue; // Avoid range errors
          final match = matchesInRound[j];
          // Align the center of the card with the incoming connector line
          final double y = previousConnectors[j].dy - (_cardHeight / 2);
          positions[match.mid] = Offset(x, y);
        }
      }

      // Calculate connector points for the *next* round
      final List<Offset> nextConnectors = [];
      for (int j = 0; j < matchesInRound.length; j += 2) {
        final topMatch = matchesInRound[j];
        final bottomMatch =
            (j + 1 < matchesInRound.length) ? matchesInRound[j + 1] : null;

        final topMatchPos = positions[topMatch.mid];
        if (topMatchPos == null) continue;

        final topWinnerOffset = _getWinnerOffset(topMatch);

        if (bottomMatch != null) {
          final bottomMatchPos = positions[bottomMatch.mid];
          if (bottomMatchPos == null) continue;

          final bottomWinnerOffset = _getWinnerOffset(bottomMatch);
          final midY = (topMatchPos.dy +
                  topWinnerOffset +
                  bottomMatchPos.dy +
                  bottomWinnerOffset) /
              2;
          nextConnectors.add(Offset(x + _cardWidth, midY));
        } else {
          nextConnectors
              .add(Offset(x + _cardWidth, topMatchPos.dy + topWinnerOffset));
        }
      }
      roundConnectorPoints[round] = nextConnectors;
    }
    return positions;
  }

  List<Widget> _buildBracketWidgets(
    BuildContext context,
    Map<int, List<Match>> groupedMatches,
    List<int> sortedRounds,
    List<PlayerInfo> players,
    Map<String, Offset> matchPositions,
  ) {
    final List<Widget> widgets = [];

    for (int i = 0; i < sortedRounds.length; i++) {
      final round = sortedRounds[i];
      final matchesInRound = groupedMatches[round]!;

      // Add connectors first so they are drawn behind the cards
      if (i < sortedRounds.length - 1) {
        widgets.add(
          _RoundConnector(
            matches: matchesInRound,
            matchPositions: matchPositions,
          ),
        );
      }

      // Add match cards
      for (final match in matchesInRound) {
        final position = matchPositions[match.mid];
        if (position == null) continue;
        widgets.add(
          Positioned(
            left: position.dx,
            top: position.dy,
            child: _MatchCard(match: match, players: players),
          ),
        );
      }
    }
    return widgets;
  }

  double _getWinnerOffset(Match match) {
    if (match.status != MatchStatus.completed) return _cardHeight / 2;
    if (match.winnerId == match.player1Id) return _cardHeight * 0.25;
    if (match.winnerId == match.player2Id) return _cardHeight * 0.75;
    return _cardHeight / 2; // Bye or draw
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

class _RoundConnector extends StatelessWidget {
  final List<Match> matches;
  final Map<String, Offset> matchPositions;

  const _RoundConnector({required this.matches, required this.matchPositions});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BracketLinePainter(
        matches: matches,
        matchPositions: matchPositions,
        lineColor: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _BracketLinePainter extends CustomPainter {
  final List<Match> matches;
  final Map<String, Offset> matchPositions;
  final Color lineColor;

  _BracketLinePainter(
      {required this.matches,
      required this.matchPositions,
      required this.lineColor});

  double _getWinnerOffset(Match match) {
    if (match.status != MatchStatus.completed) return _cardHeight / 2;
    if (match.winnerId == match.player1Id) return _cardHeight * 0.25;
    if (match.winnerId == match.player2Id) return _cardHeight * 0.75;
    return _cardHeight / 2; // Bye or draw
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    for (int i = 0; i < matches.length; i += 2) {
      final topMatch = matches[i];
      final bottomMatch = (i + 1 < matches.length) ? matches[i + 1] : null;

      final topMatchPos = matchPositions[topMatch.mid];
      if (topMatchPos == null) continue;

      final topWinnerY = topMatchPos.dy + _getWinnerOffset(topMatch);
      final startX = topMatchPos.dx + _cardWidth;

      // 1. Draw horizontal line from the top card
      canvas.drawLine(Offset(startX, topWinnerY),
          Offset(startX + _roundSpacing / 2, topWinnerY), paint);

      if (bottomMatch != null) {
        final bottomMatchPos = matchPositions[bottomMatch.mid];
        if (bottomMatchPos == null) continue;

        final bottomWinnerY = bottomMatchPos.dy + _getWinnerOffset(bottomMatch);
        final midY = (topWinnerY + bottomWinnerY) / 2;

        // 2. Draw horizontal line from the bottom card
        canvas.drawLine(Offset(startX, bottomWinnerY),
            Offset(startX + _roundSpacing / 2, bottomWinnerY), paint);

        // 3. Draw the vertical line connecting them
        canvas.drawLine(Offset(startX + _roundSpacing / 2, topWinnerY),
            Offset(startX + _roundSpacing / 2, bottomWinnerY), paint);

        // 4. Draw the final horizontal line to the next round's card
        canvas.drawLine(Offset(startX + _roundSpacing / 2, midY),
            Offset(startX + _roundSpacing, midY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
