import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_theme.dart';

/// Launch screen: a customer in the middle, distributors drifting around them
/// on a web of lines, with signals travelling in along each line.
///
/// Every instance reads the same clock, so the boot screen and the sign-in
/// check that follows it show the same frame and hand over without a jump.
class ConnectingSplash extends StatelessWidget {
  const ConnectingSplash({super.key, this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      body: Stack(
        children: [
          const Center(child: SizedBox.square(dimension: 260, child: _Web())),
          // Below the animation, so the animation doesn't move when text appears.
          Align(
            alignment: const Alignment(0, 0.52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.textTheme.bodyLarge?.copyWith(color: muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Web extends StatefulWidget {
  const _Web();

  @override
  State<_Web> createState() => _WebState();
}

class _WebState extends State<_Web> with SingleTickerProviderStateMixin {
  static final _clock = Stopwatch()..start();
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _time.value = _seconds;
    _ticker = createTicker((_) => _time.value = _seconds)..start();
  }

  double get _seconds => _clock.elapsedMicroseconds / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _WebPainter(
        time: _time,
        brand: AppColors.brand,
        ink: dark ? AppColors.brand : AppColors.brandDeep,
        node: dark ? AppColors.darkCard : AppColors.lightCard,
        line: dark ? AppColors.darkOutline : AppColors.lightOutline,
      ),
    );
  }
}

class _WebPainter extends CustomPainter {
  _WebPainter({
    required this.time,
    required this.brand,
    required this.ink,
    required this.node,
    required this.line,
  }) : super(repaint: time);

  final ValueListenable<double> time;
  final Color brand;
  final Color ink;
  final Color node;
  final Color line;

  static const _count = 6;

  Offset _nodeAt(Offset center, double radius, double t, int i) {
    final angle = -math.pi / 2 + i * 2 * math.pi / _count + t * 0.22;
    final r = radius * (1 + 0.06 * math.sin(t * 1.5 + i * 1.3));
    return center + Offset(math.cos(angle), math.sin(angle)) * r;
  }

  void _icon(Canvas canvas, IconData icon, Offset at, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final nodes = [for (var i = 0; i < _count; i++) _nodeAt(center, radius, t, i)];

    // Pulses spreading from the customer.
    for (var k = 0; k < 2; k++) {
      final p = (t * 0.45 + k * 0.5) % 1.0;
      canvas.drawCircle(
        center,
        radius * (0.3 + 0.75 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = brand.withValues(alpha: (1 - p) * 0.28),
      );
    }

    // The web between distributors.
    final web = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = line;
    for (var i = 0; i < _count; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 1) % _count], web);
      canvas.drawLine(nodes[i], nodes[(i + 2) % _count], web..color = line.withValues(alpha: 0.5));
      web.color = line;
    }

    // Each distributor linked to the customer, a signal travelling in.
    for (var i = 0; i < _count; i++) {
      final p = (t * 0.55 + i / _count) % 1.0;
      canvas.drawLine(
        nodes[i],
        center,
        Paint()
          ..strokeWidth = 1.8
          ..color = brand.withValues(alpha: 0.22 + 0.4 * (1 - p)),
      );
      final signal = Offset.lerp(nodes[i], center, Curves.easeIn.transform(p))!;
      canvas.drawCircle(signal, 3.4, Paint()..color = brand.withValues(alpha: 1 - 0.7 * p));
    }

    // Distributors.
    final nodeRadius = size.shortestSide * 0.075;
    for (final n in nodes) {
      canvas.drawCircle(n, nodeRadius, Paint()..color = node);
      canvas.drawCircle(
        n,
        nodeRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = brand,
      );
      _icon(canvas, Icons.local_shipping_rounded, n, nodeRadius * 1.1, ink);
    }

    // The customer.
    final beat = 1 + 0.05 * math.sin(t * 3);
    final customerRadius = size.shortestSide * 0.13 * beat;
    canvas.drawCircle(center, customerRadius, Paint()..color = brand);
    _icon(canvas, Icons.person_rounded, center, customerRadius * 1.25, AppColors.onBrand);
  }

  @override
  bool shouldRepaint(_WebPainter old) =>
      old.brand != brand || old.ink != ink || old.node != node || old.line != line;
}
