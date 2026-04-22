import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum MiniGameKind {
  memoryMatch,
  wordComplete,
  mathQuick,
  tapOdd;

  String get title => const [
        'MEMORY MATCH',
        'WORD COMPLETE',
        'MATH QUICK',
        'TAP THE ODD',
      ][index];

  String get instructions => const [
        'Flip cards and match the pairs.\nFewer flips, more flames!',
        'Tap the missing letter\nto complete each word.',
        'Answer fast math questions\nbefore the timer runs out.',
        'Spot the circle that looks\nslightly different. Be quick!',
      ][index];

  IconData get icon => const [
        Icons.grid_view_rounded,
        Icons.abc_rounded,
        Icons.calculate_rounded,
        Icons.visibility_rounded,
      ][index];

  Color get accent => const [
        T.classic, // blue
        T.daily, // green
        T.duel, // yellow
        T.timeAttack, // red
      ][index];

  static MiniGameKind forLevel(int level) =>
      values[(level - 1) % values.length];
}

/// Callbacks passed from the host screen to every mini-game.
class MiniGameCallbacks {
  final VoidCallback onSolved;
  final void Function(String reason) onFailed;
  const MiniGameCallbacks({required this.onSolved, required this.onFailed});
}
