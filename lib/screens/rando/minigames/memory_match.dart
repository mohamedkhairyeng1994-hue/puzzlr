import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../rando_models.dart';

class MemoryMatchGame extends StatefulWidget {
  final int seed;
  final int level;
  final MiniGameCallbacks callbacks;

  const MemoryMatchGame({
    super.key,
    required this.seed,
    required this.level,
    required this.callbacks,
  });

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const List<IconData> _pool = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.bolt_rounded,
    Icons.pets_rounded,
    Icons.cake_rounded,
    Icons.local_fire_department_rounded,
    Icons.ac_unit_rounded,
    Icons.brightness_5_rounded,
    Icons.emoji_emotions_rounded,
    Icons.music_note_rounded,
    Icons.rocket_launch_rounded,
    Icons.eco_rounded,
  ];

  late List<IconData> _cards;
  final Set<int> _matched = {};
  final List<int> _flipped = [];
  int _tries = 0;
  int _maxTries = 18;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    // 4x4 = 16 tiles, 8 pairs
    final chosen = List<IconData>.from(_pool)..shuffle(rng);
    final pairs = chosen.take(8).toList();
    _cards = [...pairs, ...pairs]..shuffle(rng);

    // Slightly tighter on higher levels
    _maxTries = max(12, 20 - (widget.level ~/ 6));
  }

  void _onTap(int i) {
    if (_locked || _matched.contains(i) || _flipped.contains(i)) return;

    HapticFeedback.selectionClick();
    setState(() => _flipped.add(i));

    if (_flipped.length == 2) {
      _tries++;
      final a = _flipped[0];
      final b = _flipped[1];
      if (_cards[a] == _cards[b]) {
        _matched.addAll([a, b]);
        _flipped.clear();
        if (_matched.length == _cards.length) {
          widget.callbacks.onSolved();
          return;
        }
      } else {
        _locked = true;
        Timer(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          setState(() {
            _flipped.clear();
            _locked = false;
          });
          if (_tries >= _maxTries) {
            widget.callbacks.onFailed('Out of tries!');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.touch_app_rounded,
                color: T.duel,
                label: 'TRIES',
                value: '${_maxTries - _tries}',
              ),
              _StatChip(
                icon: Icons.star_rounded,
                color: T.daily,
                label: 'PAIRS',
                value: '${_matched.length ~/ 2}/${_cards.length ~/ 2}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _cards.length,
              itemBuilder: (ctx, i) {
                final isFaceUp = _matched.contains(i) || _flipped.contains(i);
                final isMatched = _matched.contains(i);
                return _MemCard(
                  icon: _cards[i],
                  faceUp: isFaceUp,
                  matched: isMatched,
                  onTap: () => _onTap(i),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MemCard extends StatelessWidget {
  final IconData icon;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  const _MemCard({
    required this.icon,
    required this.faceUp,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(0, 4)),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: matched
                ? const Color(0xFF3ba629)
                : (faceUp ? const Color(0xFFFFDE59) : const Color(0xFF265b82)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: Center(
            child: faceUp
                ? Icon(
                    icon,
                    size: 34,
                    color: matched ? Colors.white : Colors.black87,
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

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
            '$label $value',
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
