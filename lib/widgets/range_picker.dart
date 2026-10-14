import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/cf_ranges.dart';
import '../core/theme.dart';
import 'glass.dart';

class RangePickerPage extends StatefulWidget {
  final List<String> initialSelected;
  const RangePickerPage({super.key, required this.initialSelected});

  static Future<List<String>?> show(
      BuildContext context, List<String> current) {
    return Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RangePickerPage(initialSelected: current),
      ),
    );
  }

  static int prefixOrder(String a, String b) {
    final pa = a.split('.').map(int.tryParse).whereType<int>().toList();
    final pb = b.split('.').map(int.tryParse).whereType<int>().toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final c = pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  @override
  State<RangePickerPage> createState() => _RangePickerPageState();
}

class _RangePickerPageState extends State<RangePickerPage> {
  late final Set<String> _selected = {...widget.initialSelected};
  final TextEditingController _search = TextEditingController();
  late final List<String> _groups = _buildGroups();
  late final Map<String, List<String>> _byGroup = _buildByGroup();
  int _tab = 1; 

  final ScrollController _tabsScroll = ScrollController();

  List<String> _buildGroups() {
    final seen = <String>{};
    for (final r in CfRanges.wide) {
      seen.add(_groupKeyOf(r));
    }
    final list = seen.toList()..sort(RangePickerPage.prefixOrder);
    return ['رسمی', ...list];
  }

  static String _groupKeyOf(String cidr) {
    final octets = cidr.split('.');
    return octets.length == 4 ? '${octets[0]}.${octets[1]}' : octets.first;
  }

  Map<String, List<String>> _buildByGroup() {
    final m = <String, List<String>>{
      'رسمی': [...CfRanges.official],
    };
    for (final r in CfRanges.wide) {
      (m[_groupKeyOf(r)] ??= <String>[]).add(r);
    }
    for (final e in m.entries) {
      e.value.sort(RangePickerPage.prefixOrder);
    }
    return m;
  }

  void _toggle(String cidr) {
    setState(() {
      if (!_selected.remove(cidr)) _selected.add(cidr);
    });
  }

  void _toggleGroup(String group) {
    final items = _byGroup[group] ?? const [];
    if (items.isEmpty) return;
    final allOn = items.every(_selected.contains);
    setState(() {
      for (final r in items) {
        if (allOn) {
          _selected.remove(r);
        } else {
          _selected.add(r);
        }
      }
    });
  }

  void _clear() => setState(_selected.clear);

  void _apply() => Navigator.of(context).pop(
        _selected.toList()..sort(RangePickerPage.prefixOrder),
      );

  @override
  void dispose() {
    _search.dispose();
    _tabsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final hitList = !searching
        ? const <String>[]
        : [
            for (final e in _byGroup.entries)
              for (final r in e.value)
                if (r.toLowerCase().contains(q)) r,
          ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(_selected.isEmpty
              ? 'انتخاب رنج‌ها'
              : '${_selected.length} رنج انتخاب شده'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _apply,
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF04121A),
          icon: const Icon(Icons.check_rounded),
          label: const Text('اعمال',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        persistentFooterButtons: [
          TextButton.icon(
            onPressed: _selected.isEmpty ? null : _clear,
            icon: const Icon(Icons.layers_clear_rounded, size: 18),
            label: const Text('پاک کردن همه'),
          ),
          Text(
            searching
                ? '${hitList.length} نتیجهٔ جست‌وجو'
                : 'مجموع: ${CfRanges.wide.length + CfRanges.official.length} رنج',
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: monoStyle(size: 14),
                  decoration: InputDecoration(
                    hintText: 'جست‌وجو در رنج‌ها — مثل 104.16',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: searching
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ),
            if (!searching)
              SliverToBoxAdapter(
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent &&
                        _tabsScroll.hasClients) {
                      final p = _tabsScroll.position;
                      _tabsScroll.jumpTo(
                        (_tabsScroll.offset + event.scrollDelta.dy)
                            .clamp(0.0, p.maxScrollExtent),
                      );
                    }
                  },
                  child: SizedBox(
                    height: 46,
                    child: ListView.separated(
                      controller: _tabsScroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 8),
                      itemCount: _groups.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final g = _groups[i];
                        final on = i == _tab;
                        return ChoiceChip(
                          selected: on,
                          onSelected: (_) => setState(() => _tab = i),
                          label: Text(g),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                on ? FontWeight.w800 : FontWeight.w500,
                            fontFamilyFallback: const [
                              'Consolas',
                              'Menlo',
                              'monospace'
                            ],
                            color: on ? const Color(0xFF04121A) : null,
                          ),
                          backgroundColor: AppColors.cardDeep,
                          selectedColor: AppColors.accent,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: on
                                    ? AppColors.accent
                                    : AppColors.glassBorder),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (searching && hitList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('رنجی با این نام پیدا نشد.',
                      style: TextStyle(color: AppColors.textTertiary)),
                ),
              )
            else if (searching)
              ..._gridSlivers(hitList)
            else
              ..._groupSlivers(_groups[_tab]),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupSlivers(String group) {
    final items = _byGroup[group] ?? const [];
    final official = group == 'رسمی';
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  official
                      ? 'این بازه‌ها همیشه در هر اسکن لحاظ می‌شوند.'
                      : '${items.length} رنج — با لمس، به اسکن اضافه/حذف می‌شود.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
              if (!official)
                TextButton(
                  onPressed: () => _toggleGroup(group),
                  child: Text(
                    items.every(_selected.contains)
                        ? 'خالی کردن گروه'
                        : 'انتخاب همهٔ گروه',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
            ],
          ),
        ),
      ),
      ..._gridSlivers(items, officialOnly: official),
    ];
  }

  List<Widget> _gridSlivers(List<String> items, {bool officialOnly = false}) {
    return [
      SliverPadding(
        // پایین گرید بازتر شد (دور ۶.۶.۵): آخرین ردیف دیگر زیر
        // دکمهٔ شناور «اعمال» گیر نمی‌کند و ته صفحه نفس دارد.
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 84),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            mainAxisExtent: 44,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final r = items[i];
              return officialOnly ? _staticChip(r) : _pickChip(r);
            },
            childCount: items.length,
          ),
        ),
      ),
    ];
  }

  Widget _staticChip(String cidr) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
      ),
      child: Text(cidr, style: monoStyle(size: 12, color: AppColors.accent)),
    );
  }

  Widget _pickChip(String cidr) {
    final on = _selected.contains(cidr);
    return Material(
      color: on
          ? AppColors.accent.withValues(alpha: 0.14)
          : AppColors.cardDeep,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => _toggle(cidr),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: on ? AppColors.accent : AppColors.glassBorder),
          ),
          child: Text(
            cidr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: monoStyle(
                size: 12,
                color: on ? AppColors.accent : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
