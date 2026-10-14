
library;

class ScanResult {
  final String ip;
  final int port;

  final int tcpMs;

  final int tlsMs;

  final String colo;

  final bool certOk;

  final String sni;

  final String? error;

  const ScanResult({
    required this.ip,
    required this.port,
    required this.tcpMs,
    required this.tlsMs,
    required this.colo,
    required this.certOk,
    required this.sni,
    this.error,
  });

  bool get ok => tcpMs > 0 && tlsMs > 0;

  int get score => tlsMs > 0 ? tlsMs : (tcpMs > 0 ? tcpMs : 1 << 30);

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'tcpMs': tcpMs,
        'tlsMs': tlsMs,
        'colo': colo,
        'certOk': certOk,
        'sni': sni,
        'error': error,
      };

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        ip: j['ip'] as String,
        port: (j['port'] as num?)?.toInt() ?? 443,
        tcpMs: (j['tcpMs'] as num?)?.toInt() ?? 0,
        tlsMs: (j['tlsMs'] as num?)?.toInt() ?? 0,
        colo: (j['colo'] as String?) ?? '',
        certOk: (j['certOk'] as bool?) ?? false,
        sni: (j['sni'] as String?) ?? '',
        error: j['error'] as String?,
      );
}

class ScanPreset {
  final String id;
  final String name;

  final List<String> ranges;
  final List<int> ports;
  final List<String> sniList;

  final bool onlyCfRanges;

  final bool requireCert;

  final int maxIps;

  final int latencyCeilingMs;

  final int threads;
  final int timeoutMs;

  const ScanPreset({
    required this.id,
    required this.name,
    required this.ranges,
    this.ports = const [443],
    this.sniList = const ['www.cloudflare.com'],
    this.onlyCfRanges = true,
    this.requireCert = true,
    this.maxIps = 4000,
    this.latencyCeilingMs = 1500,
    this.threads = 128,
    this.timeoutMs = 1500,
  });

  ScanPreset copyWith({
    String? name,
    List<String>? ranges,
    List<int>? ports,
    List<String>? sniList,
    bool? onlyCfRanges,
    bool? requireCert,
    int? maxIps,
    int? latencyCeilingMs,
    int? threads,
    int? timeoutMs,
  }) =>
      ScanPreset(
        id: id,
        name: name ?? this.name,
        ranges: ranges ?? this.ranges,
        ports: ports ?? this.ports,
        sniList: sniList ?? this.sniList,
        onlyCfRanges: onlyCfRanges ?? this.onlyCfRanges,
        requireCert: requireCert ?? this.requireCert,
        maxIps: maxIps ?? this.maxIps,
        latencyCeilingMs: latencyCeilingMs ?? this.latencyCeilingMs,
        threads: threads ?? this.threads,
        timeoutMs: timeoutMs ?? this.timeoutMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ranges': ranges,
        'ports': ports,
        'sniList': sniList,
        'onlyCfRanges': onlyCfRanges,
        'requireCert': requireCert,
        'maxIps': maxIps,
        'latencyCeilingMs': latencyCeilingMs,
        'threads': threads,
        'timeoutMs': timeoutMs,
      };

  factory ScanPreset.fromJson(Map<String, dynamic> j) => ScanPreset(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'بدون نام',
        ranges: (j['ranges'] as List?)?.cast<String>() ?? const [],
        ports: (j['ports'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [443],
        sniList: (j['sniList'] as List?)?.cast<String>() ?? const ['www.cloudflare.com'],
        onlyCfRanges: (j['onlyCfRanges'] as bool?) ?? true,
        requireCert: (j['requireCert'] as bool?) ?? true,
        maxIps: (j['maxIps'] as num?)?.toInt() ?? 4000,
        latencyCeilingMs: (j['latencyCeilingMs'] as num?)?.toInt() ?? 1500,
        threads: (j['threads'] as num?)?.toInt() ?? 128,
        timeoutMs: (j['timeoutMs'] as num?)?.toInt() ?? 1500,
      );
}

class HistoryEntry {
  final String id;
  final String presetName;
  final DateTime when;
  final List<ScanResult> results;
  final int scannedCount;

  const HistoryEntry({
    required this.id,
    required this.presetName,
    required this.when,
    required this.results,
    required this.scannedCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'presetName': presetName,
        'when': when.toIso8601String(),
        'scannedCount': scannedCount,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        presetName: (j['presetName'] as String?) ?? '',
        when: DateTime.tryParse(j['when'] as String? ?? '') ?? DateTime.now(),
        scannedCount: (j['scannedCount'] as num?)?.toInt() ?? 0,
        results: ((j['results'] as List?) ?? [])
            .map((e) => ScanResult.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class AppSettings {
  final bool showColoNames;

  final int topN;

  final bool threeD;

  final List<String> selectedRanges;

  const AppSettings({
    this.showColoNames = true,
    this.topN = 500,
    this.threeD = true,
    this.selectedRanges = const [],
  });

  AppSettings copyWith({
    bool? showColoNames,
    int? topN,
    bool? threeD,
    List<String>? selectedRanges,
  }) =>
      AppSettings(
        showColoNames: showColoNames ?? this.showColoNames,
        topN: topN ?? this.topN,
        threeD: threeD ?? this.threeD,
        selectedRanges: selectedRanges ?? this.selectedRanges,
      );

  Map<String, dynamic> toJson() => {
        'showColoNames': showColoNames,
        'topN': topN,
        'threeD': threeD,
        'selectedRanges': selectedRanges,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        showColoNames: (j['showColoNames'] as bool?) ?? true,
        topN: (j['topN'] as num?)?.toInt() ?? 500,
        threeD: (j['threeD'] as bool?) ?? true,
        selectedRanges: ((j['selectedRanges'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
