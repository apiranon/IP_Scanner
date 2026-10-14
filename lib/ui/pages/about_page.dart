import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';
import '../shell.dart';

class AboutPage extends StatelessWidget {
  final AppState state;
  const AboutPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'درباره',
          subtitle: 'شناسنامه و توضیحات برنامه',
        ),
        GlassPanel(
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'دربارهٔ رادار IP'),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'رادار IP نسخهٔ 1.0.0',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'اسکنر IP تمیز کلودفلر برای ویندوز و اندروید — '
                'یافتن IPهایی که در بازهٔ رسمی کلودفلر هستند، اتصال '
                'TLS کامل دارند و گواهی‌شان دامنهٔ SNI انتخابی را پوشش می‌دهد.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.9),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _chip('ویندوز + اندروید', AppColors.accent),
                  _chip('موتور: Socket + SecureSocket', AppColors.accent),
                  _chip('بدون وابستگی سنگین', AppColors.accent2),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // ── توضیحات اسکنر ────────────────────────────────────────
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                  title: 'اسکنر چطور کار می‌کند؟',
                  hint: 'سه مرحلهٔ پروب'),
              const SizedBox(height: AppSpacing.sm),
              _step(
                '۱. اتصال TCP',
                'به هر IP در پورت‌های پیش‌تنظیم وصل می‌شود و تأخیر '
                'برقراری ارتباط را می‌سنجد.',
              ),
              _step(
                '۲. دست‌دهی TLS',
                'اتصال امن برقرار می‌کند؛ اگر SNI پاسخ ندهد یا گواهی '
                'نامعتبر باشد، آن IP کنار می‌رود.',
              ),
              _step(
                '۳. بررسی دیتاسنتر',
                'درخواست trace می‌فرستد تا کد دیتاسنتر (مثل FRA یا TIA) '
                'و اعتبار گواهی خوانده شود.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'اسکنر فقط IPهایی را «تمیز» می‌داند که هر سه مرحله با '
                'موفقیت کامل شوند. تأخیر فقط برچسب کیفیت است، نه شرط حذف.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.9),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // ── حریم خصوصی ───────────────────────────────────────────
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'حریم خصوصی'),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'هیچ داده‌ای از دستگاه شما به سروری ارسال نمی‌شود. '
                'نتایج اسکن، پیش‌تنظیم‌ها و تاریخچه فقط روی همین دستگاه '
                'ذخیره می‌شوند و با حذف برنامه پاک می‌گردند.',
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
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color)),
      );

  Widget _step(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 17, color: AppColors.good),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: body,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
