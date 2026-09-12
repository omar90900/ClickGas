import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders Material icons into round map markers (e.g. the driver's truck).
class MapIcons {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> circle(
    IconData icon, {
    required Color background,
    required Color foreground,
    required double devicePixelRatio,
    double size = 44,
  }) async {
    final key = '${icon.codePoint}-${background.toARGB32()}-$devicePixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached;

    final px = size * devicePixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(px / 2, px / 2);
    canvas.drawCircle(
      center.translate(0, devicePixelRatio),
      px / 2 - devicePixelRatio,
      Paint()..color = Colors.black26,
    );
    canvas.drawCircle(center, px / 2 - devicePixelRatio, Paint()..color = background);
    canvas.drawCircle(
      center,
      px / 2 - 2 * devicePixelRatio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * devicePixelRatio
        ..color = Colors.white,
    );
    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: px * 0.56,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: foreground,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      Offset((px - painter.width) / 2, (px - painter.height) / 2),
    );
    final image =
        await recorder.endRecording().toImage(px.round(), px.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: devicePixelRatio,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}
