import 'dart:math';

import 'package:collection/collection.dart';
import 'package:counters/common/model/league.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/utils/log.dart';
import 'package:counters/features/league/model/bracket_models.dart';
import 'package:counters/features/league/services/bracket_generator.dart';
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

  const TournamentBracketView({
    super.key,
    required this.league,
    required this.onFullscreenToggle,
  });

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

  // The new structured bracket data
  TournamentBracket? _bracket;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _generateAndPositionBracket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  @override
  void didUpdateWidget(covariant TournamentBracketView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.league != widget.league) {
      _generateAndPositionBracket();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformationController.dispose();
    super.dispose();
  }

  /// Generates the bracket structure and calculates node positions.
  void _generateAndPositionBracket() {
    final generator = BracketGenerator();
    final bracket = generator.generate(widget.league.matches);
    final players = ref.read(playerProvider).value?.players ?? [];
    _calculateAllMatchPositions(bracket, players);
    setState(() {
      _bracket = bracket;
    });
  }

  /// Final, correct layout algorithm with separate vertical zones for brackets.
  void _calculateAllMatchPositions(
      TournamentBracket bracket, List<PlayerInfo> players) {
    if (bracket.allNodes.isEmpty) return;

    // Helper to get player names for logging
    String getPlayerNames(Match match) {
      final p1 = players.firstWhere((p) => p.pid == match.player1Id,
          orElse: () => PlayerInfo(name: 'TBD', avatar: ''));
      final p2 = players.firstWhere((p) => p.pid == match.player2Id,
          orElse: () => PlayerInfo(name: 'TBD', avatar: ''));
      return '${p1.name} vs ${p2.name}';
    }

    // Helper to format offset for logging
    String formatOffset(Offset offset) {
      return '(${offset.dx.toStringAsFixed(1)}, ${offset.dy.toStringAsFixed(1)})';
    }

    Log.v('开始计算对阵图节点位置 (最终分区布局)...');
    final nodesByDepth = groupBy(bracket.allNodes, (n) => n.depth);
    final sortedDepths = nodesByDepth.keys.toList()..sort();

    final wbNodes = bracket.allNodes
        .where((n) =>
            n.match.bracketType != BracketType.loser &&
            n.match.bracketType != BracketType.finals)
        .toList();
    final lbNodes = bracket.allNodes
        .where((n) => n.match.bracketType == BracketType.loser)
        .toList();
    final finalNodes = bracket.allNodes
        .where((n) => n.match.bracketType == BracketType.finals)
        .toList();

    // --- Pre-computation Step 1: Correct all source node links in the winner bracket ---
    // This is the critical fix: The BracketGenerator may link nodes incorrectly.
    // We rebuild the links based on the actual winners of the previous round.
    for (final node in wbNodes) {
      if (node.depth > 1) {
        final prevRoundNodes = wbNodes.where((n) => n.depth == node.depth - 1);
        final p1 = node.match.player1Id;
        final p2 = node.match.player2Id;

        BracketNode? source1;
        BracketNode? source2;

        if (p1 != 'bye' && p1 != 'TBD') {
          source1 = prevRoundNodes.firstWhereOrNull((prev) =>
              prev.match.winnerId == p1 ||
              (prev.match.player1Id == p1 && prev.match.player2Id == 'bye'));
        }
        if (p2 != null && p2 != 'bye' && p2 != 'TBD') {
          source2 = prevRoundNodes.firstWhereOrNull((prev) =>
              prev.match.winnerId == p2 ||
              (prev.match.player1Id == p2 && prev.match.player2Id == 'bye'));
        }

        // Assign the corrected sources back to the node.
        if (source1 != null && source2 != null) {
          // Ensure source1 is the one that is visually higher up based on original order.
          if (source1.verticalOrder > source2.verticalOrder) {
            final temp = source1;
            source1 = source2;
            source2 = temp;
          }
          node.sourceNode1 = source1;
          node.sourceNode2 = source2;
        }
      }
    }

    // --- Pre-computation Step 1.5: Correct all source node links in the loser bracket ---
    String? getLoserId(Match match) {
      if (match.status != MatchStatus.completed ||
          match.winnerId == null ||
          match.player2Id == 'bye') {
        return null;
      }
      if (match.winnerId == match.player1Id) return match.player2Id;
      if (match.winnerId == match.player2Id) return match.player1Id;
      return null;
    }

    for (final node in lbNodes) {
      final p1 = node.match.player1Id;
      final p2 = node.match.player2Id;

      BracketNode? source1;
      BracketNode? source2;

      if (p1 != 'bye' && p1 != 'TBD') {
        source1 = lbNodes
            .where(
                (prev) => prev.match.winnerId == p1 && prev.depth < node.depth)
            .sorted((a, b) => b.depth.compareTo(a.depth))
            .firstOrNull;
        source1 ??=
            wbNodes.firstWhereOrNull((prev) => getLoserId(prev.match) == p1);
      }

      if (p2 != null && p2 != 'bye' && p2 != 'TBD') {
        source2 = lbNodes
            .where(
                (prev) => prev.match.winnerId == p2 && prev.depth < node.depth)
            .sorted((a, b) => b.depth.compareTo(a.depth))
            .firstOrNull;
        source2 ??=
            wbNodes.firstWhereOrNull((prev) => getLoserId(prev.match) == p2);
      }

      // The positioning logic expects source1 to be from the loser bracket if possible.
      if (source1 != null &&
          source2 != null &&
          source1.match.bracketType != BracketType.loser &&
          source2.match.bracketType == BracketType.loser) {
        final temp = source1;
        source1 = source2;
        source2 = temp;
      }

      node.sourceNode1 = source1;
      node.sourceNode2 = source2;
    }

    // --- Pre-computation Step 2: Create an optimally ordered list for Round 1 ---
    // Now that the links are correct, we can re-order Round 1 for a clean layout.
    final round1Nodes = wbNodes.where((n) => n.depth == 1).toList();
    final round2Nodes = wbNodes.where((n) => n.depth == 2).toList();
    List<BracketNode> orderedRound1Nodes = round1Nodes
      ..sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));

    if (round1Nodes.isNotEmpty && round2Nodes.isNotEmpty) {
      final List<BracketNode> reorderedList = [];
      final Set<String> processedRound1Ids = {};

      final sortedRound2Nodes = List.of(round2Nodes)
        ..sort((a, b) {
          final aMinOrder = (a.sourceNode1 != null && a.sourceNode2 != null)
              ? min(a.sourceNode1!.verticalOrder, a.sourceNode2!.verticalOrder)
              : 0;
          final bMinOrder = (b.sourceNode1 != null && b.sourceNode2 != null)
              ? min(b.sourceNode1!.verticalOrder, b.sourceNode2!.verticalOrder)
              : 0;
          return aMinOrder.compareTo(bMinOrder);
        });

      for (final r2Node in sortedRound2Nodes) {
        final sources = [r2Node.sourceNode1, r2Node.sourceNode2]
            .nonNulls
            .toList()
          ..sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));

        for (final source in sources) {
          if (!processedRound1Ids.contains(source.id)) {
            reorderedList.add(source);
            processedRound1Ids.add(source.id);
          }
        }
      }

      final remaining =
          round1Nodes.where((n) => !processedRound1Ids.contains(n.id));
      reorderedList.addAll(remaining);

      if (reorderedList.length == round1Nodes.length) {
        orderedRound1Nodes = reorderedList;
      }
    }

    double winnerMaxY = 0;

    // --- Pass 1: Layout Winner Bracket ---
    for (final depth in sortedDepths) {
      final List<BracketNode> nodesInDepth;
      if (depth == 1) {
        nodesInDepth = orderedRound1Nodes;
      } else {
        nodesInDepth = wbNodes.where((n) => n.depth == depth).toList()
          ..sort((a, b) {
            final aMinY = (a.sourceNode1 != null && a.sourceNode2 != null)
                ? min(a.sourceNode1!.position.dy, a.sourceNode2!.position.dy)
                : 0.0;
            final bMinY = (b.sourceNode1 != null && b.sourceNode2 != null)
                ? min(b.sourceNode1!.position.dy, b.sourceNode2!.position.dy)
                : 0.0;
            return aMinY.compareTo(bMinY);
          });
      }

      for (int i = 0; i < nodesInDepth.length; i++) {
        final node = nodesInDepth[i];
        final double x = (node.depth - 1) * (_cardWidth + _roundSpacing);
        double y;

        if (node.depth > 1) {
          if (node.sourceNode1 != null && node.sourceNode2 != null) {
            y = (node.sourceNode1!.position.dy +
                    node.sourceNode2!.position.dy) /
                2;
          } else {
            y = i * (_cardHeight + _verticalCardSpacing);
          }
        } else {
          y = i * (_cardHeight + _verticalCardSpacing);
        }

        if (i > 0) {
          final prevNode = nodesInDepth[i - 1];
          final minAllowedY =
              prevNode.position.dy + _cardHeight + _verticalCardSpacing;
          if (y < minAllowedY) {
            y = minAllowedY;
          }
        }

        node.position = Offset(x, y);
        Log.v(
            '[胜者组] ${getPlayerNames(node.match)} (轮次 ${node.depth}) 位置: ${formatOffset(node.position)}');
        if (node.sourceNode1 != null) {
          Log.v(
              '  └── 连接自: ${getPlayerNames(node.sourceNode1!.match)} @ ${formatOffset(node.sourceNode1!.position)}');
        }
        if (node.sourceNode2 != null) {
          Log.v(
              '  └── 连接自: ${getPlayerNames(node.sourceNode2!.match)} @ ${formatOffset(node.sourceNode2!.position)}');
        }
        if (y > winnerMaxY) winnerMaxY = y;
      }
    }

    // --- Pass 2: Layout Loser Bracket Independently ---
    double loserMaxY = 0;
    final Map<String, Offset> lbRelativePositions = {};

    for (final depth in sortedDepths) {
      final nodesInDepth = lbNodes.where((n) => n.depth == depth).toList()
        ..sort((a, b) {
          double getSortY(BracketNode node) {
            // Case 1: Both sources are from the loser bracket. Sort by their midpoint.
            if (node.sourceNode1?.match.bracketType == BracketType.loser &&
                node.sourceNode2?.match.bracketType == BracketType.loser) {
              final y1 = lbRelativePositions[node.sourceNode1!.id]?.dy ?? 0.0;
              final y2 = lbRelativePositions[node.sourceNode2!.id]?.dy ?? 0.0;
              return (y1 + y2) / 2;
            }
            // Case 2: Only source1 is from the loser bracket. Sort by its position.
            if (node.sourceNode1?.match.bracketType == BracketType.loser) {
              return lbRelativePositions[node.sourceNode1!.id]?.dy ?? 0.0;
            }
            // Case 3: Only source2 is from the loser bracket. Sort by its position.
            if (node.sourceNode2?.match.bracketType == BracketType.loser) {
              return lbRelativePositions[node.sourceNode2!.id]?.dy ?? 0.0;
            }
            // Case 4: First round of the loser bracket (sources are from WB).
            // Sort by the minimum Y position of the players dropping down.
            final y1 = node.sourceNode1?.position.dy ?? double.infinity;
            final y2 = node.sourceNode2?.position.dy ?? double.infinity;
            return min(y1, y2);
          }

          return getSortY(a).compareTo(getSortY(b));
        });
      for (int i = 0; i < nodesInDepth.length; i++) {
        final node = nodesInDepth[i];
        // FIX: Remove X-axis offset for loser bracket
        final double x = (node.depth - 1) * (_cardWidth + _roundSpacing);
        double y;

        if (node.sourceNode1?.match.bracketType == BracketType.loser &&
            node.sourceNode2?.match.bracketType == BracketType.loser) {
          // Both sources are from LB, calculate midpoint in relative space
          final y1 = lbRelativePositions[node.sourceNode1!.id]!.dy;
          final y2 = lbRelativePositions[node.sourceNode2!.id]!.dy;
          y = (y1 + y2) / 2;
        } else if (node.sourceNode1?.match.bracketType == BracketType.loser) {
          // One source from LB, one from WB, align with the LB source
          y = lbRelativePositions[node.sourceNode1!.id]!.dy;
        } else {
          // First round of LB, position sequentially
          y = i * (_cardHeight + _verticalCardSpacing);
        }

        // Collision avoidance
        if (i > 0) {
          final prevNode = nodesInDepth[i - 1];
          final minAllowedY = lbRelativePositions[prevNode.id]!.dy +
              _cardHeight +
              _verticalCardSpacing;
          if (y < minAllowedY) {
            y = minAllowedY;
          }
        }

        lbRelativePositions[node.id] = Offset(x, y);
        if (y > loserMaxY) loserMaxY = y;
      }
    }

    // --- Pass 3: Shift Entire Loser Bracket Down ---
    final yShift = winnerMaxY + _cardHeight + (_verticalCardSpacing * 2);
    Log.v('败者组整体向下平移: ${yShift.toStringAsFixed(1)}');
    lbNodes.sort((a, b) => a.depth.compareTo(
        b.depth)); // Sort by depth to ensure sources are processed first
    for (final node in lbNodes) {
      final relativePos = lbRelativePositions[node.id]!;
      node.position = Offset(relativePos.dx, relativePos.dy + yShift);
      Log.v(
          '[败者组] ${getPlayerNames(node.match)} (轮次 ${node.depth}) 位置: ${formatOffset(node.position)}');
      if (node.sourceNode1 != null) {
        Log.v(
            '  └── 连接自: ${getPlayerNames(node.sourceNode1!.match)} @ ${formatOffset(node.sourceNode1!.position)}');
      }
      if (node.sourceNode2 != null) {
        Log.v(
            '  └── 连接自: ${getPlayerNames(node.sourceNode2!.match)} @ ${formatOffset(node.sourceNode2!.position)}');
      }
    }

    // --- Pass 4: Position Finals Last ---
    for (final node in finalNodes) {
      if (node.sourceNode1 != null && node.sourceNode2 != null) {
        final double x = (node.depth - 1) * (_cardWidth + _roundSpacing);
        final y =
            (node.sourceNode1!.position.dy + node.sourceNode2!.position.dy) / 2;
        node.position = Offset(x, y);
        Log.v(
            '[决赛] ${getPlayerNames(node.match)} 位置修正: ${formatOffset(node.position)}');
        if (node.sourceNode1 != null) {
          Log.v(
              '  └── 连接自: ${getPlayerNames(node.sourceNode1!.match)} @ ${formatOffset(node.sourceNode1!.position)}');
        }
        if (node.sourceNode2 != null) {
          Log.v(
              '  └── 连接自: ${getPlayerNames(node.sourceNode2!.match)} @ ${formatOffset(node.sourceNode2!.position)}');
        }
      }
    }
    Log.v('对阵图节点位置计算完毕。');
  }

  void _centerView() {
    if (!mounted ||
        _interactiveViewerKey.currentContext == null ||
        _bracket == null ||
        _bracket!.allNodes.isEmpty) {
      return;
    }

    final RenderBox renderBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final viewSize = renderBox.size;

    final totalWidth = _bracket!.allNodes
            .map((n) => n.position.dx)
            .reduce((max, x) => x > max ? x : x) +
        _cardWidth;
    final totalHeight = _bracket!.allNodes
            .map((n) => n.position.dy)
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final playerState = ref.watch(playerProvider).value;
    if (playerState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bracket == null || _bracket!.allNodes.isEmpty) {
      return const Center(child: Text('没有比赛信息可供显示'));
    }

    final totalWidth = _bracket!.allNodes
            .map((n) => n.position.dx)
            .reduce((max, x) => x > max ? x : x) +
        _cardWidth;
    final totalHeight = _bracket!.allNodes
            .map((n) => n.position.dy)
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
                      bracket: _bracket!,
                      lineColor: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  ..._bracket!.allNodes.map((node) {
                    return Positioned(
                      left: node.position.dx,
                      top: node.position.dy,
                      child: _MatchCard(
                          match: node.match, players: playerState.players),
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

/// The new, simplified painter that draws lines based on the bracket tree.
class _BracketLinePainter extends CustomPainter {
  final TournamentBracket bracket;
  final Color lineColor;

  _BracketLinePainter({required this.bracket, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    // Iterate through all nodes and draw lines to their sources.
    for (final node in bracket.allNodes) {
      // --- Special handling for Loser Bracket connections ---
      // In the loser bracket, we only want to draw the clean horizontal
      // progression lines from the winner of the *previous* loser bracket match.
      // We do NOT draw the jagged lines from the players dropping down from
      // the winner's bracket, as this creates a messy, overlapping view.
      if (node.match.bracketType == BracketType.loser) {
        // A match in the LB can be fed by another LB match (advancing player)
        // or a WB match (player dropping down). We only draw the former.
        if (node.sourceNode1?.match.bracketType == BracketType.loser) {
          _drawConnector(canvas, paint, node, node.sourceNode1!);
        }
        if (node.sourceNode2?.match.bracketType == BracketType.loser) {
          _drawConnector(canvas, paint, node, node.sourceNode2!);
        }
      } else {
        // For Winner Bracket and Finals, draw all connections as normal.
        if (node.sourceNode1 != null) {
          _drawConnector(canvas, paint, node, node.sourceNode1!);
        }
        if (node.sourceNode2 != null) {
          _drawConnector(canvas, paint, node, node.sourceNode2!);
        }
      }
    }
  }

  void _drawConnector(
      Canvas canvas, Paint paint, BracketNode target, BracketNode source) {
    final targetPos = target.position;
    final sourcePos = source.position;

    // Y-position for the line start/end points.
    final targetY = targetPos.dy + _cardHeight / 2;
    final sourceWinnerY = _getWinnerYOffset(source);

    final startX = sourcePos.dx + _cardWidth;
    final endX = targetPos.dx;
    final midX = startX + _roundSpacing / 2;

    // Horizontal line from source
    canvas.drawLine(
        Offset(startX, sourceWinnerY), Offset(midX, sourceWinnerY), paint);
    // Vertical line connecting the paths
    canvas.drawLine(Offset(midX, sourceWinnerY), Offset(midX, targetY), paint);
    // Horizontal line to target
    canvas.drawLine(Offset(midX, targetY), Offset(endX, targetY), paint);
  }

  /// Calculates the Y-offset for the line based on the winner.
  double _getWinnerYOffset(BracketNode node) {
    final match = node.match;
    final pos = node.position;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
