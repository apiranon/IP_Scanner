import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/cf_ranges.dart';
import '../../core/format.dart';
import '../../core/ips.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';

class PresetsSection extends StatelessWidget {
  final AppState state;
  const PresetsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'پیش‌تنظیم‌های اسکن',
            hint: 'بازه‌ها، پورت‌ها، SNI و سقف هر تِم',
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'افزودن',
                    icon: Icons.add_rounded,
                    onTap: () => _editPreset(context, state, null),
                    compact: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: NeonButton(
                    label: 'بازنشانی',
                    icon: Icons.settings_backup_restore_rounded,
                    onTap: () => _confirmReset(context),
                    borderColor: AppColors.bad,
                    outline: true,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final p in state.presets)
            _PresetCard(
              p: p,
              selected: p.id == state.selectedPresetId,
              onSelect: () => state.selectPreset(p.id),
              onEdit: () => _editPreset(context, state, p),
              onDelete: () => _confirmDelete(context, state, p),
            ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('بازنشانی پیش‌تنظیم‌ها'),
          content: const Text(
              'همهٔ پیش‌تنظیم‌های اسکن به حالت اولیهٔ برنامه برمی‌گردند؛ '
              'تِم‌های ساخته/ویرایش‌شدهٔ شما جایگزین می‌شوند. ادامه می‌دهم؟'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 50,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('انصراف')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
                  onPressed: () {
                    state.resetPresetsToDefaults();
                    Navigator.pop(ctx);
                  },
                  child: const Text('بازنشانی'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, ScanPreset p) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف پیش‌ تنظیم'),
          content: Text('«${p.name}» حذف شود؟ بازه‌های آن از ذخیره پاک می‌شوند.'),
          actions: [          
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 50,
              children: [
                TextButton( onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
                  onPressed: () {
                    state.deletePreset(p.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPreset(BuildContext context, AppState state, ScanPreset? p) {
    showDialog(
      context: context,
      builder: (ctx) => _PresetEditorDialog(state: state, existing: p),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final ScanPreset p;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresetCard({
    required this.p,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = CfRanges.totalSize(p.ranges);
    final totalStr = total > BigInt.from(1 << 20)
        ? '${(total.toDouble() / (1 << 20)).toStringAsFixed(1)}M'
        : Fmt.thousands(total.toInt());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        glow: selected,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: selected ? AppColors.accentGradient : null,
                      color: selected ? null : AppColors.cardDeep2,
                      border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.glassBorder),
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radar_rounded,
                      color: selected
                          ? const Color(0xFF04121A)
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.ranges.length} بازه · ${p.ports.join("/")} پورت · ${p.sniList.length} SNI · سقف ${Fmt.thousands(p.maxIps)} IP',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: onEdit,
                      tooltip: 'ویرایش',
                      icon: const Icon(Icons.edit_outlined, size: 19)),
                  IconButton(
                      onPressed: onDelete,
                      tooltip: 'حذف',
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 19,
                          color: AppColors.bad.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final r in p.ranges.take(5))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: CfRanges.isOfficial(r)
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.warn.withValues(alpha: 0.12),
                        border: Border.all(
                          color: CfRanges.isOfficial(r)
                              ? AppColors.accent.withValues(alpha: 0.35)
                              : AppColors.warn.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        r,
                        style: monoStyle(
                          size: 11,
                          color: CfRanges.isOfficial(r)
                              ? AppColors.accent
                              : AppColors.warn,
                        ),
                      ),
                    ),
                  if (p.ranges.length > 5)
                    Text(
                      '+${p.ranges.length - 5} بازه دیگر',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    'حجم کل: ~$totalStr IP',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                  const Spacer(),
                  if (!selected)
                    TextButton.icon(
                      onPressed: onSelect,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 17),
                      label: const Text('انتخاب'),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 16, color: AppColors.good),
                        const SizedBox(width: 4),
                        const Text(
                          'فعال',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.good,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _PresetEditorDialog extends StatefulWidget {
  final AppState state;
  final ScanPreset? existing;

  const _PresetEditorDialog({required this.state, required this.existing});

  @override
  State<_PresetEditorDialog> createState() => _PresetEditorDialogState();
}

class _PresetEditorDialogState extends State<_PresetEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _ranges;
  late final TextEditingController _ports;
  late final TextEditingController _snis;
  late final TextEditingController _maxIps;
  late final TextEditingController _ceiling;
  late final TextEditingController _threads;
  late final TextEditingController _timeout;

  late bool _onlyCf;
  late bool _requireCert;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _ranges = TextEditingController(text: (p?.ranges ?? CfRanges.official).join('\n'));
    _ports = TextEditingController(
        text: (p?.ports ?? const [443]).join(', '));
    _snis = TextEditingController(
        text: (p?.sniList ?? const ['www.cloudflare.com']).join('\n'));
    _maxIps = TextEditingController(
        text: (p?.maxIps ?? 4000).toString());
    _ceiling = TextEditingController(
        text: (p?.latencyCeilingMs ?? 1500).toString());
    _threads = TextEditingController(text: (p?.threads ?? 128).toString());
    _timeout = TextEditingController(text: (p?.timeoutMs ?? 1500).toString());
    _onlyCf = p?.onlyCfRanges ?? true;
    _requireCert = p?.requireCert ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _ranges.dispose();
    _ports.dispose();
    _snis.dispose();
    _maxIps.dispose();
    _ceiling.dispose();
    _threads.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardDeep,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing == null ? 'پیش‌ تنظیم جدید' : 'ویرایش پیش‌ تنظیم',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _name,
                          decoration:
                              const InputDecoration(labelText: 'نام تِم'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _ranges,
                          maxLines: 6,
                          style: monoStyle(size: 12.5),
                          decoration: const InputDecoration(
                            labelText: 'بازه‌ها (هر خط یک CIDR)',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _ports,
                          decoration: const InputDecoration(
                              labelText: 'پورت‌ها (با ویرگول جدا کنید)'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _snis,
                          maxLines: 4,
                          style: monoStyle(size: 12.5),
                          decoration: const InputDecoration(
                            labelText: 'SNIها (هر خط یک دامنه)',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                                child: TextField(
                                    controller: _maxIps,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'حداکثر IP'))),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                                child: TextField(
                                    controller: _ceiling,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'سقف تأخیر (ms)'))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                                child: TextField(
                                    controller: _threads,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'همزمانی'))),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                                child: TextField(
                                    controller: _timeout,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'تایم‌اوت (ms)'))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('فقط بازه‌های رسمی کلودفلر',
                              style: TextStyle(fontSize: 13.5)),
                          subtitle: const Text(
                              'IPهای ساخته‌شده فیلتر ASN رسمی می‌شوند',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textTertiary)),
                          value: _onlyCf,
                          onChanged: (v) => setState(() => _onlyCf = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('گواهی باید دامنهٔ SNI را داشته باشد',
                              style: TextStyle(fontSize: 13.5)),
                          subtitle: const Text(
                              'IPهایی که گواهی جعلی/متفاوت دارند حذف می‌شوند',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textTertiary)),
                          value: _requireCert,
                          onChanged: (v) => setState(() => _requireCert = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('ذخیره'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    // اعتبارسنجی CIDRها
    final ranges = <String>[];
    for (final line in _ranges.text.split(RegExp(r'[\n,;]'))) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final c = Ipv4Cidr.parse(t);
      if (c != null) ranges.add(c.cidr);
    }
    if (ranges.isEmpty || _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام و حداقل یک CIDR معتبر لازم است')),
      );
      return;
    }
    final ports = _ports.text
        .split(RegExp(r'[,\s]+'))
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((v) => v > 0 && v < 65536)
        .toList();
    final snis = _snis.text
        .split(RegExp(r'[\n,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final id = widget.existing?.id ??
        'p${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    widget.state.savePreset(ScanPreset(
      id: id,
      name: _name.text.trim(),
      ranges: ranges,
      ports: ports.isEmpty ? const [443] : ports,
      sniList: snis.isEmpty ? const ['www.cloudflare.com'] : snis,
      maxIps: int.tryParse(_maxIps.text) ?? 4000,
      latencyCeilingMs: int.tryParse(_ceiling.text) ?? 1500,
      threads: int.tryParse(_threads.text) ?? 128,
      timeoutMs: int.tryParse(_timeout.text) ?? 1500,
      onlyCfRanges: _onlyCf,
      requireCert: _requireCert,
    ));
    Navigator.pop(context);
  }
}
