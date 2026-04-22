import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../rando_models.dart';

class MathQuickGame extends StatefulWidget {
  final int seed;
  final int level;
  final MiniGameCallbacks callbacks;

  const MathQuickGame({
    super.key,
    required this.seed,
    required this.level,
    required this.callbacks,
  });

  @override
  State<MathQuickGame> createState() => _MathQuickGameState();
}

class _MathQuickGameState extends State<MathQuickGame> {
  static const int _totalQuestions = 6;

  late List<_MathQ> _questions;
  int _index = 0;
  int? _pressed;
  bool? _pressedCorrect;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    _questions = List.generate(_totalQuestions, (_) => _genQ(rng, widget.level));
  }

  _MathQ _genQ(Random rng, int level) {
    final ops = level >= 15
        ? ['+', '-', '×']
        : (level >= 6 ? ['+', '-', '×'] : ['+', '-']);
    final op = ops[rng.nextInt(ops.length)];
    int a, b, ans;
    switch (op) {
      case '×':
        a = 2 + rng.nextInt(9);
        b = 2 + rng.nextInt(9);
        ans = a * b;
        break;
      case '-':
        a = 5 + rng.nextInt(40);
        b = 1 + rng.nextInt(a);
        ans = a - b;
        break;
      default:
        a = 2 + rng.nextInt(30);
        b = 2 + rng.nextInt(30);
        ans = a + b;
    }
    final opts = <int>{ans};
    while (opts.length < 4) {
      final jitter = rng.nextInt(10) + 1;
      final sign = rng.nextBool() ? 1 : -1;
      final cand = ans + sign * jitter;
      if (cand >= 0 && cand != ans) opts.add(cand);
    }
    final list = opts.toList()..shuffle(rng);
    return _MathQ(a: a, b: b, op: op, answer: ans, options: list);
  }

  void _tap(int i) async {
    if (_pressed != null) return;
    final q = _questions[_index];
    final correct = q.options[i] == q.answer;
    setState(() {
      _pressed = i;
      _pressedCorrect = correct;
    });
    HapticFeedback.selectionClick();
    if (!correct) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.callbacks.onFailed('Wrong answer!');
      return;
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (_index == _questions.length - 1) {
      widget.callbacks.onSolved();
      return;
    }
    setState(() {
      _index++;
      _pressed = null;
      _pressedCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: T.daily, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Q ${_index + 1}/${_questions.length}',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF265b82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black45, offset: Offset(0, 6)),
            ],
          ),
          child: Text(
            '${q.a}  ${q.op}  ${q.b}  =  ?',
            style: GoogleFonts.luckiestGuy(
              fontSize: 42,
              color: Colors.white,
              letterSpacing: 2,
              shadows: const [
                Shadow(color: Colors.black, offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.9,
            children: List.generate(q.options.length, (i) {
              Color bg = const Color(0xFF38B6FF);
              if (_pressed == i) {
                bg = (_pressedCorrect ?? false)
                    ? const Color(0xFF3ba629)
                    : const Color(0xFFFF5757);
              }
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        '${q.options[i]}',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 30,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _MathQ {
  final int a;
  final int b;
  final String op;
  final int answer;
  final List<int> options;
  _MathQ({
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
    required this.options,
  });
}
