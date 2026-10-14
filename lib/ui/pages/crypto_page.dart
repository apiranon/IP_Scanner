import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ciphers.dart';
import '../../core/share_bridge.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';
import '../shell.dart';

class CryptoPage extends StatefulWidget {
  final String? sharedText;
  final int sharedSeq;
  const CryptoPage({super.key, this.sharedText, this.sharedSeq = 0});

  @override
  State<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends State<CryptoPage> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  final _key = TextEditingController();
  final _inputFocus = FocusNode();

  CipherKind _kind = CipherKind.aps;
  bool _hideKey = true;
  String? _error;
  bool _encode = true;
  int _appliedSeq = 0;

  @override
  void initState() {
    super.initState();
    _input.addListener(_tick);
    _output.addListener(_tick);
    _applyShared(widget.sharedText, widget.sharedSeq);
  }

  @override
  void didUpdateWidget(covariant CryptoPage old) {
    super.didUpdateWidget(old);
    if (widget.sharedSeq != old.sharedSeq) {
      _applyShared(widget.sharedText, widget.sharedSeq);
    }
  }

  void _tick() => setState(() {});

  void _applyShared(String? text, int seq) {
    if (text == null || text.isEmpty || seq == _appliedSeq) return;
    _appliedSeq = seq;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_input.text.isEmpty) {
        _fillFromShare(text);
        return;
      }
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.cardDeep2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.glassBorder),
            ),
            title: const Text('متن دریافتی از اشتراک',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            content: Text(
              'یک متن از برنامهٔ دیگری به رادار IP فرستاده شده. '
              'جای متن فعلی قرار بدهم؟',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.7),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _fillFromShare(text);
                },
                child: const Text('جایگزین کن',
                    style: TextStyle(color: AppColors.accent)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _fillFromShare('${_input.text}\n$text');
                },
                child: const Text('به آخرش اضافه کن',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('رد',
                    style: TextStyle(color: AppColors.bad)),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _fillFromShare(String text) {
    setState(() {
      _input.text = text;
      _output.clear();
      _error = null;
      _encode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('متن از اشتراک دریافت شد — حالا دیکد کنید.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    final what = _output.text.isNotEmpty ? _output.text : _input.text;
    if (what.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اول متنی بنویسید یا انکد کنید.')),
      );
      return;
    }
    final ok = await ShareBridge.shareText(what);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اشتراک باز نشد؛ متن کپی شد.')),
      );
      await Clipboard.setData(ClipboardData(text: what));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    _key.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  bool get _latinOut => true;

  void _run(bool encode) {
    setState(() => _error = null);
    final src = _input.text;
    if (src.isEmpty) {
      setState(() => _output.clear());
      return;
    }
    try {
      final res = encode
          ? TextCipher.encode(_kind, src, _key.text)
          : TextCipher.decode(_kind, src, _key.text);
      setState(() => _output.text = res);
    } on CipherUserError catch (e) {
      setState(() {
        _output.clear();
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _output.clear();
        _error = 'خطای غیرمنتظره‌ای رخ داد؛ متن یا کلید را بررسی کنید.';
      });
    }
  }

  void _swap() {
    final inText = _input.text;
    final outText = _output.text;
    setState(() {
      _input.text = outText;
      _output.text = inText;
      _encode = !_encode;
      _error = null;
    });
  }

  void _copy() {
    final t = _output.text;
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خروجی خالی است.')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: t));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خروجی در کلیپ‌بورد کپی شد.')),
    );
  }

  void _clear() {
    setState(() {
      _input.clear();
      _output.clear();
      _error = null;
    });
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const PageHeader(
          title: 'رمزنگاری متن',
          subtitle: 'انکد و دیکد با کلید دلخواه — پشتیبانی کامل فارسی',
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              color: AppColors.cardDeep2.withValues(alpha: 0.55),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modeButton(
                  label: 'انکد',
                  icon: Icons.lock_rounded,
                  active: _encode,
                  color: AppColors.accent,
                  onTap: () {
                    if (_encode) return;
                    setState(() {
                      _encode = true;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(width: 4),
                _modeButton(
                  label: 'دیکد',
                  icon: Icons.lock_open_rounded,
                  active: !_encode,
                  color: AppColors.accent2,
                  onTap: () {
                    if (!_encode) return;
                    setState(() {
                      _encode = false;
                      _error = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'فرمت رمزنگاری'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardDeep2,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CipherKind>(
                    value: _kind,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    dropdownColor: AppColors.cardDeep2,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    items: [
                      for (final k in CipherKind.values)
                        DropdownMenuItem(
                          value: k,
                          child: Text(k.labelFa,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                    ],
                    onChanged: (k) {
                      if (k == null) return;
                      // عوض‌شدن فرمت، نتیجهٔ قبلی را بی‌معنا می‌کند.
                      setState(() {
                        _kind = k;
                        _output.clear();
                        _error = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                _kind.descFa,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textTertiary, height: 1.6),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _key,
                obscureText: _kind == CipherKind.aesGcm && _hideKey,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'کلید',
                  hintText: _kind.keyHintFa,
                  hintStyle: const TextStyle(
                      fontSize: 11.5, color: AppColors.textTertiary),
                  suffixIcon: _kind == CipherKind.aesGcm
                      ? IconButton(
                          tooltip: _hideKey ? 'نمایش گذرواژه' : 'پنهان‌کردن',
                          iconSize: 19,
                          icon: Icon(_hideKey
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setState(() => _hideKey = !_hideKey),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, c) {
            final input = _fieldCard(
              'متن ورودی',
              controller: _input,
              hint: _encode
                  ? 'متن معمولی را بنویسید تا انکد شود…'
                  : 'متن رمز (Base64/هگز/فارسیِ رمزشده) را این‌جا بگذارید…',
              icon: Icons.login_rounded,
              focus: _inputFocus,
            );
            final output = _fieldCard(
              'خروجی',
              controller: _output,
              hint: _encode
                  ? 'متن رمزشده این‌جا نمایش داده می‌شود…'
                  : 'متن خوانا پس از دیکد این‌جا می‌آید…',
              icon: Icons.logout_rounded,
              readOnly: true,
              latin: _latinOut,
            );
            if (c.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: input),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: output),
                ],
              );
            }
            return Column(
              children: [
                input,
                const SizedBox(height: AppSpacing.lg),
                output,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.bad.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.bad.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppColors.bad),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.bad, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Center(
          child: SizedBox(
            width: 260,
            child: NeonButton(
              label: _encode ? 'تبدیل (انکد)' : 'تبدیل (دیکد)',
              icon: _encode ? Icons.lock_rounded : Icons.lock_open_rounded,
              onTap: () => _run(_encode),
              borderColor: AppColors.accent,
              outline: true,
              // برجسته‌تر از کمکی‌ها: هاله + بوردر پررنگ، باز هم شفاف.
              highlight: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, c) {
            final helperButtons = <(String, IconData, VoidCallback, Color)>[
              (
                'جابجایی',
                Icons.swap_vert_rounded,
                _swap,
                AppColors.accent2,
              ),
              (
                'کپی خروجی',
                Icons.copy_rounded,
                _copy,
                AppColors.good,
              ),
              if (ShareBridge.hasNativeSheet)
                (
                  'اشتراک',
                  Icons.ios_share_rounded,
                  _share,
                  AppColors.accent2,
                ),
              (
                'پاک کردن',
                Icons.delete_outline_rounded,
                _clear,
                AppColors.bad,
              ),
            ];
            Widget btn((String, IconData, VoidCallback, Color) b,
                    {required bool full}) =>
                NeonButton(
                  label: b.$1,
                  icon: b.$2,
                  onTap: b.$3,
                  borderColor: b.$4,
                  outline: true,
                  compact: !full,
                );
            List<Widget> rowOf(List<(String, IconData, VoidCallback, Color)> slice,
                    {required bool full}) =>
                [
                  for (final (i, b) in slice.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: btn(b, full: full)),
                  ],
                ];
            if (c.maxWidth >= 560 || helperButtons.length <= 3) {
              return Row(children: rowOf(helperButtons, full: false));
            }
            return Column(
              children: [
                Row(children: rowOf(helperButtons.sublist(0, 2), full: true)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: rowOf(helperButtons.sublist(2), full: true)),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: NeonButton(
        label: label,
        icon: icon,
        onTap: onTap,
        borderColor: color,
        outline: true,
        highlight: active,
      ),
    );
  }

  Widget _fieldCard(
    String label, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    bool latin = false,
    FocusNode? focus,
  }) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            title: label,
            trailing: Icon(icon, size: 18, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Directionality(
            textDirection: latin ? TextDirection.ltr : TextDirection.rtl,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              focusNode: focus,
              minLines: 5,
              maxLines: 9,
              style: const TextStyle(fontSize: 14, height: 1.7),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
                filled: readOnly,
                fillColor: readOnly ? Colors.black.withValues(alpha: 0.18) : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'کاراکتر: ${controller.value.text.runes.length}',
            textAlign: latin ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
                fontSize: 10.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
