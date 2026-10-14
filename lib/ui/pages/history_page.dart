import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';
import '../shell.dart';

class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final h = state.history;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            PageHeader(
              title: 'تاریخچه',
              subtitle: '۱۲ اسکن آخر به‌صورت خودکار ذخیره می‌شوند',
              action: h.isEmpty
                  ? null
                  : NeonButton(
                      label: 'پاک کردن',
                      icon: Icons.delete_sweep_rounded,
                      secondary: true,
                      onTap: () => _confirmClear(context),
                    ),
            ),
            if (h.isEmpty)
              const GlassPanel(
                child: SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 32, color: AppColors.textTertiary),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'هنوز اسکنی ذخیره نشده — اولین اسکت را شروع کن',
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              for (final e in h)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _HistoryCard(
                    title: e.presetName,
                    when: e.when,
                    scanned: e.scannedCount,
                    ok: e.results.length,
                    best: e.results.isEmpty
                        ? 0
                        : e.results
                            .map((r) => r.tlsMs)
                            .reduce((a, b) => a < b ? a : b),
                    top: e.results.take(3).map((r) => r.ip).toList(),
                    onOpen: () {
                      state.restoreFromHistory(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('نتایج بازیابی شد — به تب رادار بروید'),
                        ),
                      );
                    },
                    onDelete: () => state.deleteHistory(e.id),
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('پاک کردن تاریخچه'),
          content: const Text('همهٔ رکوردهای ذخیره‌شده حذف شوند؟'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 50,
              children: [
                TextButton( onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
                  onPressed: () {
                    state.clearHistory();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حذف همه'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final DateTime when;
  final int scanned;
  final int ok;
  final int best;
  final List<String> top;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.title,
    required this.when,
    required this.scanned,
    required this.ok,
    required this.best,
    required this.top,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.accent2.withValues(alpha: 0.16),
                  border: Border.all(
                      color: AppColors.accent2.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.history_rounded,
                    size: 18, color: AppColors.accent2),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(Fmt.timeAgo(when),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'بازیابی',
                onPressed: onOpen,
                icon: const Icon(Icons.restore_rounded, size: 19),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 19, color: AppColors.bad.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: AppSpacing.md,
              children: [
                _kv('scanned', Fmt.thousands(scanned), AppColors.textSecondary),
                _kv('clean', '$ok', AppColors.good),
                _kv('best', best == 0 ? '—' : Fmt.ms(best), AppColors.accent),
              ],
            ),
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                top.join('   ·   '),
                style: monoStyle(size: 11.5, color: AppColors.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k ',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary)),
          Text(v, style: monoStyle(size: 12.5, color: c)),
        ],
      );
}
