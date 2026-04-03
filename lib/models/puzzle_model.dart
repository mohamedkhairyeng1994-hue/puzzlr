import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Difficulty ────────────────────────────────────────────────────────────────

enum Difficulty {
  easy,
  medium,
  hard;

  int get gridSize => const [3, 4, 5][index];
  int get shuffleMoves => const [50, 120, 250][index];
  int get starA => const [20, 50, 100][index];
  int get starB => const [60, 120, 250][index];
  int get moveLimit => const [50, 200, 450][index];
  int get timeLimit => const [120, 240, 420][index];

  String get label => const ['Easy', 'Medium', 'Hard'][index];
  String get gridLabel => const ['3×3', '4×4', '5×5'][index];
  String get subtitle => const [
    'Perfect to start · 3×3',
    'A real challenge · 4×4',
    'Expert territory · 5×5',
  ][index];

  Color get accent =>
      const [Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFFF43F5E)][index];

  IconData get icon => const [
    Icons.sentiment_satisfied_alt_outlined,
    Icons.local_fire_department_outlined,
    Icons.bolt_outlined,
  ][index];
}

// ── PuzzleModel ───────────────────────────────────────────────────────────────

class PuzzleModel extends ChangeNotifier {
  final Difficulty difficulty;
  final int seed;
  final bool usePowerups;

  late List<int> _tiles;
  late int _emptyPos;
  int _moves = 0;
  bool _solved = false;

  // Mystery reveal: positions where tile == correct tile
  final Set<int> _inPlace = {};

  // Power-ups
  late int peekLeft;
  int hintLeft = 2;
  int autoLeft = 1;
  bool isPeeking = false;
  int? hintPos;

  late Random _rng;

  PuzzleModel({required this.difficulty, int? seed, this.usePowerups = true})
    : seed = seed ?? Random().nextInt(999999) {
    peekLeft = difficulty == Difficulty.easy ? 1 : (difficulty == Difficulty.medium ? 2 : 3);
    _rng = Random(this.seed);
    _init();
    _shuffle();
  }

  int get gridSize => difficulty.gridSize;
  int get total => gridSize * gridSize;
  List<int> get tiles => List.unmodifiable(_tiles);
  int get emptyPos => _emptyPos;
  int get moves => _moves;
  bool get solved => _solved;

  bool inPlace(int pos) => _tiles[pos] == pos;

  Set<int> get inPlaceSet => Set.unmodifiable(_inPlace);

  void _init() {
    _tiles = List.generate(total, (i) => i);
    _emptyPos = total - 1;
    _moves = 0;
    _solved = false;
    _inPlace.clear();
    hintPos = null;
    isPeeking = false;
    _refreshInPlace();
  }

  void _shuffle() {
    int prev = -1;
    for (int i = 0; i < difficulty.shuffleMoves; i++) {
      final nbrs = _adj(_emptyPos).where((n) => n != prev).toList();
      final pick = nbrs[_rng.nextInt(nbrs.length)];
      _swap(_emptyPos, pick);
      prev = _emptyPos;
      _emptyPos = pick;
    }
    if (_checkSolved()) _shuffle();
    _refreshInPlace();
  }

  List<int> _adj(int pos) {
    final r = pos ~/ gridSize, c = pos % gridSize;
    return [
      if (r > 0) pos - gridSize,
      if (r < gridSize - 1) pos + gridSize,
      if (c > 0) pos - 1,
      if (c < gridSize - 1) pos + 1,
    ];
  }

  void _swap(int a, int b) {
    final t = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = t;
  }

  bool canMove(int pos) => _adj(_emptyPos).contains(pos);

  void tap(int pos) {
    if (!canMove(pos) || _solved) return;
    _swap(pos, _emptyPos);
    _emptyPos = pos;
    _moves++;
    hintPos = null;
    _refreshInPlace();
    _solved = _checkSolved();
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void _refreshInPlace() {
    _inPlace.clear();
    for (int i = 0; i < total; i++) {
      if (_tiles[i] == i) _inPlace.add(i);
    }
  }

  bool _checkSolved() {
    for (int i = 0; i < total; i++) {
      if (_tiles[i] != i) return false;
    }
    return true;
  }

  // ── Power-ups ──────────────────────────────────────────────────────────────

  void activatePeek() {
    if (peekLeft <= 0 || !usePowerups) return;
    peekLeft--;
    isPeeking = true;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void deactivatePeek() {
    isPeeking = false;
    notifyListeners();
  }

  void activateHint() {
    if (hintLeft <= 0 || !usePowerups || _solved) return;
    hintLeft--;
    hintPos = _bestMove();
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void activateAutoMove() {
    if (autoLeft <= 0 || !usePowerups || _solved) return;
    autoLeft--;
    final best = _bestMove();
    if (best != null) {
      tap(best);
    }
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  int? _bestMove() {
    final candidates = _adj(_emptyPos);
    if (candidates.isEmpty) return null;

    int? bestPos;
    int bestDelta = -999;

    for (final pos in candidates) {
      final before = _totalManhattan();
      // Simulate swap
      _swap(pos, _emptyPos);
      final prevEmpty = _emptyPos;
      _emptyPos = pos;
      final after = _totalManhattan();
      // Undo swap
      _emptyPos = prevEmpty;
      _swap(pos, _emptyPos);

      final delta = before - after; // positive = improvement
      if (delta > bestDelta) {
        bestDelta = delta;
        bestPos = pos;
      }
    }
    return bestPos;
  }

  int _totalManhattan() {
    int total = 0;
    for (int pos = 0; pos < this.total; pos++) {
      final piece = _tiles[pos];
      if (piece == this.total - 1) continue; // skip empty
      final goalR = piece ~/ gridSize;
      final goalC = piece % gridSize;
      final curR = pos ~/ gridSize;
      final curC = pos % gridSize;
      total += (goalR - curR).abs() + (goalC - curC).abs();
    }
    return total;
  }

  void restart() {
    peekLeft = difficulty == Difficulty.easy ? 1 : (difficulty == Difficulty.medium ? 2 : 3);
    hintLeft = 2;
    autoLeft = 1;
    _rng = Random(seed);
    _init();
    _shuffle();
    notifyListeners();
  }

  void forceSolve() {
    if (_solved) return;
    for (int i = 0; i < total; i++) {
      _tiles[i] = i;
    }
    _emptyPos = total - 1;
    _solved = true;
    _refreshInPlace();
    notifyListeners();
  }

  int get stars {
    if (_moves <= difficulty.starA) return 3;
    if (_moves <= difficulty.starB) return 2;
    return 1;
  }

  int posOf(int p) => _tiles.indexOf(p);
}
