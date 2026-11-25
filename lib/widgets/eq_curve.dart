import 'package:flutter/material.dart';

import '../theme.dart';

/// A smooth curve through the Low / Mid / High gains. It is driven by the real
/// slider values, so it reshapes as the user drags (not a fake animation).
class EqCurve extends StatelessWidget {
  final double low, mid, high;
  final double minDb, maxDb;
  final bool enabled;
  final bool compact;
  final double height;

  const EqCurve({
    super.key,
    required this.low,
    required this.mid,
    required this.high,
    required this.minDb,
    required this.maxDb,
    this.enabled = true,
    this.compact = false,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CurvePainter(low, mid, high, minDb, maxDb, enabled, compact),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final double low, mid, high, minDb, maxDb;
  final bool enabled, compact;

  _CurvePainter(this.low, this.mid, this.high, this.minDb, this.maxDb,
      this.enabled, this.compact);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final padY = compact ? 6.0 : 18.0;
    final range = (maxDb - minDb) == 0 ? 1 : (maxDb - minDb);

    double yOf(double db) =>
        h - padY - ((db - minDb) / range) * (h - 2 * padY);

    final color = enabled ? C.copper : C.muted;
    final xs = [w * 0.15, w * 0.5, w * 0.85];
    final ys = [yOf(low), yOf(mid), yOf(high)];

    // 0 dB (flat) reference line, dashed.
    if (!compact) {
      final zeroY = yOf(0);
      final dash = Paint()
        ..color = C.track
        ..strokeWidth = 1;
      for (double x = 0; x < w; x += 10) {
        canvas.drawLine(Offset(x, zeroY), Offset(x + 5, zeroY), dash);
      }
      final tp = TextPainter(
        text: const TextSpan(
          text: '0 dB',
          style: TextStyle(color: C.muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, zeroY - 14));
    }

    // Smooth path: flat lead-in, S-curves between points, flat lead-out.
    final path = Path()
      ..moveTo(0, ys[0])
      ..lineTo(xs[0], ys[0]);
    for (var i = 0; i < 2; i++) {
      final mx = (xs[i] + xs[i + 1]) / 2;
      path.cubicTo(mx, ys[i], mx, ys[i + 1], xs[i + 1], ys[i + 1]);
    }
    path.lineTo(w, ys[2]);

    // Soft fill under the curve.
    final fill = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // The curve itself.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 2 : 3
        ..strokeCap = StrokeCap.round,
    );

    // Handles at the three band positions.
    if (!compact) {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(xs[i], ys[i]), 8, Paint()..color = C.card);
        canvas.drawCircle(Offset(xs[i], ys[i]), 5, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.low != low ||
      old.mid != mid ||
      old.high != high ||
      old.minDb != minDb ||
      old.maxDb != maxDb ||
      old.enabled != enabled ||
      old.compact != compact;
}