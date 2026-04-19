import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/puzzle_model.dart';
import '../services/api_client.dart';
import '../services/daily_service.dart';
import '../services/profile_service.dart';
import '../services/solve_service.dart';
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
  AppState({
    ProfileService? profileService,
    SolveService? solveService,
    DailyService? dailyService,
  })  : _profileService = profileService ?? ProfileService(),
        _solveService = solveService ?? SolveService(),
        _dailyService = dailyService ?? DailyService();

  final ProfileService _profileService;
  final SolveService _solveService;
  final DailyService _dailyService;

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
  int dailyStage = 0;
  Map<String, int> dailyMoves = {};
  Map<String, int> dailyTimes = {};
  String? dailyStageDate;

  // ── User/session fields ─────────────────────────────────────────────────────
  String? userName;
  String? userEmail;
  int? userId;

  bool get isSignedIn => ApiClient.instance.isAuthenticated;

  // ── Load / Save ─────────────────────────────────────────────────────────────
  /// Loads the token, then either fetches the profile from the backend
  /// (source of truth) or reads the last cached snapshot for offline use.
  Future<void> load() async {
    await ApiClient.instance.loadToken();
    await _loadCacheFromPrefs();

    if (ApiClient.instance.isAuthenticated) {
      try {
        final profile = await _profileService.fetch();
        _applyProfile(profile);
        await _saveCacheToPrefs();
      } catch (_) {
        // Offline: keep cached values
      }
    }
    notifyListeners();
  }

  Future<void> _loadCacheFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    streak = prefs.getInt('streak') ?? 0;
    totalSolved = prefs.getInt('totalSolved') ?? 0;
    dailyCompletedToday = prefs.getBool('dailyDone') ?? false;
    hasWonDuel = prefs.getBool('hasWonDuel') ?? false;

    final lastStr = prefs.getString('lastDaily');
    if (lastStr != null) lastDailyDate = DateTime.tryParse(lastStr);

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
    if (triesStr != null) lastTriesDate = DateTime.tryParse(triesStr);
    triesLeft = prefs.getInt('triesLeft') ?? 5;
    flames = prefs.getInt('flames') ?? 0;

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

    userId = prefs.getInt('userId');
    userName = prefs.getString('userName');
    userEmail = prefs.getString('userEmail');
  }

  Future<void> _saveCacheToPrefs() async {
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

    final unlockedIds =
        achievements.where((a) => a.unlocked).map((a) => a.id).toList();
    await prefs.setStringList('achievements', unlockedIds);

    await prefs.setInt('triesLeft', triesLeft);
    await prefs.setInt('flames', flames);
    if (lastTriesDate != null) {
      await prefs.setString('lastTriesDate', lastTriesDate!.toIso8601String());
    }

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

    if (userId != null) await prefs.setInt('userId', userId!);
    if (userName != null) await prefs.setString('userName', userName!);
    if (userEmail != null) await prefs.setString('userEmail', userEmail!);
  }

  /// Kept for backwards compatibility with existing call sites.
  Future<void> save() => _saveCacheToPrefs();

  /// Applies a profile payload from the backend.
  void _applyProfile(Map<String, dynamic> p) {
    userId = _asInt(p['id']);
    userName = p['name'] as String?;
    userEmail = p['email'] as String?;

    streak = _asInt(p['streak']) ?? 0;
    totalSolved = _asInt(p['total_solved']) ?? 0;
    flames = _asInt(p['flames']) ?? 0;
    triesLeft = _asInt(p['tries_left']) ?? 5;
    hasWonDuel = p['has_won_duel'] == true;
    dailyCompletedToday = p['daily_completed_today'] == true;
    dailyStage = _asInt(p['daily_stage']) ?? 0;

    lastDailyDate = _asDate(p['last_daily_date']);
    lastTriesDate = _asDate(p['last_tries_date']);
    dailyStageDate = p['daily_stage_date'] as String?;

    final bm = p['best_moves'];
    if (bm is Map) {
      bestMoves = {
        'easy': _asInt(bm['easy']) ?? 99999,
        'medium': _asInt(bm['medium']) ?? 99999,
        'hard': _asInt(bm['hard']) ?? 99999,
      };
    }

    final unlocked = (p['achievements'] as List?)?.cast<String>() ?? const [];
    for (final a in achievements) {
      a.unlocked = unlocked.contains(a.id);
    }
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
  }

  static DateTime? _asDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  // ── Authentication hooks ────────────────────────────────────────────────────
  Future<void> onAuthenticated(Map<String, dynamic> user) async {
    userId = _asInt(user['id']);
    userName = user['name'] as String?;
    userEmail = user['email'] as String?;
    await load();
  }

  Future<void> signOut() async {
    await ApiClient.instance.setToken(null);
    userId = null;
    userName = null;
    userEmail = null;
    notifyListeners();
  }

  // ── Record solve ────────────────────────────────────────────────────────────
  Future<void> recordSolve({
    required Difficulty d,
    required int moves,
    required int seconds,
    required bool usedPowerups,
    bool isTimeAttack = false,
    bool isCustomPhoto = false,
    bool isDaily = false,
  }) async {
    // Local optimistic update so UI responds immediately.
    totalSolved++;
    final key = d.name;
    if (!bestMoves.containsKey(key) || moves < bestMoves[key]!) {
      bestMoves[key] = moves;
    }

    _unlock('first_steps');
    if (seconds < 30) _unlock('speed_demon');
    if (d == Difficulty.easy && moves <= 20) _unlock('minimalist');
    if (!usedPowerups) _unlock('powerless');
    if (d == Difficulty.hard) _unlock('hard_core');
    if (totalSolved >= 25) _unlock('marathon');
    if (isTimeAttack) _unlock('time_warrior');
    if (isCustomPhoto) _unlock('custom_creator');
    if (moves <= d.starA) _unlock('perfectionist');

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

    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      try {
        final res = await _solveService.submit(
          difficulty: d.name,
          moves: moves,
          seconds: seconds,
          usedPowerups: usedPowerups,
          isTimeAttack: isTimeAttack,
          isCustomPhoto: isCustomPhoto,
          isDaily: isDaily,
        );
        final profile = res['profile'];
        if (profile is Map<String, dynamic>) {
          _applyProfile(profile);
          notifyListeners();
        }
      } catch (_) {
        // Keep optimistic local state
      }
    }

    await _saveCacheToPrefs();
  }

  Future<void> spendFlames(int amount) async {
    if (flames < amount) return;

    flames -= amount;
    triesLeft++;
    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      try {
        final profile = await _profileService.spendFlames(amount);
        _applyProfile(profile);
        notifyListeners();
      } catch (_) {}
    }
    await _saveCacheToPrefs();
  }

  // ── Daily streak ────────────────────────────────────────────────────────────
  Future<void> checkDailyStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastDailyDate == null) return;

    final lastDay =
        DateTime(lastDailyDate!.year, lastDailyDate!.month, lastDailyDate!.day);
    final diff = today.difference(lastDay).inDays;

    if (diff > 1) {
      streak = 0;
    }
    if (diff > 0) {
      dailyCompletedToday = false;
    }
    await _saveCacheToPrefs();
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

    await _saveCacheToPrefs();
    notifyListeners();
  }

  // ── Duel win ────────────────────────────────────────────────────────────────
  Future<void> recordDuelWin() async {
    hasWonDuel = true;
    _unlock('duel_win');
    await _saveCacheToPrefs();
    notifyListeners();
  }

  // ── Daily Stage System ──────────────────────────────────────────────────────
  Difficulty? get currentDailyDifficulty {
    if (dailyStage >= 3) return null;
    return Difficulty.values[dailyStage];
  }

  int get dailySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  Future<void> recordDailyStage({
    required Difficulty d,
    required int moves,
    required int seconds,
  }) async {
    dailyMoves[d.name] = moves;
    dailyTimes[d.name] = seconds;
    dailyStage = d.index + 1;

    flames += 2;

    if (dailyStage >= 3) {
      dailyCompletedToday = true;
      flames += 5;
      await recordDailyComplete();
    }

    dailyStageDate = _todayString();
    notifyListeners();

    if (ApiClient.instance.isAuthenticated) {
      try {
        final res = await _dailyService.complete(
          difficulty: d.name,
          moves: moves,
          seconds: seconds,
        );
        final profile = res['profile'];
        if (profile is Map<String, dynamic>) {
          _applyProfile(profile);
          notifyListeners();
        }
      } catch (_) {}
    }
    await _saveCacheToPrefs();
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

  int get dailyTotalMoves =>
      (dailyMoves['easy'] ?? 0) +
      (dailyMoves['medium'] ?? 0) +
      (dailyMoves['hard'] ?? 0);
  int get dailyTotalTime =>
      (dailyTimes['easy'] ?? 0) +
      (dailyTimes['medium'] ?? 0) +
      (dailyTimes['hard'] ?? 0);

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

    entries.add(LeaderboardEntry(
      name: userName ?? 'You',
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
  Future<void> useTry() async {
    if (triesLeft > 0) {
      triesLeft--;
      notifyListeners();
    }
    if (ApiClient.instance.isAuthenticated) {
      try {
        final profile = await _profileService.useTry();
        _applyProfile(profile);
        notifyListeners();
      } catch (_) {}
    }
    await _saveCacheToPrefs();
  }

  Future<void> watchAdForTry() async {
    triesLeft++;
    notifyListeners();
    if (ApiClient.instance.isAuthenticated) {
      try {
        final profile = await _profileService.watchAdForTry();
        _applyProfile(profile);
        notifyListeners();
      } catch (_) {}
    }
    await _saveCacheToPrefs();
  }

  void _unlock(String id) {
    final achievement = achievements.where((a) => a.id == id).firstOrNull;
    if (achievement != null && !achievement.unlocked) {
      achievement.unlocked = true;
    }
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
}
