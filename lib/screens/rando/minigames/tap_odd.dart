import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../rando_models.dart';

class TapOddGame extends StatefulWidget {
  final int seed;
  final int level;
  final MiniGameCallbacks callbacks;

  const TapOddGame({
    super.key,
    required this.seed,
    required this.level,
    required this.callbacks,
  });

  @override
  State<TapOddGame> createState() => _TapOddGameState();
}

class _TapOddGameState extends State<TapOddGame> {
  static const int _rounds = 5;
  late int _oddIndex;
  late Color _baseColor;
  late Color _oddColor;
  late int _gridSize;
  int _roundIndex = 0;

  int _roundSec = 8;
  int _elapsedSec = 0;
  Timer? _ticker;
  late Random _rng;

  @override
  void initState() {
    super.initState();
    _rng = Random(widget.seed);
    _startRound();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startRound() {
    // Harder = smaller color difference, bigger grid
    final difficulty = (widget.level / 5).clamp(0, 5).toInt();
    _gridSize = 3 + min(2, _roundIndex ~/ 2 + difficulty ~/ 2); // 3..5
    final total = _gridSize * _gridSize;
    _oddIndex = _rng.nextInt(total);

    final hueOffset = _rng.nextInt(360).toDouble();
    _baseColor = HSLColor.fromAHSL(1.0, hueOffset, 0.75, 0.55).toColor();

    final diffStep = max(0.04, 0.14 - difficulty * 0.02);
    _oddColor = HSLColor.fromColor(_baseColor)
        .withLightness(
          (HSLColor.fromColor(_baseColor).lightness - diffStep).clamp(0.0, 1.0),
        )
        .toColor();

    _roundSec = max(4, 9 - (widget.level ~/ 10));
    _elapsedSec = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
      if (_elapsedSec >= _roundSec) {
        _ticker?.cancel();
        widget.callbacks.onFailed('Time ran out!');
      }
    });
    setState(() {});
  }

  void _tap(int i) {
    if (i == _oddIndex) {
      HapticFeedback.lightImpact();
      _ticker?.cancel();
      if (_roundIndex == _rounds - 1) {
        widget.callbacks.onSolved();
      } else {
        setState(() => _roundIndex++);
        _startRound();
      }
    } else {
      HapticFeedback.vibrate();
      _ticker?.cancel();
      widget.callbacks.onFailed('Wrong tile!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = max(0, _roundSec - _elapsedSec);
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chip(
                icon: Icons.flag_rounded,
                color: T.daily,
                text: 'ROUND ${_roundIndex + 1}/$_rounds',
              ),
              _Chip(
                icon: Icons.timer_rounded,
                color: remaining <= 2 ? T.timeAttack : T.gold,
                text: '${remaining}s',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _gridSize * _gridSize,
              itemBuilder: (ctx, i) {
                final c = i == _oddIndex ? _oddColor : _baseColor;
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Chip({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
