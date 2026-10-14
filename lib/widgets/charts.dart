import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/colo.dart';
import '../core/format.dart';
import '../core/theme.dart';
import 'glass.dart';

class LatencyBars extends StatelessWidget {
  final List<(String, int)> items; // (ip:port, ms)
  final int maxMs;
  final int? highlightedMs;

  const LatencyBars({
    super.key,
    required this.items,
    required this.maxMs,
    this.highlightedMs,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final max = maxMs > 0 ? maxMs : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (ip, ms) in items.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 128,
                  child: Text(
                    ip,
                    style: monoStyle(size: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.cardDeep2,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: Fmt.fraction(ms, max),
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            gradient: LinearGradient(
                              colors: [
                                Fmt.colorForLatency(ms).withValues(alpha: 0.95),
                                Fmt.colorForLatency(ms).withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 62,
                  child: Text(
                    Fmt.ms(ms),
                    textAlign: TextAlign.end,
                    style: monoStyle(
                        size: 12, color: Fmt.colorForLatency(ms)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LatencyRadarChart extends StatelessWidget {
  final List<int> msValues; // بهترین‌ها
  final String centerLabel;

  const LatencyRadarChart({
    super.key,
    required this.msValues,
    this.centerLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarChartPainter(msValues),
      child: const SizedBox(width: double.infinity, height: 180),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<int> values;
  _RadarChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.42;
    const maxVal = 800.0; // ms سقف مقیاس

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var ring = 1; ring <= 3; ring++) {
      final rr = r * ring / 3;
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final a = (i * 60 - 90) * math.pi / 180;
        final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }

    final n = math.min(6, values.length);
    if (n < 3) return;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final a = (i * 60 - 90) * math.pi / 180;
      final frac = (values[i] / maxVal).clamp(0.05, 1.0);
      final rr = r * frac;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.accent.withValues(alpha: 0.55),
          AppColors.accent2.withValues(alpha: 0.18),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.accent.withValues(alpha: 0.9)
        ..strokeWidth = 2,
    );

    for (var i = 0; i < n; i++) {
      final a = (i * 60 - 90) * math.pi / 180;
      final frac = (values[i] / maxVal).clamp(0.05, 1.0);
      final rr = r * frac;
      canvas.drawCircle(
        Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a)),
        3,
        Paint()..color = AppColors.good,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) => old.values != values;
}

class ColoDonut extends StatelessWidget {
  final List<(String, int)> entries; // (colo, count) مرتب‌شده
  final VoidCallback? onTap;

  const ColoDonut({super.key, required this.entries, this.onTap});

  static const _palette = [
    AppColors.accent,
    AppColors.accent2,
    AppColors.accent3,
    AppColors.good,
    AppColors.warn,
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold<int>(0, (s, e) => s + e.$2);
    if (total == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(painter: _DonutPainter(entries, total)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < entries.length && i < 6; i++)
                  _legend(entries[i].$1, entries[i].$2, total, _palette[i]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String colo, int count, int total, Color color) {
    final pct = (count * 100 / total).round();
    final chip = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(colo.isEmpty ? '—' : colo,
              style: monoStyle(size: 12, color: color)),
          const SizedBox(width: 6),
          Text('$pct٪',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
    if (colo.isEmpty) return chip;
    final city = coloCity(colo);
    final fa = coloFa(colo);
    final msg = isKnownColo(colo)
        ? '$colo — $fa ($city)'
        : '$colo — کد دیتاسنتر ناشناخته';
    return Tooltip(
      message: msg,
      waitDuration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.cardDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      textStyle: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
      child: chip,
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(String, int)> entries;
  final int total;
  _DonutPainter(this.entries, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final rect = Rect.fromCircle(center: c, radius: r);
    var start = -math.pi / 2;
    for (var i = 0; i < entries.length && i < 6; i++) {
      final frac = entries[i].$2 / total;
      final sweep = 2 * math.pi * frac;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt
        ..color = ColoDonut._palette[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
    // هستهٔ تیره — حس سه‌بعدی
    canvas.drawCircle(c, r - 12, Paint()..color = AppColors.bg);
    canvas.drawCircle(
      Offset(c.dx - 2, c.dy - 2),
      r - 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.entries != entries || old.total != total;
}
