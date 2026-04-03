import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';

// Run with: dart run tool/generate_icon.dart
// Requires flutter (dart from flutter SDK)

Future<void> main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 1024.0;

  final bgPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(size, size),
      [const Color(0xFF0A0D2E), const Color(0xFF050714)],
    );

  // Background rounded rect
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, size, size), const Radius.circular(200)),
    bgPaint,
  );

  const pad = 108.0;
  const gap = 36.0;
  const cell = (size - 2 * pad - 2 * gap) / 3;
  const r = Radius.circular(44);

  final gridColors = <Color?>[
    null,
    const Color(0xFF818CF8),
    const Color(0xFF6366F1),
    const Color(0xFF6366F1),
    const Color(0xFF4F8EF7),
    const Color(0xFF34D399),
    const Color(0xFF34D399),
    const Color(0xFF10B981),
    const Color(0xFF10B981),
  ];

  for (int i = 0; i < 9; i++) {
    final row = i ~/ 3;
    final col = i % 3;
    final x = pad + col * (cell + gap);
    final y = pad + row * (cell + gap);
    final rect = Rect.fromLTWH(x, y, cell, cell);
    final rrect = RRect.fromRectAndRadius(rect, r);
    final c = gridColors[i];

    if (c == null) {
      // Empty slot
      canvas.drawRRect(
          rrect,
          Paint()
            ..color = const Color(0xFF0D1130)
            ..style = PaintingStyle.fill);
      canvas.drawRRect(
          rrect,
          Paint()
            ..color = const Color(0x22FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    } else {
      // Colored tile
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, y),
            Offset(x + cell, y + cell),
            [
              Color.lerp(c, Colors.white, 0.25)!,
              c,
            ],
          )
          ..style = PaintingStyle.fill,
      );
      // Glow effect
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = c.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
      );
      // Specular highlight
      canvas.drawOval(
        Rect.fromLTWH(x + cell * 0.12, y + cell * 0.1, cell * 0.55,
            cell * 0.3),
        Paint()..color = const Color(0x20FFFFFF),
      );
    }
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final outDir = Directory('assets/icon');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(bytes);
  print('✅ Icon written to assets/icon/icon.png (${bytes.length} bytes)');
}
