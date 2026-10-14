import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/colo_geo.dart';
import '../core/earth.dart';
import '../core/theme.dart';

class RadarOrb extends StatefulWidget {
  final bool active;
  final double fraction;
  final Map<String, int> coloCounts;
  final VoidCallback? onTap;

  const RadarOrb({
    super.key,
    required this.active,
    required this.fraction,
    required this.coloCounts,
    this.onTap,
  });

  @override
  State<RadarOrb> createState() => _RadarOrbState();
}

class _RadarOrbState extends State<RadarOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.active
        ? const Duration(seconds: 10)
        : const Duration(seconds: 24);
    if (_spin.duration != dur) {
      _spin.duration = dur;
      _spin.repeat();
    }

    return Center(
      child: SizedBox.fromSize(
        size: const Size(320, 260),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, _) {
              return CustomPaint(
                painter: _GlobePainter(
                  angle: _spin.value * 2 * math.pi,
                  fraction: widget.fraction,
                  coloCounts: widget.coloCounts,
                  active: widget.active,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Proj {
  final double x; 
  final double y;
  final double z;

  const _Proj(this.x, this.y, this.z);

  bool get front => z > 0;
}

class _Star {
  final double lat;
  final double lon; 
  final double w;

  const _Star(this.lat, this.lon, this.w);
}

class _GlobePainter extends CustomPainter {
  final double angle;
  final double fraction;
  final Map<String, int> coloCounts;
  final bool active;

  _GlobePainter({
    required this.angle,
    required this.fraction,
    required this.coloCounts,
    required this.active,
  });

  static const double _tilt = -0.20;
  static final double _cosT = math.cos(_tilt);
  static final double _sinT = math.sin(_tilt);

  _Proj _p(double lat, double lon) {
    final cl = math.cos(lat);
    final lp = lon + angle;
    final x = cl * math.sin(lp);
    final y = math.sin(lat);
    final z = cl * math.cos(lp);
    final y2 = y * _cosT - z * _sinT;
    final z2 = y * _sinT + z * _cosT;
    return _Proj(x, y2, z2);
  }

  List<_Star> _stars() {
    if (coloCounts.isEmpty) return const [];
    var maxN = 1;
    for (final n in coloCounts.values) {
      if (n > maxN) maxN = n;
    }
    final out = <_Star>[];
    for (final e in coloCounts.entries) {
      final g = coloGeo(e.key);
      if (g == null) continue;
      out.add(_Star(
        g.$1 * math.pi / 180.0,
        g.$2 * math.pi / 180.0,
        math.sqrt(e.value / maxN),
      ));
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) * 0.42;
    final tone = active ? AppColors.accent : AppColors.bad;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: active ? 0.14 : 0.12),
          tone.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.72, 0.86, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: R * 1.42));
    canvas.drawCircle(c, R * 1.42, halo);

    final ocean = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [
          const Color(0xFF14304D).withValues(alpha: 0.92),
          const Color(0xFF0C1F38).withValues(alpha: 0.95),
          const Color(0xFF060E1E).withValues(alpha: 0.98),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: R));
    canvas.drawCircle(c, R, ocean);
    final glow = Paint()
      ..color = tone.withValues(alpha: 0.0675)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);

    final glowPath = Path();
    final frontPath = Path();
    final backPath = Path();
    for (final v in EarthPoints.land) {
      final p = _p(v.lat, v.lon);
      final o = Offset(c.dx + p.x * R, c.dy - p.y * R);
      if (p.front) {
        glowPath.addOval(Rect.fromCircle(center: o, radius: v.v * 1.9));
        // ×۲٫۶ — دایره‌ها روی هم می‌افتند و شکاف گرید را می‌پوشانند.
        frontPath.addOval(Rect.fromCircle(center: o, radius: v.v * 2.6));
      } else {
        backPath.addOval(Rect.fromCircle(center: o, radius: 1.6));
      }
    }

    void drawHemisphere(Path land, double alpha) {
      canvas.saveLayer(null, Paint());
      canvas.drawPath(land, Paint()..color = Colors.white);
      canvas.drawPaint(Paint()
        ..blendMode = BlendMode.srcIn
        ..color = tone.withValues(alpha: alpha));
      canvas.restore();
    }

    drawHemisphere(backPath, 0.09);
    canvas.drawPath(glowPath, glow);
    drawHemisphere(frontPath, 0.27);
    final coastTone = active ? Colors.white : AppColors.bad;
    final edge = Paint()..color = coastTone.withValues(alpha: 0.26);
    final edgeBack = Paint()..color = coastTone.withValues(alpha: 0.05);
    final coastF = Path();
    final coastB = Path();
    for (final v in EarthPoints.coast) {
      final p = _p(v.lat, v.lon);
      final o = Offset(c.dx + p.x * R, c.dy - p.y * R);
      (p.front ? coastF : coastB)
          .addOval(Rect.fromCircle(center: o, radius: 0.9));
    }
    canvas.drawPath(coastB, edgeBack);
    canvas.drawPath(coastF, edge);

    if (active && coloCounts.isNotEmpty) {
      final stars = _stars();
      final twinkle = 1.0 + 0.18 * math.sin(angle * 5.0);
      final corePaint = Paint();
      final starHalo = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6);
      for (final s in stars) {
        final p = _p(s.lat, s.lon);
        if (p.z < 0.14) continue; 
        final px = c.dx + p.x * R;
        final py = c.dy - p.y * R;
        final depth = p.z;
        final a = ((0.45 + 0.55 * depth) * twinkle * (0.55 + 0.45 * s.w))
            .clamp(0.0, 1.0);
        starHalo.color = AppColors.good.withValues(alpha: a * 0.55);
        canvas.drawCircle(
            Offset(px, py), 2.4 + depth * 1.4 + s.w * 2.2, starHalo);
        corePaint.color = Colors.white.withValues(alpha: a);
        canvas.drawCircle(
            Offset(px, py), 0.9 + depth * 0.9 + s.w * 1.4, corePaint);
      }
    }

    final night = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, 0.55),
        colors: [
          const Color(0xFF02060F).withValues(alpha: 0.60),
          const Color(0xFF02060F).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.85],
      ).createShader(Rect.fromCircle(center: c, radius: R));
    canvas.drawCircle(c, R, night);

    final glossC = Offset(c.dx - R * 0.34, c.dy - R * 0.38);
    final gloss = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 0.9],
      ).createShader(Rect.fromCircle(center: glossC, radius: R * 0.55));
    canvas.drawCircle(glossC, R * 0.55, gloss);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = SweepGradient(
        colors: active
            ? [
                AppColors.accent.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.06),
                AppColors.accent2.withValues(alpha: 0.45),
                AppColors.accent.withValues(alpha: 0.55),
              ]
            : [
                AppColors.bad.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.06),
                AppColors.bad.withValues(alpha: 0.40),
                AppColors.bad.withValues(alpha: 0.55),
              ],
      ).createShader(Rect.fromCircle(center: c, radius: R));
    canvas.drawCircle(c, R - 0.65, rim);

    if (fraction > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accent;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: R * 1.12),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      old.angle != angle ||
      old.fraction != fraction ||
      old.active != active ||
      !_sameCounts(old.coloCounts, coloCounts);

  static bool _sameCounts(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
