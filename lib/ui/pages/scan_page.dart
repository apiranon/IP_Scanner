import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/colo.dart';
import '../../core/file_export.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/glass.dart';
import '../../widgets/radar_orb.dart';
import '../shell.dart';

class ScanPage extends StatelessWidget {
  final AppState state;
  const ScanPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'رادار IP',
          subtitle: 'یافتن IPهای تمیز کلودفلر با سنجش تأخیر TCP/TLS',
          logo: true,
        ),
        _ControlCard(state: state),
        const SizedBox(height: AppSpacing.lg),
        _StatsRow(state: state),
        const SizedBox(height: AppSpacing.lg),
        _ResultsCard(state: state),
        const SizedBox(height: AppSpacing.lg),
        _InsightsRow(state: state),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _ControlCard extends StatelessWidget {
  final AppState state;
  const _ControlCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final fraction = state.progressTotal == 0
        ? 0.0
        : (state.progressDone / state.progressTotal).clamp(0.0, 1.0).toDouble();
    final p = state.selectedPreset;

    final coloCounts = <String, int>{};
    for (final r in state.currentResults) {
      if (r.colo.isEmpty) continue;
      coloCounts[r.colo] = (coloCounts[r.colo] ?? 0) + 1;
    }

    return GlassPanel(
      glow: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'پیش‌ تنظیم: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: DropdownButton<String>(
                  value: p.id,
                  isDense: true,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.cardDeep,
                  menuMaxHeight: 320,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  items: [
                    for (final e in state.presets)
                      DropdownMenuItem(alignment: AlignmentGeometry.center,value: e.id, child: Text(e.name)),
                  ],
                  onChanged: state.scanning
                      ? null
                      : (v) {
                          if (v != null) state.selectPreset(v);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RadarOrb(
            active: state.scanning,
            fraction: state.scanning ? fraction : 0.0,
            coloCounts: coloCounts,
            onTap: state.scanning ? state.requestCancel : state.startScan,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.scanning ? 'برای توقف روی کره بزنید' : 'برای شروع روی کره بزنید',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressLine(state: state, fraction: fraction),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final AppState state;
  final double fraction;
  const _ProgressLine({required this.state, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final elapsed = state.scanStarted == null
        ? null
        : (state.scanFinished ?? DateTime.now())
            .difference(state.scanStarted!)
            .inMilliseconds;
    final rate = (elapsed != null && elapsed > 300 && state.progressDone > 0)
        ? state.progressDone * 1000 ~/ elapsed
        : 0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.cardDeep2,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            children: [
              _mini('scanned', Fmt.thousands(state.progressDone)),
              _mini('clean', '${state.progressOk}',
                  color: AppColors.good),
              if (rate > 0) _mini('ip/sec', '$rate'),
              if (elapsed != null)
                _mini('elapsed',
                    '${(elapsed / 1000).toStringAsFixed(1)}s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mini(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$k ',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textTertiary)),
            Text(v,
                style: monoStyle(
                    size: 13, color: color ?? AppColors.accent)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AppState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final best = state.currentResults.isEmpty
        ? 0
        : state.currentResults.first.tlsMs;
    final avg = state.currentResults.isEmpty
        ? 0
        : state.currentResults.fold<int>(0, (s, r) => s + r.tlsMs) ~/
            state.currentResults.length;
    final colos = <String>{
      for (final r in state.currentResults)
        if (r.colo.isNotEmpty) r.colo
    }.length;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 640 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        StatChip(
          value: state.progressOk.toString(),
          label: 'تمیز IP',
          color: AppColors.good,
          icon: Icons.wb_sunny_rounded,
        ),
        StatChip(
          value: best == 0 ? '—' : Fmt.ms(best),
          label: 'سریع‌ترین',
          color: AppColors.accent,
          icon: Icons.bolt_rounded,
        ),
        StatChip(
          value: avg == 0 ? '—' : Fmt.ms(avg),
          label: 'میانگین',
          color: AppColors.warn,
          icon: Icons.speed_rounded,
        ),
        StatChip(
          value: '$colos',
          label: 'دیتاسنتر',
          color: AppColors.accent2,
          icon: Icons.location_city_rounded,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _ResultsCard extends StatelessWidget {
  final AppState state;
  const _ResultsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.currentResults.take(state.settings.topN).toList();

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: 'IPهای تمیز',
            hint: state.currentResults.isEmpty
                ? null
                : 'نمایش ${list.length} از ${state.currentResults.length}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'کپی بدون پورت',
                  onPressed: list.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: state.exportText(withPort: false)));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('IPها بدون پورت کپی شد')),
                            );
                          }
                        },
                  icon: const Icon(Icons.dialpad_rounded, size: 19),
                ),
                IconButton(
                  tooltip: 'کپی همه',
                  onPressed: list.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: state.exportText()));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('لیست کپی شد'))
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_rounded, size: 19),
                ),
                IconButton(
                  tooltip: 'خروجی فایل',
                  onPressed: list.isEmpty
                      ? null
                      : () => _saveAsDialog(context, state),
                  icon: const Icon(Icons.download_rounded, size: 19),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ErrorBox(message: state.lastError!),
            ),
          if (list.isEmpty && !state.scanning && state.lastError == null)
            const _EmptyHint()
          else if (list.isEmpty && state.scanning)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'در حال جست‌وجو…',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                itemCount: list.length,
                itemBuilder: (context, i) =>
                    ResultTile(r: list[i], rank: i + 1, showColoFa: state.settings.showColoNames, ceilingMs: state.selectedPreset.latencyCeilingMs),
              ),
            ),
        ],
      ),
    );
  }


  Future<void> _saveAsDialog(BuildContext context, AppState state) async {
    final withPort = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروجی فایل'),
        content: const Text('لیست IPها با چه فرمتی ذخیره شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('بدون پورت'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('با پورت'),
          ),
        ],
      ),
    );
    if (withPort == null || !context.mounted) return; 
    await _saveToFile(context, state, withPort: withPort);
  }

  Future<void> _saveToFile(
    BuildContext context,
    AppState state, {
    required bool withPort,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await saveTextFile(
      text: state.exportText(onlyTop: false, withPort: withPort),
      suggestedName: 'ip_list_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            path == null ? 'ذخیره‌سازی انجام نشد' : 'ذخیره شد: $path'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bad.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.bad.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.bad, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.bad, fontSize: 12.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_tethering_rounded,
              size: 30, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.sm),
          Text(
            'کره را لمس کنید تا IPهای تمیز پیدا شوند',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class ResultTile extends StatelessWidget {
  final ScanResult r;
  final int rank;
  final bool showColoFa;
  final int ceilingMs;

  static final double _ipW = () {
    final tp = TextPainter(
      text: TextSpan(
          text: '000.000.000.000:000000', style: monoStyle(size: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width.ceilToDouble();
    tp.dispose();
    return w;
  }();

  const ResultTile(
      {super.key,
      required this.r,
      required this.rank,
      this.showColoFa = true,
      this.ceilingMs = 1500});

  @override
  Widget build(BuildContext context) {
    final latencyColor = Fmt.colorForLatency(r.tlsMs);
    final colo = r.colo;
    final coloText = colo.isEmpty
        ? '—'
        : (showColoFa && isKnownColo(colo)
            ? '$colo · ${coloFa(colo)}'
            : colo);

    final underCeiling = ceilingMs <= 0 || r.tlsMs <= ceilingMs;
    final wide = MediaQuery.of(context).size.width >= 680;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: rank <= 3
              ? AppColors.accent.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: rank == 1
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: monoStyle(
                  size: 12,
                  color: rank <= 3 ? AppColors.accent : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (wide)
              InkWell(
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: '${r.ip}:${r.port}'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${r.ip}:${r.port} کپی شد'),
                          duration: const Duration(seconds: 1)),
                    );
                  }
                },
                child: SizedBox(
                  width: _ipW,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${r.ip}:${r.port}',
                      overflow: TextOverflow.ellipsis,
                      style: monoStyle(size: 14),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: '${r.ip}:${r.port}'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${r.ip}:${r.port} کپی شد'),
                            duration: const Duration(seconds: 1)),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${r.ip}:${r.port}',
                          overflow: TextOverflow.ellipsis,
                          style: monoStyle(size: 14),
                        ),
                      ),
                      Text(
                        coloText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            if (wide) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: underCeiling
                    ? 'تمیز ناب — زیر سقف ${ceilingMs}ms'
                    : 'کارا ولی کند — بالای سقف ${ceilingMs}ms',
                child: Icon(
                  underCeiling
                      ? Icons.verified_rounded
                      : Icons.timelapse_rounded,
                  size: 16,
                  color: underCeiling ? AppColors.good : AppColors.warn,
                ),
              ),
              if (!r.certOk) ...[
                const SizedBox(width: 4),
                const Tooltip(
                  message: 'SAN گواهی این دامنه را نداشت',
                  child: Icon(Icons.gpp_bad_outlined,
                      size: 16, color: AppColors.warn),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 155,
                child: Text(
                  coloText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),

              const Spacer(),
            ],

            if (!wide) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: underCeiling
                    ? 'تمیز ناب — زیر سقف ${ceilingMs}ms'
                    : 'کارا ولی کند — بالای سقف ${ceilingMs}ms',
                child: Icon(
                  underCeiling
                      ? Icons.verified_rounded
                      : Icons.timelapse_rounded,
                  size: 16,
                  color: underCeiling ? AppColors.good : AppColors.warn,
                ),
              ),
              if (!r.certOk) ...[
                const SizedBox(width: 4),
                const Tooltip(
                  message: 'SAN گواهی این دامنه را نداشت',
                  child: Icon(Icons.gpp_bad_outlined,
                      size: 16, color: AppColors.warn),
                ),
              ],
            ],

            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 58,
              child: Text(
                Fmt.ms(r.tlsMs),
                textAlign: TextAlign.end,
                style: monoStyle(size: 13, color: latencyColor),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'کپی',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: r.ip));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${r.ip} کپی شد'),
                        duration: const Duration(seconds: 1)),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded,
                  size: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _InsightsRow extends StatelessWidget {
  final AppState state;
  const _InsightsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final res = state.currentResults;
    if (res.isEmpty) return const SizedBox.shrink();

    // توزیع colo
    final counts = <String, int>{};
    for (final r in res) {
      counts[r.colo] = (counts[r.colo] ?? 0) + 1;
    }
    final coloList = counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    final bars = res
        .take(8)
        .map((e) => ('${e.ip}:${e.port}', e.tlsMs))
        .toList();
    final radarVals = res
        .take(6)
        .map((e) => e.tlsMs)
        .toList();

    return Column(
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                  title: 'تأخیر بهترین‌ها', hint: 'هرچه کوتاه‌تر، بهتر'),
              const SizedBox(height: AppSpacing.md),
              LatencyBars(items: bars, maxMs: 800),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                  title: 'دیتاسنترها', hint: 'کدام IPها کجا سرو می‌شوند'),
              const SizedBox(height: AppSpacing.md),
              ColoDonut(entries: coloList),
              const SizedBox(height: AppSpacing.md),
              if (radarVals.length >= 3)
                LatencyRadarChart(msValues: radarVals),
            ],
          ),
        ),
      ],
    );
  }
}
