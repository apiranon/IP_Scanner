import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'core/cf_ranges.dart';
import 'core/ips.dart';
import 'core/models.dart';
import 'data/store.dart';
import 'scanner/scanner_engine.dart';

class AppState extends ChangeNotifier {
  final Store store = Store();
  final Random _rnd = Random.secure();

  late List<ScanPreset> presets;
  late AppSettings settings;
  late List<HistoryEntry> history;
  String selectedPresetId = '';

  bool scanning = false;
  bool _cancelRequested = false;
  int progressDone = 0;
  int progressTotal = 0;
  int progressOk = 0;
  DateTime? scanStarted;
  DateTime? scanFinished;
  List<ScanResult> currentResults = [];
  List<String> currentQueue = [];
  String? lastError;

  AppState() {
    presets = CfRanges.defaultPresets();
    settings = const AppSettings();
    history = [];
    selectedPresetId = presets.first.id;
  }

  ScanPreset get selectedPreset =>
      presets.firstWhere((p) => p.id == selectedPresetId, orElse: () => presets.first);

  Future<void> load() async {
    await store.init();
    final j = await store.read();
    final (ps, st, hs, sel) = Store.decodeState(j);
    if (ps.isNotEmpty) presets = List.of(ps);
    settings = st;
    history = List.of(hs);
    if (sel.isNotEmpty && presets.any((p) => p.id == sel)) {
      selectedPresetId = sel;
    }
    notifyListeners();
  }

  Future<void> persist() async {
    await store.write(Store.encodeState(
      presets: presets,
      settings: settings,
      history: history,
      selectedPresetId: selectedPresetId,
    ));
  }

  void selectPreset(String id) {
    selectedPresetId = id;
    notifyListeners();
    persist();
  }

  void savePreset(ScanPreset p) {
    final i = presets.indexWhere((e) => e.id == p.id);
    if (i == -1) {
      presets.add(p);
    } else {
      presets[i] = p;
    }
    selectedPresetId = p.id;
    notifyListeners();
    persist();
  }

  void deletePreset(String id) {
    presets.removeWhere((p) => p.id == id);
    if (presets.isEmpty) presets = CfRanges.defaultPresets();
    if (selectedPresetId == id) selectedPresetId = presets.first.id;
    notifyListeners();
    persist();
  }

  void resetPresetsToDefaults() {
    presets = CfRanges.defaultPresets();
    selectedPresetId = presets.first.id;
    notifyListeners();
    persist();
  }

  void updateSettings(AppSettings s) {
    settings = s;
    notifyListeners();
    persist();
  }

  late final List<Ipv4Cidr> cfBlocks = <String>[
    ...CfRanges.official,
    ...CfRanges.wide,
  ].map(Ipv4Cidr.parse).whereType<Ipv4Cidr>().toList();

  List<String> buildQueue(ScanPreset p) {
    final rangeSet = <String>{...p.ranges, ...settings.selectedRanges};
    final blocks = rangeSet.map(Ipv4Cidr.parse).whereType<Ipv4Cidr>().toList();
    if (blocks.isEmpty) return [];

    final perRange = (p.maxIps ~/ blocks.length).clamp(256, 4096).toInt();
    final ips = sampleIps(
      blocks: blocks,
      total: p.maxIps,
      perRangeLimit: perRange,
      rand: _rnd.nextInt,
    );
    final filtered = p.onlyCfRanges
        ? ips.where((ip) => Ipv4.inRanges(ip, cfBlocks))
        : ips;
    return filtered.toSet().toList();
  }

  Future<void> startScan() async {
    if (scanning) return;
    final p = selectedPreset;
    lastError = null;
    final queue = buildQueue(p);
    if (queue.isEmpty) {
      lastError = 'هیچ IP معتبری از بازه‌ها ساخته نشد. CIDRها را بررسی کنید.';
      notifyListeners();
      return;
    }

    scanning = true;
    _cancelRequested = false;
    currentQueue = queue;
    currentResults = [];
    progressDone = 0;
    progressTotal = queue.length;
    progressOk = 0;
    scanStarted = DateTime.now();
    scanFinished = null;
    notifyListeners();

    unawaited(_runScan(p, queue));
  }

  Future<void> _runScan(ScanPreset p, List<String> queue) async {
    try {
      final res = await ScannerEngine.scan(
        ips: queue,
        preset: p,
        onResult: (r) {
          currentResults.add(r);
          if (currentResults.length % 5 == 0) notifyListeners();
        },
        onProgress: (done, total, ok) {
          progressDone = done;
          progressTotal = total;
          progressOk = ok;
          if (done % 20 == 0 || done == total) notifyListeners();
        },
        isCancelled: () => _cancelRequested,
      );
      res.sort((a, b) => a.score.compareTo(b.score));
      currentResults = res;
    } catch (e) {
      lastError = 'خطای غیرمنتظره در اسکن: $e';
    } finally {
      scanning = false;
      scanFinished = DateTime.now();
      notifyListeners();

      // ثبت تاریخچه (فقط اگر نتیجه‌ای داشت)
      if (currentResults.isNotEmpty) {
        history.insert(
          0,
          HistoryEntry(
            id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
            presetName: p.name,
            when: DateTime.now(),
            results: List.of(currentResults).take(200).toList(),
            scannedCount: queue.length,
          ),
        );
        if (history.length > 12) history.removeRange(12, history.length);
        persist();
      }
    }
  }

  void requestCancel() {
    _cancelRequested = true;
  }

  void clearResults() {
    currentResults = [];
    progressDone = 0;
    progressOk = 0;
    notifyListeners();
  }

  void deleteHistory(String id) {
    history.removeWhere((h) => h.id == id);
    notifyListeners();
    persist();
  }

  void clearHistory() {
    history.clear();
    notifyListeners();
    persist();
  }

  void restoreFromHistory(HistoryEntry h) {
    currentResults = List.of(h.results);
    currentQueue = h.results.map((r) => r.ip).toList();
    progressDone = h.scannedCount;
    progressTotal = h.scannedCount;
    progressOk = h.results.length;
    scanStarted = h.when;
    scanFinished = null;
    notifyListeners();
  }

  String exportText({bool withPort = true, bool onlyTop = true}) {
    final list = onlyTop
        ? currentResults.take(settings.topN).toList()
        : List.of(currentResults);
    final sb = StringBuffer();
    for (final r in list) {
      sb.writeln(withPort ? '${r.ip}:${r.port}' : r.ip);
    }
    return sb.toString();
  }
}
