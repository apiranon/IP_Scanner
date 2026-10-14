import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/cf_ranges.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';
import '../../widgets/range_picker.dart';
import '../shell.dart';
import 'presets_page.dart';

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  Future<void> _openPicker(BuildContext context) async {
    final res = await RangePickerPage.show(
        context, state.settings.selectedRanges);
    if (res != null) {
      state.updateSettings(state.settings.copyWith(selectedRanges: res));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final sel = state.settings.selectedRanges;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const PageHeader(
              title: 'تنظیمات اسکنر',
              subtitle: 'پیش‌تنظیم‌ها، نمایش نتایج و بازه‌های اسکن',
            ),
            PresetsSection(state: state),
            const SizedBox(height: AppSpacing.lg),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(title: 'نمایش'),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نام فارسی دیتاسنترها',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                        'کد colo همراه نام شهر به فارسی نشان داده می‌شود',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    value: state.settings.showColoNames,
                    onChanged: (v) => state.updateSettings(
                        state.settings.copyWith(showColoNames: v)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('حداکثر نتایج نمایشی',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text('الان: ${state.settings.topN} ردیف',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    trailing: SizedBox(
                      width: 240,
                      child: Slider(
                        min: 20,
                        max: 10000,
                        divisions: 499, // گام ۲۰تایی: ۲۰ تا ۱۰٬۰۰۰
                        value: state.settings.topN.toDouble().clamp(20, 10000),
                        label: '${state.settings.topN}',
                        onChanged: (v) => state.updateSettings(
                            state.settings.copyWith(
                                topN: v.round().clamp(20, 10000).toInt())),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── انتخاب رنج‌ها ────────────────────────────────────
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    title: 'رنج‌های اسکن',
                    hint: '${CfRanges.wide.length} رنج قابل انتخاب',
                    trailing: GestureDetector(
                      onTap: () => _openPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: AppColors.accentGradient,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded,
                                size: 15, color: Color(0xFF04121A)),
                            SizedBox(width: 5),
                            Text('انتخاب',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF04121A))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (sel.isEmpty)
                    const Text(
                      'هیچ رنج اضافه‌ای انتخاب نشده — فقط بازه‌های رسمی و '
                      'رنج‌های خودِ پیش‌ تنظیم اسکن می‌شوند. با دکمهٔ «انتخاب» '
                      'می‌توانید از میان بیش از ۵۶۰ رنج کشف‌شده، هر چه '
                      'بخواهید به اسکن اضافه کنید.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.9),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${sel.length} رنج اضافه به تمام اسکن‌ها افزوده می‌شود.',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                        IconButton(
                          tooltip: 'پاک کردن انتخاب‌ها',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => state.updateSettings(
                              state.settings.copyWith(
                                  selectedRanges: const [])),
                        ),
                      ],
                    ),
                  if (sel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        children: [
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final r in sel)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: AppColors.accent2
                                        .withValues(alpha: 0.12),
                                    border: Border.all(
                                        color: AppColors.accent2
                                            .withValues(alpha: 0.35)),
                                  ),
                                  child: Text(r,
                                      style: monoStyle(
                                          size: 11,
                                          color: AppColors.accent2)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                      title: 'بازه‌های رسمی کلودفلر',
                      hint: 'منبع: cloudflare.com/ips-v4'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final r in CfRanges.official)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.accent.withValues(alpha: 0.10),
                            border: Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            r,
                            style: monoStyle(
                                size: 11, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'اسکنر فقط IPهایی را «تمیز» می‌داند که اتصال TLS کامل '
                    'برقرار کنند و گواهی‌شان دامنهٔ SNI انتخابی را پوشش دهد. '
                    'تأخیر فقط برچسب کیفیت است، نه شرط حذف.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }
}
