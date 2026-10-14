import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/models.dart';

class Store {
  static const _file = 'ip_scanner_state.json';

  late final File _f;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _f = File('${dir.path}${Platform.pathSeparator}$_file');
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      if (!await _f.exists()) return null;
      final txt = await _f.readAsString();
      if (txt.trim().isEmpty) return null;
      return jsonDecode(txt) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      await _f.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
    }
  }

  static Map<String, dynamic> encodeState({
    required List<ScanPreset> presets,
    required AppSettings settings,
    required List<HistoryEntry> history,
    required String selectedPresetId,
  }) =>
      {
        'v': 1,
        'presets': presets.map((p) => p.toJson()).toList(),
        'settings': settings.toJson(),
        'selectedPresetId': selectedPresetId,
        'history': history.map((h) => h.toJson()).toList(),
      };

  static (List<ScanPreset>, AppSettings, List<HistoryEntry>, String)
      decodeState(Map<String, dynamic>? j) {
    if (j == null) {
      return (const [], const AppSettings(), const [], '');
    }
    final presets = ((j['presets'] as List?) ?? [])
        .map((e) => ScanPreset.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final settings = j['settings'] == null
        ? const AppSettings()
        : AppSettings.fromJson((j['settings'] as Map).cast<String, dynamic>());
    final history = ((j['history'] as List?) ?? [])
        .map((e) => HistoryEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final sel = (j['selectedPresetId'] as String?) ?? '';
    return (presets, settings, history, sel);
  }
}
