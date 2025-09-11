import 'package:counters/common/model/match.dart';
import 'package:flutter/material.dart';

/// Represents the entire structured tournament bracket.
class TournamentBracket {
  /// The root node of the winner's bracket tree.
  final BracketNode? winnerBracketRoot;

  /// The root node of the loser's bracket tree.
  final BracketNode? loserBracketRoot;

  /// The root node for the grand final(s).
  final BracketNode? grandFinal;

  /// A flat list of all nodes for easy iteration and rendering.
  final List<BracketNode> allNodes;

  TournamentBracket({
    this.winnerBracketRoot,
    this.loserBracketRoot,
    this.grandFinal,
    required this.allNodes,
  });
}

/// Represents a single node (a match) in the tournament bracket tree.
class BracketNode {
  final Match match;

  /// The node from which the first player/team comes.
  BracketNode? sourceNode1;

  /// The node from which the second player/team comes.
  BracketNode? sourceNode2;

  /// The depth of the node in the bracket tree (equivalent to round).
  final int depth;

  /// The visual position of the node on the canvas.
  /// This is calculated later by the layout algorithm.
  Offset position = Offset.zero;

  /// The vertical order within a round, used for initial layout.
  final int verticalOrder;

  BracketNode({
    required this.match,
    required this.depth,
    required this.verticalOrder,
    this.sourceNode1,
    this.sourceNode2,
  });

  /// Unique identifier for the node, based on the match ID.
  String get id => match.mid;
}
