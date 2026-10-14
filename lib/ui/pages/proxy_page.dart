import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_state.dart';
import '../../core/file_export.dart';
import '../../core/proxy_builder.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';
import '../shell.dart';

class ProxyPage extends StatefulWidget {
  final AppState state;
  const ProxyPage({super.key, required this.state});

  @override
  State<ProxyPage> createState() => _ProxyPageState();
}

class _ProxyPageState extends State<ProxyPage> {
  int _mode = 0;

  final _link = TextEditingController();
  final _server = TextEditingController();
  String _fp = '';

  final _ech = TextEditingController();


  String _cs = ''; 
  String _fm = '';

  // زنجیره‌ساز
  bool _hop1Ssh = false;
  final _hop1Link = TextEditingController();
  final _sshServer = TextEditingController();
  final _sshPort = TextEditingController(text: '22');
  final _sshUser = TextEditingController();
  final _sshPass = TextEditingController();
  final _hop2 = TextEditingController();
  int _fmt = 0;
  String _dns = kDnsOptions.first;
  final _socksPort = TextEditingController(text: '10808');
  String _log = 'warning';

  String _output = '';
  String? _error;
  String _directLink = '';

  @override
  void dispose() {
    for (final c in [
      _link, _server, _ech, _hop1Link, _sshServer, _sshPort, _sshUser,
      _sshPass, _hop2, _socksPort,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copy(String text) async {
    if (text.trim().isEmpty) {
      _snack('خروجی خالی است.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _snack('خروجی در کلیپ‌بورد کپی شد.');
  }

  Future<void> _saveOut() async {
    if (_output.trim().isEmpty) {
      _snack('خروجی خالی است.');
      return;
    }
    final json = _mode == 2;
    final path = await saveTextFile(
      text: _output,
      suggestedName: json ? 'proxy-config.json' : 'proxy-link.txt',
      jsonFilter: json,
      title: json ? 'ذخیرهٔ فایل جیسون' : 'ذخیرهٔ فایل',
    );
    if (path != null) _snack('فایل ذخیره شد: $path');
  }

  // ── ساخت ──────────────────────────────────────────────────────
  void _build() {
    setState(() {
      _error = null;
      _output = '';
      _directLink = '';
      if (_mode == 0) {
        final r = enhanceEchUrl(
          _link.text,
          server: _server.text,
          fp: _fp,
          ech: _ech.text,
        );
        _apply(r);
      } else if (_mode == 1) {
        final r = enhanceFragmentUrl(
          _link.text,
          server: _server.text,
          fp: _fp,
          cs: _cs,
          fm: _fm,
        );
        _apply(r);
      } else {
        _buildChain();
      }
    });
  }

  void _apply(Map<String, dynamic> r) {
    final err = paramsError(r);
    if (err != null) {
      _error = err;
    } else {
      _output = (r['url'] ?? r['json'] ?? '').toString();
    }
  }

  void _buildChain() {
    final port = int.tryParse(_socksPort.text.trim()) ?? 10808;
    final dns = _dns;

    final Map<String, dynamic> p1;
    if (_hop1Ssh) {
      p1 = parseSSH(
        server: _sshServer.text,
        port: _sshPort.text,
        user: _sshUser.text,
        password: _sshPass.text,
      );
    } else {
      p1 = parseProxyURLSingle(_hop1Link.text);
    }
    final err1 = paramsError(p1);
    if (err1 != null) {
      _error = 'نوبت اول: $err1';
      return;
    }
    final p2 = parseProxyURLSingle(_hop2.text);
    final err2 = paramsError(p2);
    if (err2 != null) {
      _error = 'نوبت دوم: $err2';
      return;
    }

    try {
      final Map<String, dynamic> json;
      if (_fmt == 0) {
        if (_hop1Ssh) {
          _error = 'فرمت کلاسیک از SSH پشتیبانی نمی‌کند — یکی از فرمت‌های '
              'مدرن را انتخاب کنید.';
          return;
        }
        json = buildClassicJson(p1, p2,
            dnsServer: dns, socksPort: port, logLevel: _log);
      } else if (_fmt == 1) {
        json = buildModernTunJson(p1, p2,
            dnsServer: dns, socksPort: port, logLevel: _log);
      } else {
        json = buildModernPortJson(p1, p2,
            dnsServer: dns, socksPort: port, logLevel: _log);
      }
      _output = prettyJson(json);
      final lr = linkFromParams(p2);
      _directLink = paramsError(lr) == null ? (lr['url'] ?? '').toString() : '';
    } catch (e) {
      _error = 'ساخت پیکربندی ناموفق بود: $e';
    }
  }
  void _clearFields() {
    setState(() {
      _output = '';
      _error = null;
      _directLink = '';
      switch (_mode) {
        case 0: 
          _link.clear();
          _server.clear();
          _fp = '';
          _ech.clear();
        case 1: 
          _link.clear();
          _server.clear();
          _fp = '';
          _cs = '';
          _fm = '';
        default: 
          _hop1Ssh = false;
          for (final c in [
            _hop1Link, _sshServer, _sshUser, _sshPass, _hop2,
          ]) {
            c.clear();
          }
          _sshPort.text = '22';
          _fmt = 0;
          _dns = kDnsOptions.first;
          _socksPort.text = '10808';
          _log = 'warning';
      }
    });
  }

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'ساخت پروکسی',
          subtitle: 'بهبود لینک و زنجیره‌سازی دوپله',
        ),
        Row(
          children: [
            Expanded(
              child: _modeButton(
                label: 'بهبود ECH',
                icon: Icons.verified_user_rounded,
                active: _mode == 0,
                onTap: () => setState(() => _mode = 0),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _modeButton(
                label: 'بهبود فرگمنت',
                icon: Icons.call_split_rounded,
                active: _mode == 1,
                onTap: () => setState(() => _mode = 1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _modeButton(
                label: 'زنجیره‌ساز',
                icon: Icons.link_rounded,
                active: _mode == 2,
                onTap: () => setState(() => _mode = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_mode == 0) _echPane() else if (_mode == 1) _fragmentPane()
        else
          _chainPane(),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: NeonButton(
                  label: _mode == 2 ? 'ساخت پیکربندی' : 'ساخت لینک',
                  icon: Icons.play_arrow_rounded,
                  onTap: _build,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: NeonButton(
                  label: 'پاک کردن',
                  icon: Icons.cleaning_services_rounded,
                  onTap: _clearFields,
                  borderColor: AppColors.bad,
                  outline: true,
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _errorBox(_error!),
        ],
        if (_output.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _outputBox(),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return NeonButton(
      label: label,
      icon: icon,
      onTap: onTap,
      borderColor: AppColors.accent,
      outline: true,
      highlight: active,
      compact: true,
    );
  }

  Widget _echPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _explainer(
          'بهبود ECH',
          'پارامترهای `fp` و `ech` را روی لینک VLESS/Trojan می‌نشاند تا '
          'دسترسی به سرور از روی نام دامنه در مسیر شبکه پنهان بماند. '
          'اگر لینک با TLS ساخته نشده باشد فقط اثر انگشت اعمال می‌شود.',
        ),
        _linkField(
          'لینک VLESS یا Trojan',
          _link,
          hint: 'vless://… یا trojan://…',
        ),
        _serverField(),
        _fpField(),
        const SizedBox(height: AppSpacing.md),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'سرور پرسش ECH',
                hint: 'دامنهٔ پرسش + سرویس‌دهندهٔ DNS؛ خالی = حذف پارامتر ech',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _ech,
                minLines: 1,
                maxLines: 3,
                style: monoStyle(size: 13),
                decoration: _decoration(
                    'cloudflare-ech.com+udp://8.8.8.8 یا فقط دامنهٔ ech'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'اگر فقط دامنه بنویسید، سرویس‌دهندهٔ DNS پیش‌فرض '
                '(udp://8.8.8.8) خودکار اضافه می‌شود. برای حذف ech '
                'از لینک، این قسمت را خالی بگذارید.',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.8),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final e in kEchPresets.entries)
                    ActionChip(
                      label: Text(e.value.split('+').last,
                          style: monoStyle(size: 10.5,
                              color: AppColors.accent2)),
                      onPressed: () =>
                          setState(() => _ech.text = e.value),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fragmentPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _explainer(
          'بهبود فرگمنت',
          'بسته‌های TLS را قطعه‌قطعه می‌کند تا امضای ترافیک در مسیر شبکه '
          'خوانا نباشد. `fp` همیشه اعمال می‌شود؛ `cs` و `fm` فقط وقتی '
          'لینک با TLS ساخته شده باشد.',
        ),
        _linkField(
          'لینک VLESS یا Trojan',
          _link,
          hint: 'vless://… یا trojan://…',
        ),
        _serverField(),
        _fpField(),
        const SizedBox(height: AppSpacing.md),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dropdownField(
                'مجموعهٔ رمزنگاری (cs)',
                value: _cs,
                items: {
                  '': 'بدون تغییر',
                  kDefaultCipherSuites: 'پیش‌فرض برنامه (۱۳ رمزنگار)',
                },
                onChanged: (v) => setState(() => _cs = v),
                hint: 'فقط با security=tls اعمال می‌شود؛ خالی = پارامتر '
                    'cs اضافه نمی‌شود.',
              ),
              const SizedBox(height: AppSpacing.md),
              _dropdownField(
                'الگوی فرگمنت (fm)',
                value: _fm,
                items: {
                  '': 'بدون تغییر',
                  for (final e in kFragmentPresets.entries) e.key: e.key,
                },
                onChanged: (v) => setState(() => _fm = v),
                hint: 'v1 برای اتصال‌های معمولی، v2 برای شرایط سخت‌تر. '
                    'مقدارها لاتین و ثابت‌اند.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chainPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _explainer(
          'زنجیره‌ساز',
          'دو پروکسی را به‌صورت زنجیره به هم وصل می‌کند: ترافیک از '
          'پلهٔ اول (بدون واسطه) عبور می‌کند و از پلهٔ دوم (زیرمجموعهٔ '
          'اول) به مقصد می‌رسد. خروجی، پیکربندی JSON آمادهٔ ورود به '
          'برنامه‌های پروکسی است.',
        ),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                title: 'نوبت اول (بدون واسطه)',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SSH',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    Switch(
                      value: _hop1Ssh,
                      activeTrackColor: AppColors.accent,
                      onChanged: (v) => setState(() => _hop1Ssh = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_hop1Ssh) _sshFields() else _linkFieldInline(
                _hop1Link,
                hint: 'لینک VLESS / VMess / Trojan / SS / SOCKS / HTTP',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'نوبت دوم (زیرمجموعهٔ اول)',
                hint: 'از این پله، خروجی نهایی به مقصد وصل می‌شود',
              ),
              const SizedBox(height: AppSpacing.sm),
              _linkFieldInline(
                _hop2,
                hint: 'لینک VLESS / VMess / Trojan / SS / SOCKS / HTTP',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'خروجی'),
              const SizedBox(height: AppSpacing.sm),
              _dropdownField(
                'قالب پیکربندی',
                value: '$_fmt',
                items: const {
                  '0': 'کلاسیک — ساختار vnext با streamSettings',
                  '1': 'مدرن (تانل) — تانل + DNS چندلایه + NTP',
                  '2': 'مدرن (پورت محلی) — پورت SOCKS به‌جای تانل',
                },
                onChanged: (v) => setState(() => _fmt = int.parse(v)),
                hint: 'فرمت کلاسیک از SSH پشتیبانی نمی‌کند؛ برای SSH یکی '
                    'از فرمت‌های مدرن را انتخاب کنید.',
              ),
              const SizedBox(height: AppSpacing.md),
              _dropdownField(
                'DNS راه دور',
                value: _dns,
                items: {for (final d in kDnsOptions) d: d},
                onChanged: (v) => setState(() => _dns = v),
                hint: 'درخواست‌های DNS از مسیر زنجیره پرسیده می‌شوند تا '
                    'مقصد واقعی لو نرود.',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('پورت SOCKS محلی',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _socksPort,
                          keyboardType: TextInputType.number,
                          style: monoStyle(size: 13),
                          decoration: _decoration('10808'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _dropdownField(
                      'سطح لاگ',
                      value: _log,
                      items: {
                        for (final l in kLogLevels)
                          l: switch (l) {
                            'none' => 'خاموش',
                            'warning' => 'هشدار',
                            'error' => 'خطا',
                            'info' => 'اطلاعات',
                            _ => 'اشکال‌زدایی',
                          },
                      },
                      onChanged: (v) => setState(() => _log = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sshFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _miniField('سرور', _sshServer, hint: 'نشانی یا دامنه'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _miniField('پورت', _sshPort, hint: '22'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _miniField('کاربر', _sshUser, hint: 'root'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _miniField('گذرواژه', _sshPass, hint: 'الزامی'),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'SSH فقط در فرمت‌های مدرن ساخته می‌شود؛ کاربر پیش‌فرض root و '
          'پورت پیش‌فرض 22 است.',
          style: TextStyle(
              fontSize: 11.5, color: AppColors.textSecondary, height: 1.8),
        ),
      ],
    );
  }

  Widget _explainer(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(body,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.9)),
          ],
        ),
      ),
    );
  }

  Widget _linkField(String label, TextEditingController c, {String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              title: label,
              trailing: const Icon(Icons.link_rounded,
                  size: 17, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _linkFieldInline(c, hint: hint),
          ],
        ),
      ),
    );
  }

  Widget _linkFieldInline(TextEditingController c, {String hint = ''}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: c,
        minLines: 1,
        maxLines: 4,
        style: monoStyle(size: 13),
        decoration: _decoration(hint),
      ),
    );
  }

  Widget _serverField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'سرور جایگزین (اختیاری)',
              hint: 'خالی = نشانی فعلی لینک تغییر نکند',
            ),
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _server,
                style: monoStyle(size: 13),
                decoration: _decoration(
                    'IP:port یا [IPv6]:port — مثلاً 1.2.3.4:443'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'اگر بعداً سرور را عوض کردید، نیازی به ساخت لینک دوباره '
              'نیست؛ فقط همین مقدار را بنویسید و دوباره بسازید.',
              style: TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fpField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'اثر انگشت مرورگر (fp)',
              hint: 'چهرهٔ دستگاه شما در دست‌دهی TLS',
            ),
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: DropdownButton<String>(
                value: _fp,
                isExpanded: true,
                dropdownColor: AppColors.cardDeep2,
                style: monoStyle(size: 13, color: AppColors.textPrimary),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('بدون تغییر',
                        style: TextStyle(fontSize: 13)),
                  ),
                  for (final f in kFingerprints)
                    DropdownMenuItem(
                      value: f,
                      child: Text(f,
                          style: monoStyle(
                              size: 13, color: AppColors.accent)),
                    ),
                ],
                onChanged: (v) => setState(() => _fp = v ?? ''),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'در بهبود ECH انتخاب «بدون تغییر» یا «none» باعث حذف fp '
              'از لینک می‌شود؛ در بهبود فرگمنت فقط نادیده گرفته می‌شود.',
              style: TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label, {
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
    String hint = '',
  }) {
    final safe = items.containsKey(value) ? value : items.keys.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          value: safe,
          isExpanded: true,
          dropdownColor: AppColors.cardDeep2,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          underline: const SizedBox.shrink(),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(hint,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                  height: 1.7)),
        ],
      ],
    );
  }

  Widget _miniField(String label, TextEditingController c, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: c,
            style: monoStyle(size: 13),
            decoration: _decoration(hint),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
      );

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: AppColors.bad.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.bad.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.bad),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.bad, height: 1.7)),
          ),
        ],
      ),
    );
  }

  Widget _outputBox() {
    return GlassPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: _mode == 2 ? 'پیکربندی ساخته‌شده' : 'لینک ساخته‌شده',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeonButton(
                  label: 'کپی',
                  icon: Icons.copy_rounded,
                  onTap: () => _copy(_output),
                  compact: true,
                  outline: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                // ذخیرهٔ فایل (دور ۶.۸.۳) — زنجیره با فیلتر JSON،
                // بقیه متنی.
                NeonButton(
                  label: 'خروجی فایل',
                  icon: Icons.save_alt_rounded,
                  onTap: _saveOut,
                  compact: true,
                  outline: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              _output,
              style: monoStyle(size: 12.5, color: AppColors.accent),
            ),
          ),
          if (_directLink.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.glassBorder),
            const SizedBox(height: AppSpacing.md),
            SectionTitle(
              title: 'لینک مستقیم (نوبت دوم)',
              hint: 'برای ورود تک‌لینکی در کلاینت',
              trailing: NeonButton(
                label: 'کپی',
                icon: Icons.copy_rounded,
                onTap: () => _copy(_directLink),
                compact: true,
                outline: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                _directLink,
                style: monoStyle(size: 12.5, color: AppColors.accent2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
