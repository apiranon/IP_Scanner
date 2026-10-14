import 'package:flutter/material.dart';

import 'theme.dart';

class Fmt {
  Fmt._();
  static String thousands(int n) {
    final s = n.abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
  static String ms(int v) => v <= 0 ? '—' : '${thousands(v)}ms';

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'همین حالا';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    if (diff.inDays < 30) return '${diff.inDays} روز پیش';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  static String clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  static Color colorForLatency(int msValue) => msValue <= 0
      ? AppColors.bad
      : msValue <= 120
          ? AppColors.good
          : msValue <= 300
              ? AppColors.warn
              : AppColors.bad;
  static double fraction(int msValue, int maxMs) {
    if (maxMs <= 0 || msValue <= 0) return 0;
    return (msValue / maxMs).clamp(0.0, 1.0).toDouble();
  }
}
