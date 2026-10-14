import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/share_bridge.dart';
import '../core/theme.dart';
import 'pages/about_page.dart';
import 'pages/crypto_page.dart';
import 'pages/history_page.dart';
import 'pages/proxy_page.dart';
import 'pages/scan_page.dart';
import 'pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  StreamSubscription<String>? _sharedSub;
  String? _sharedText;
  int _sharedSeq = 0;

  @override
  void initState() {
    super.initState();
    _sharedSub = ShareBridge.incoming.listen((text) {
      setState(() {
        _tab = 4;
        _sharedText = text;
        _sharedSeq++;
      });
    });
  }

  @override
  void dispose() {
    _sharedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final pages = [
          ScanPage(state: s),
          ProxyPage(state: s),
          HistoryPage(state: s),
          SettingsPage(state: s),
          CryptoPage(
            sharedText: _sharedText,
            sharedSeq: _sharedSeq,
          ),
          AboutPage(state: s),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: AppColors.bgGradient),
              child: Row(
                children: [
                  if (_isWide(context))
                    _SideRail(
                      tab: _tab,
                      onSelect: (i) => setState(() => _tab = i),
                      scanning: s.scanning,
                    ),
                  Expanded(
                    child: IndexedStack(index: _tab, children: pages),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _isWide(context)
                ? null
                : _BottomBar(
                    tab: _tab,
                    onSelect: (i) => setState(() => _tab = i),
                    scanning: s.scanning,
                  ),
          ),
        );
      },
    );
  }

  static bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 860;
}

class _SideRail extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onSelect;
  final bool scanning;

  const _SideRail({
    required this.tab,
    required this.onSelect,
    required this.scanning,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.radar_rounded, 'رادار'),
      (Icons.account_balance_wallet_rounded, 'ساخت پروکسی'),
      (Icons.history_rounded, 'تاریخچه'),
      (Icons.settings_rounded, 'تنظیمات اسکنر'),
      (Icons.enhanced_encryption_rounded, 'رمزنگاری متن'),
      (Icons.info_rounded, 'درباره'),
    ];
    return Container(
      width: 220,
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.glass,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/AP.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.radar_rounded,
                            color: AppColors.accent,
                            size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'رادار IP',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                const Text(
                  'اسکنر IP تمیز کلودفلر',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 4),
              child: _NavItem(
                icon: items[i].$1,
                label: items[i].$2,
                selected: tab == i,
                onTap: () => onSelect(i),
              ),
            ),
          const Spacer(),
          if (scanning)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                '● اسکن در جریان…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onSelect;
  final bool scanning;

  const _BottomBar({
    required this.tab,
    required this.onSelect,
    required this.scanning,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.radar_rounded, 'رادار'),
      (Icons.account_balance_wallet_rounded, 'پروکسی'),
      (Icons.history_rounded, 'تاریخچه'),
      (Icons.settings_rounded, 'تنظیمات'),
      (Icons.enhanced_encryption_rounded, 'رمزنگاری'),
      (Icons.info_rounded, 'درباره'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardDeep,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              items[i].$1,
                              size: 22,
                              color: tab == i
                                  ? AppColors.accent
                                  : AppColors.textTertiary,
                            ),
                            if (i == 0 && scanning)
                              Positioned(
                                top: -2,
                                right: -4,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.good,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: tab == i
                                ? AppColors.accent
                                : AppColors.textTertiary,
                            fontWeight:
                                tab == i ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final bool logo;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.logo = false,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final logoSize = (scaler.scale(22) * 1.4 +  2 + scaler.scale(12.5) * 1.4).ceilToDouble();

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
              fontSize: 12.5, color: AppColors.textSecondary),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          if (logo && Platform.isAndroid) ...[
            SizedBox(
              width: logoSize,
              height: logoSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  'assets/images/AP.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.radar_rounded,
                      color: AppColors.accent,
                      size: 26),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: text),
          ?action,
        ],
      ),
    );
  }
}
