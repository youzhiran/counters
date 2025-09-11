import 'package:collection/collection.dart';
import 'package:counters/common/model/league_enums.dart';
import 'package:counters/common/model/match.dart';
import 'package:counters/features/league/model/bracket_models.dart';

/// A service to generate a structured tournament bracket from a flat list of matches.
class BracketGenerator {
  /// Generates a [TournamentBracket] from a list of [Match] objects.
  ///
  /// This method contains the core logic for inferring the bracket structure
  /// for both single and double elimination tournaments.
  TournamentBracket generate(List<Match> allMatches) {
    if (allMatches.isEmpty) {
      return TournamentBracket(allNodes: []);
    }

    // 1. Create nodes for all matches and map them by ID for easy access.
    final allNodes = <String, BracketNode>{};
    final groupedByRound = groupBy(allMatches, (m) => m.round);

    groupedByRound.forEach((round, matchesInRound) {
      // CRITICAL FIX: Do NOT sort by mid. The natural order in the list
      // is the only reliable source for the visual top-to-bottom order.
      // matchesInRound.sort((a, b) => a.mid.compareTo(b.mid)); // THIS WAS THE ROOT CAUSE OF ALL LINKING ERRORS
      for (var i = 0; i < matchesInRound.length; i++) {
        final match = matchesInRound[i];
        allNodes[match.mid] = BracketNode(
          match: match,
          depth: round,
          verticalOrder: i,
        );
      }
    });

    // 2. Separate nodes by bracket type for specific linking logic.
    final nodesByBracketType =
        groupBy(allNodes.values, (node) => node.match.bracketType);

    final List<BracketNode> winnerNodes = [
      ...(nodesByBracketType[BracketType.winner] ?? []),
      ...(nodesByBracketType[null] ?? []), // Treat null as winner bracket
    ];
    final loserNodes = nodesByBracketType[BracketType.loser] ?? [];
    final finalNodes = nodesByBracketType[BracketType.finals] ?? [];

    final Map<int, List<BracketNode>> wbByRound =
        groupBy(winnerNodes, (n) => n.depth);
    final Map<int, List<BracketNode>> lbByRound =
        groupBy(loserNodes, (n) => n.depth);

    // 3. Link nodes within their respective brackets.
    _linkWinnerBracket(wbByRound, allNodes);
    _linkLoserBracket(lbByRound, wbByRound, allNodes);
    _linkFinals(finalNodes, wbByRound, lbByRound, allNodes);

    // 4. Identify the root nodes.
    final winnerRoot = winnerNodes.sortedBy<num>((n) => n.depth).lastOrNull;
    final loserRoot = loserNodes.sortedBy<num>((n) => n.depth).lastOrNull;
    final finalRoot = finalNodes.sortedBy<num>((n) => n.depth).lastOrNull;

    return TournamentBracket(
      winnerBracketRoot: winnerRoot,
      loserBracketRoot: loserRoot,
      grandFinal: finalRoot,
      allNodes: allNodes.values.toList(),
    );
  }

  /// Links nodes in the winner's bracket.
  void _linkWinnerBracket(
    Map<int, List<BracketNode>> wbByRound,
    Map<String, BracketNode> allNodes,
  ) {
    final sortedRounds = wbByRound.keys.toList()..sort();
    for (var i = 1; i < sortedRounds.length; i++) {
      final round = sortedRounds[i];
      final prevRound = sortedRounds[i - 1];
      final matchesInRound = wbByRound[round]!;
      final matchesInPrevRound = wbByRound[prevRound]!;

      // CRITICAL FIX: Sort by the visual vertical order, not by the arbitrary match ID.
      matchesInRound.sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));
      matchesInPrevRound
          .sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));

      for (int j = 0; j < matchesInRound.length; j++) {
        final node = matchesInRound[j];
        final sourceIndex1 = j * 2;
        final sourceIndex2 = sourceIndex1 + 1;

        if (sourceIndex1 < matchesInPrevRound.length) {
          node.sourceNode1 = matchesInPrevRound[sourceIndex1];
        }
        if (sourceIndex2 < matchesInPrevRound.length) {
          node.sourceNode2 = matchesInPrevRound[sourceIndex2];
        }
      }
    }
  }

  /// Links nodes in the loser's bracket, handling drop-downs from the winner's bracket.
  void _linkLoserBracket(
    Map<int, List<BracketNode>> lbByRound,
    Map<int, List<BracketNode>> wbByRound,
    Map<String, BracketNode> allNodes,
  ) {
    if (lbByRound.isEmpty) return;

    final sortedLbRounds = lbByRound.keys.toList()..sort();
    final sortedWbRounds = wbByRound.keys.toList()..sort();

    // Sort all rounds by vertical order first to ensure stable linking
    for (final round in sortedLbRounds) {
      lbByRound[round]!
          .sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));
    }
    for (final round in sortedWbRounds) {
      wbByRound[round]!
          .sort((a, b) => a.verticalOrder.compareTo(b.verticalOrder));
    }

    // Handle the first round of the loser bracket separately.
    // This is where losers from the first WB round are paired up.
    // The visual connection is problematic and incorrect to draw as a tree,
    // so we DO NOT link them. The player data in the match is sufficient.
    /*
    final firstLbRoundNum = sortedLbRounds.first;
    final firstWbRoundNum = sortedWbRounds.first;
    if (lbByRound.containsKey(firstLbRoundNum) &&
        wbByRound.containsKey(firstWbRoundNum)) {
      final matchesInFirstLbRound = lbByRound[firstLbRoundNum]!;
      final matchesInFirstWbRound = wbByRound[firstWbRoundNum]!;
      for (int j = 0; j < matchesInFirstLbRound.length; j++) {
        final node = matchesInFirstLbRound[j];
        final sourceIndex1 = j * 2;
        final sourceIndex2 = sourceIndex1 + 1;

        if (sourceIndex1 < matchesInFirstWbRound.length) {
          node.sourceNode1 = matchesInFirstWbRound[sourceIndex1];
        }
        if (sourceIndex2 < matchesInFirstWbRound.length) {
          node.sourceNode2 = matchesInFirstWbRound[sourceIndex2];
        }
      }
    }
    */

    // Link the rest of the loser bracket rounds.
    for (int i = 0; i < sortedLbRounds.length; i++) {
      final roundNum = sortedLbRounds[i];
      final matchesInRound = lbByRound[roundNum]!;

      // Skip the first round as it's handled (or intentionally skipped) above
      if (i == 0) continue;

      final prevLbRoundNum = sortedLbRounds[i - 1];

      for (var j = 0; j < matchesInRound.length; j++) {
        final node = matchesInRound[j];
        final prevLbRound = lbByRound[prevLbRoundNum]!;

        // In LB, rounds alternate between taking a dropped player from WB
        // and consolidating winners within LB.
        if (roundNum % 2 == 0) {
          // This round takes one winner from the previous LB round
          // and one loser dropped from a WB round.
          node.sourceNode1 = prevLbRound[j];

          // The link to the WB is visually confusing and incorrect.
          // We disable it. The player data is already correct in the match object.
          /*
          final wbRoundToDropFromIndex = (roundNum / 2).floor();
          if (wbRoundToDropFromIndex < sortedWbRounds.length) {
            final wbRound = wbByRound[sortedWbRounds[wbRoundToDropFromIndex]];
            if (wbRound != null && j < wbRound.length) {
              node.sourceNode2 = wbRound[j];
            }
          }
          */
        } else {
          // This round consolidates two winners from the previous LB round.
          final sourceIndex1 = j * 2;
          final sourceIndex2 = sourceIndex1 + 1;
          if (sourceIndex1 < prevLbRound.length) {
            node.sourceNode1 = prevLbRound[sourceIndex1];
          }
          if (sourceIndex2 < prevLbRound.length) {
            node.sourceNode2 = prevLbRound[sourceIndex2];
          }
        }
      }
    }
  }

  /// Links the final matches.
  void _linkFinals(
    List<BracketNode> finalNodes,
    Map<int, List<BracketNode>> wbByRound,
    Map<int, List<BracketNode>> lbByRound,
    Map<String, BracketNode> allNodes,
  ) {
    if (finalNodes.isEmpty) return;

    final grandFinal = finalNodes.first;
    final winnerFinal =
        wbByRound[(wbByRound.keys.toList()..sort()).lastOrNull]?.firstOrNull;
    final loserFinal =
        lbByRound[(lbByRound.keys.toList()..sort()).lastOrNull]?.firstOrNull;

    grandFinal.sourceNode1 = winnerFinal;
    grandFinal.sourceNode2 = loserFinal;

    // Link bracket reset match if it exists.
    if (finalNodes.length > 1) {
      final bracketReset = finalNodes[1];
      bracketReset.sourceNode1 = grandFinal;
      // The second player is technically also from the grand final.
      // For visualization, we only need one link.
    }
  }
}
