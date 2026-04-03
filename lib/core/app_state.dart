import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/puzzle_model.dart';
import 'theme.dart';

// ── Leaderboard Entry ─────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String name;
  final int totalMoves;
  final int totalSeconds;
  final bool isPlayer;

  const LeaderboardEntry({
    required this.name,
    required this.totalMoves,
    required this.totalSeconds,
    this.isPlayer = false,
  });
}

// ── Achievement ───────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });
}

// ── AppState ──────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  // ── Achievements ────────────────────────────────────────────────────────────
  final List<Achievement> achievements = [
    Achievement(
      id: 'first_steps',
      title: 'First Steps',
      desc: 'Complete your first puzzle',
      icon: Icons.flag,
      color: T.classic,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      desc: 'Solve a puzzle in under 30 seconds',
      icon: Icons.bolt,
      color: T.timeAttack,
    ),
    Achievement(
      id: 'minimalist',
      title: 'Minimalist',
      desc: 'Solve easy in 20 moves or fewer',
      icon: Icons.gesture,
      color: T.daily,
    ),
    Achievement(
      id: 'streak3',
      title: 'On a Roll',
      desc: '3-day daily streak',
      icon: Icons.local_fire_department,
      color: T.duel,
    ),
    Achievement(
      id: 'streak7',
      title: 'Unstoppable',
      desc: '7-day daily streak',
      icon: Icons.whatshot,
      color: T.timeAttack,
    ),
    Achievement(
      id: 'powerless',
      title: 'Powerless',
      desc: 'Solve without using any power-ups',
      icon: Icons.battery_0_bar,
      color: Color(0xFF8B5CF6),
    ),
    Achievement(
      id: 'duel_win',
      title: 'Duel Master',
      desc: 'Win a local duel match',
      icon: Icons.people,
      color: T.duel,
    ),
    Achievement(
      id: 'hard_core',
      title: 'Hard Core',
      desc: 'Complete a hard difficulty puzzle',
      icon: Icons.diamond,
      color: T.timeAttack,
    ),
    Achievement(
      id: 'marathon',
      title: 'Marathon',
      desc: 'Complete 25 puzzles total',
      icon: Icons.emoji_events,
      color: T.gold,
    ),
    Achievement(
      id: 'time_warrior',
      title: 'Time Warrior',
      desc: 'Complete a time attack puzzle',
      icon: Icons.timer,
      color: T.timeAttack,
    ),
    Achievement(
      id: 'custom_creator',
      title: 'Custom Creator',
      desc: 'Use your own photo',
      icon: Icons.photo_camera,
      color: T.custom,
    ),
    Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      desc: 'Earn 3 stars on any puzzle',
      icon: Icons.star,
      color: T.gold,
    ),
  ];

  // ── State fields ────────────────────────────────────────────────────────────
  int streak = 0;
  DateTime? lastDailyDate;
  bool dailyCompletedToday = false;
  int totalSolved = 0;
  Map<String, int> bestMoves = {};
  bool hasWonDuel = false;
  
  // Tries system
  int triesLeft = 5;
  DateTime? lastTriesDate;

  // Currency
  int flames = 0;

  // ── Daily Puzzle Stage System ───────────────────────────────────────────────
  // 0 = none done, 1 = easy done, 2 = medium done, 3 = all done
  int dailyStage = 0;
  // Per-stage results: moves & seconds for today's completed stages
  Map<String, int> dailyMoves = {}; // 'easy', 'medium', 'hard'
  Map<String, int> dailyTimes = {};
  String? dailyStageDate; // ISO date string to detect day change

  // ── Load / Save ─────────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    streak = prefs.getInt('streak') ?? 0;
    totalSolved = prefs.getInt('totalSolved') ?? 0;
    dailyCompletedToday = prefs.getBool('dailyDone') ?? false;
    hasWonDuel = prefs.getBool('hasWonDuel') ?? false;

    final lastStr = prefs.getString('lastDaily');
    if (lastStr != null) {
      lastDailyDate = DateTime.tryParse(lastStr);
    }

    bestMoves = {
      'easy': prefs.getInt('bestMovesEasy') ?? 99999,
      'medium': prefs.getInt('bestMovesMedium') ?? 99999,
      'hard': prefs.getInt('bestMovesHard') ?? 99999,
    };

    final achievementIds = prefs.getStringList('achievements') ?? [];
    for (final a in achievements) {
      a.unlocked = achievementIds.contains(a.id);
    }

    final triesStr = prefs.getString('lastTriesDate');
    if (triesStr != null) {
      lastTriesDate = DateTime.tryParse(triesStr);
    }
    triesLeft = prefs.getInt('triesLeft') ?? 5;
    flames = prefs.getInt('flames') ?? 0;
    _checkTriesRefill();

    // Daily stage system
    dailyStage = prefs.getInt('dailyStage') ?? 0;
    dailyStageDate = prefs.getString('dailyStageDate');
    dailyMoves = {
      'easy': prefs.getInt('dailyMovesEasy') ?? 0,
      'medium': prefs.getInt('dailyMovesMedium') ?? 0,
      'hard': prefs.getInt('dailyMovesHard') ?? 0,
    };
    dailyTimes = {
      'easy': prefs.getInt('dailyTimeEasy') ?? 0,
      'medium': prefs.getInt('dailyTimeMedium') ?? 0,
      'hard': prefs.getInt('dailyTimeHard') ?? 0,
    };
    _checkDailyStageReset();

    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', streak);
    await prefs.setInt('totalSolved', totalSolved);
    await prefs.setBool('dailyDone', dailyCompletedToday);
    await prefs.setBool('hasWonDuel', hasWonDuel);
    if (lastDailyDate != null) {
      await prefs.setString('lastDaily', lastDailyDate!.toIso8601String());
    }
    await prefs.setInt('bestMovesEasy', bestMoves['easy'] ?? 99999);
    await prefs.setInt('bestMovesMedium', bestMoves['medium'] ?? 99999);
    await prefs.setInt('bestMovesHard', bestMoves['hard'] ?? 99999);
    final unlockedIds = achievements
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toList();
    await prefs.setStringList('achievements', unlockedIds);
    await prefs.setInt('triesLeft', triesLeft);
    await prefs.setInt('flames', flames);
    if (lastTriesDate != null) {
      await prefs.setString('lastTriesDate', lastTriesDate!.toIso8601String());
    }
    // Daily stage
    await prefs.setInt('dailyStage', dailyStage);
    if (dailyStageDate != null) {
      await prefs.setString('dailyStageDate', dailyStageDate!);
    }
    await prefs.setInt('dailyMovesEasy', dailyMoves['easy'] ?? 0);
    await prefs.setInt('dailyMovesMedium', dailyMoves['medium'] ?? 0);
    await prefs.setInt('dailyMovesHard', dailyMoves['hard'] ?? 0);
    await prefs.setInt('dailyTimeEasy', dailyTimes['easy'] ?? 0);
    await prefs.setInt('dailyTimeMedium', dailyTimes['medium'] ?? 0);
    await prefs.setInt('dailyTimeHard', dailyTimes['hard'] ?? 0);
  }

  // ── Record solve ─────────────────────────────────────────────────────────────
  Future<void> recordSolve({
    required Difficulty d,
    required int moves,
    required int seconds,
    required bool usedPowerups,
    bool isTimeAttack = false,
    bool isCustomPhoto = false,
    bool isDaily = false,
  }) async {
    totalSolved++;

    final key = d.name;
    if (!bestMoves.containsKey(key) || moves < bestMoves[key]!) {
      bestMoves[key] = moves;
    }

    // Check achievements
    _unlock('first_steps');

    if (seconds < 30) _unlock('speed_demon');
    if (d == Difficulty.easy && moves <= 20) _unlock('minimalist');
    if (!usedPowerups) _unlock('powerless');
    if (d == Difficulty.hard) _unlock('hard_core');
    if (totalSolved >= 25) _unlock('marathon');
    if (isTimeAttack) _unlock('time_warrior');
    if (isCustomPhoto) _unlock('custom_creator');
    if (d == Difficulty.easy && moves <= d.starA) _unlock('perfectionist');
    if (d == Difficulty.medium && moves <= d.starA) _unlock('perfectionist');
    if (d == Difficulty.hard && moves <= d.starA) _unlock('perfectionist');

    // Add Flame Rewards
    if (moves <= d.starA) {
      flames += 3;
    } else if (moves <= d.starB) {
      flames += 2;
    } else {
      flames += 1;
    }

    if (isDaily) {
      await recordDailyComplete();
    }

    await save();
    notifyListeners();
  }

  Future<void> spendFlames(int amount) async {
    if (flames >= amount) {
      flames -= amount;
      triesLeft++; // grant a try instantly
      await save();
      notifyListeners();
    }
  }

  // ── Daily streak ────────────────────────────────────────────────────────────
  Future<void> checkDailyStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastDailyDate == null) return;

    final lastDay = DateTime(
      lastDailyDate!.year,
      lastDailyDate!.month,
      lastDailyDate!.day,
    );
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) {
      // Same day — streak unchanged
    } else if (diff == 1) {
      // Yesterday — streak still valid but not yet incremented
    } else {
      // Gap of 2+ days — reset streak
      streak = 0;
      await save();
    }

    // Reset dailyCompletedToday if it's a new day
    if (diff > 0) {
      dailyCompletedToday = false;
      await save();
    }

    notifyListeners();
  }

  Future<void> recordDailyComplete() async {
    if (dailyCompletedToday) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastDailyDate != null) {
      final lastDay = DateTime(
        lastDailyDate!.year,
        lastDailyDate!.month,
        lastDailyDate!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    dailyCompletedToday = true;
    lastDailyDate = today;

    if (streak >= 3) _unlock('streak3');
    if (streak >= 7) _unlock('streak7');

    await save();
    notifyListeners();
  }

  // ── Duel win ────────────────────────────────────────────────────────────────
  Future<void> recordDuelWin() async {
    hasWonDuel = true;
    _unlock('duel_win');
    await save();
    notifyListeners();
  }

  // ── Daily Stage System ──────────────────────────────────────────────────────

  /// The difficulty for the current daily stage.
  Difficulty? get currentDailyDifficulty {
    if (dailyStage >= 3) return null; // all done
    return Difficulty.values[dailyStage];
  }

  /// Seed for daily puzzle, deterministic per date.
  int get dailySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Record completion of the current daily stage.
  Future<void> recordDailyStage({
    required Difficulty d,
    required int moves,
    required int seconds,
  }) async {
    dailyMoves[d.name] = moves;
    dailyTimes[d.name] = seconds;
    dailyStage = d.index + 1; // advance to next stage

    // Award flames for daily completion
    flames += 2;

    // If all 3 stages done, mark daily as complete for streak
    if (dailyStage >= 3) {
      dailyCompletedToday = true;
      flames += 5; // Bonus for full completion
      await recordDailyComplete();
    }

    final todayStr = _todayString();
    dailyStageDate = todayStr;

    await save();
    notifyListeners();
  }

  void _checkDailyStageReset() {
    final todayStr = _todayString();
    if (dailyStageDate != todayStr) {
      dailyStage = 0;
      dailyMoves = {'easy': 0, 'medium': 0, 'hard': 0};
      dailyTimes = {'easy': 0, 'medium': 0, 'hard': 0};
      dailyStageDate = todayStr;
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Total moves + time across all completed daily stages.
  int get dailyTotalMoves =>
      (dailyMoves['easy'] ?? 0) + (dailyMoves['medium'] ?? 0) + (dailyMoves['hard'] ?? 0);
  int get dailyTotalTime =>
      (dailyTimes['easy'] ?? 0) + (dailyTimes['medium'] ?? 0) + (dailyTimes['hard'] ?? 0);

  /// Generate a simulated per-stage leaderboard with the player's score injected.
  List<LeaderboardEntry> getDailyStageLeaderboard({
    required Difficulty d,
    required int playerMoves,
    required int playerSeconds,
  }) {
    final rng = Random(dailySeed + d.index * 7);
    final names = [
      'PuzzlePro', 'TileKing', 'SlydeMaster', 'BrainStorm',
      'MoveGuru', 'SpeedSlyde', 'GridNinja', 'SwiftSolver',
      'TileWhiz', 'PuzzleAce', 'QuickFlip', 'GameWizard',
      'SlydeHero', 'TileChamp', 'BrainFlip', 'GridLord',
      'MindMaze', 'PuzzleStar', 'TileForce', 'SlydeKing',
    ];

    // Generate ranges appropriate for each difficulty
    final moveBase = const [10, 30, 60][d.index];
    final moveRange = const [40, 100, 200][d.index];
    final timeBase = const [20, 50, 100][d.index];
    final timeRange = const [120, 240, 400][d.index];

    final entries = <LeaderboardEntry>[];
    for (int i = 0; i < 20; i++) {
      final m = moveBase + rng.nextInt(moveRange);
      final s = timeBase + rng.nextInt(timeRange);
      entries.add(LeaderboardEntry(
        name: names[rng.nextInt(names.length)],
        totalMoves: m,
        totalSeconds: s,
      ));
    }

    // Add the player
    entries.add(LeaderboardEntry(
      name: 'You',
      totalMoves: playerMoves,
      totalSeconds: playerSeconds,
      isPlayer: true,
    ));

    entries.sort((a, b) {
      final mc = a.totalMoves.compareTo(b.totalMoves);
      if (mc != 0) return mc;
      return a.totalSeconds.compareTo(b.totalSeconds);
    });

    return entries;
  }

  /// Get just the player's rank for a stage.
  int getPlayerDailyRank({
    required Difficulty d,
    required int playerMoves,
    required int playerSeconds,
  }) {
    final entries = getDailyStageLeaderboard(
      d: d,
      playerMoves: playerMoves,
      playerSeconds: playerSeconds,
    );
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].isPlayer) return i + 1;
    }
    return entries.length;
  }

  // ── Internal ────────────────────────────────────────────────────────────────
  void _checkTriesRefill() {
    final now = DateTime.now();
    if (lastTriesDate == null) {
      lastTriesDate = now;
      triesLeft = 5;
    } else {
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(lastTriesDate!.year, lastTriesDate!.month, lastTriesDate!.day);
      if (today.difference(lastDay).inDays >= 1) {
        lastTriesDate = now;
        triesLeft = 5;
      }
    }
  }

  Future<void> useTry() async {
    _checkTriesRefill();
    if (triesLeft > 0) {
      triesLeft--;
      await save();
      notifyListeners();
    }
  }

  Future<void> watchAdForTry() async {
    // Fake ad watch logic - instant for now
    triesLeft++;
    await save();
    notifyListeners();
  }

  void _unlock(String id) {
    final achievement = achievements.where((a) => a.id == id).firstOrNull;
    if (achievement != null && !achievement.unlocked) {
      achievement.unlocked = true;
      // Save is called by the caller
    }
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
}
