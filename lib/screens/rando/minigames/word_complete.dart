import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../rando_models.dart';

class WordCompleteGame extends StatefulWidget {
  final int seed;
  final int level;
  final MiniGameCallbacks callbacks;

  const WordCompleteGame({
    super.key,
    required this.seed,
    required this.level,
    required this.callbacks,
  });

  @override
  State<WordCompleteGame> createState() => _WordCompleteGameState();
}

class _WordCompleteGameState extends State<WordCompleteGame> {
  static const List<String> _words = [
    'APPLE', 'HOUSE', 'MUSIC', 'PLANT', 'CLOUD', 'STORM', 'RIVER',
    'BEACH', 'TIGER', 'MANGO', 'BRICK', 'PRIZE', 'CHAIR', 'CANDY',
    'HONEY', 'PIZZA', 'PAPER', 'LEMON', 'SMILE', 'GHOST', 'ROBOT',
    'SUGAR', 'WATER', 'LIGHT', 'CRANE', 'ZEBRA', 'NOVEL', 'PEARL',
    'TRAIN', 'OCEAN',
  ];

  late List<_Round> _rounds;
  int _round = 0;
  int _wrong = 0;
  late int _maxWrong;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    final pool = List<String>.from(_words)..shuffle(rng);
    final rounds = <_Round>[];
    final total = 5;
    for (int i = 0; i < total; i++) {
      final word = pool[i % pool.length];
      // Hide 1 letter on easy levels, 2 letters on higher
      final holes = widget.level >= 10 ? 2 : 1;
      final idxs = <int>{};
      while (idxs.length < holes) {
        idxs.add(rng.nextInt(word.length));
      }
      rounds.add(_Round.build(word, idxs.toList()..sort(), rng));
    }
    _rounds = rounds;
    _maxWrong = 3;
  }

  void _onTapLetter(String letter) {
    if (!mounted) return;
    final r = _rounds[_round];
    final need = r.missing[r.filled.length];
    if (letter == need) {
      HapticFeedback.lightImpact();
      setState(() => r.filled.add(letter));
      if (r.filled.length == r.missing.length) {
        // Round done
        if (_round == _rounds.length - 1) {
          widget.callbacks.onSolved();
        } else {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            setState(() => _round++);
          });
        }
      }
    } else {
      HapticFeedback.vibrate();
      setState(() => _wrong++);
      if (_wrong >= _maxWrong) {
        widget.callbacks.onFailed('Too many wrong guesses!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _rounds[_round];
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
                text: 'WORD ${_round + 1}/${_rounds.length}',
              ),
              _Chip(
                icon: Icons.heart_broken_rounded,
                color: T.timeAttack,
                text: '${_maxWrong - _wrong}',
              ),
            ],
          ),
        ),
        const Spacer(),
        // The word display
        _WordDisplay(
          letters: List.generate(r.word.length, (i) {
            if (!r.holes.contains(i)) return r.word[i];
            final idx = r.holes.indexOf(i);
            if (idx < r.filled.length) return r.filled[idx];
            return null;
          }),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: r.options
                .map((c) => _LetterButton(letter: c, onTap: () => _onTapLetter(c)))
                .toList(),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Round {
  final String word;
  final List<int> holes; // indices into word
  final List<String> missing; // the correct letters to fill, in order
  final List<String> options; // letter choices to tap
  final List<String> filled = [];

  _Round({
    required this.word,
    required this.holes,
    required this.missing,
    required this.options,
  });

  factory _Round.build(String word, List<int> holes, Random rng) {
    final missing = holes.map((i) => word[i]).toList();
    final letters = <String>{...missing};
    const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (letters.length < 6) {
      letters.add(abc[rng.nextInt(abc.length)]);
    }
    final opts = letters.toList()..shuffle(rng);
    return _Round(word: word, holes: holes, missing: missing, options: opts);
  }
}

class _WordDisplay extends StatelessWidget {
  final List<String?> letters;
  const _WordDisplay({required this.letters});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final l in letters)
          Container(
            width: 48,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: l == null
                    ? const Color(0xFF265b82)
                    : const Color(0xFFFFDE59),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  l ?? '_',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 30,
                    color: l == null ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LetterButton extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  const _LetterButton({required this.letter, required this.onTap});

  @override
  State<_LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<_LetterButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF38B6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Center(
              child: Text(
                widget.letter,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 24,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black54, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
