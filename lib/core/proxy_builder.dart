library;

import 'dart:convert';

const String kDefaultCipherSuites = 'TLS_AES_256_GCM_SHA384:'
    'TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:'
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:'
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:'
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:'
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:'
    'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:'
    'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:'
    'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:'
    'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256';

const Map<String, String> kFragmentPresets = {
  'v1': '{"tcp": [{"type": "fragment", "settings": {"packets": "tlshello", '
      '"lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0"}},'
      '{"type": "fragment", "settings": {"packets": "1-1", '
      '"lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355"}}]}',
  'v2': '{"tcp": [{"type": "fragment", "settings": {"packets": "tlshello", '
      '"lengths": ["0", "104", "1"], "delays": ["0"], "maxSplit": "0"}},'
      '{"type": "fragment", "settings": {"packets": "1-1", '
      '"lengths": ["114", "1"], "delays": ["1"], "maxSplit": "11"}}]}',
};

const Map<String, String> kEchPresets = {
  'ech-1': 'cloudflare-ech.com+udp://1.1.1.1',
  'ech-2': 'cloudflare-ech.com+udp://9.9.9.9',
  'ech-3': 'cloudflare-ech.com+udp://208.67.222.222',
  'ech-4': 'cloudflare-ech.com+udp://8.8.8.8',
  'ech-5': 'cloudflare-ech.com+udp://1.0.0.1',
  'ech-6': 'cloudflare-ech.com+udp://8.8.4.4',
  'ech-7': 'cloudflare-ech.com+udp://149.112.112.112',
  'ech-8': 'cloudflare-ech.com+udp://208.67.220.220',
  'ech-9': 'cloudflare-ech.com+udp://76.76.19.19',
  'ech-10': 'cloudflare-ech.com+udp://76.76.2.0',
  'ech-11': 'cloudflare-ech.com+udp://94.140.14.14',
  'ech-12': 'cloudflare-ech.com+udp://94.140.15.15',
  'ech-13': 'cloudflare-ech.com+udp://64.6.64.6',
  'ech-14': 'cloudflare-ech.com+udp://64.6.65.6',
  'ech-15': 'cloudflare-ech.com+udp://45.90.28.0',
  'ech-16': 'cloudflare-ech.com+udp://45.90.30.0',
  'ech-17': 'cloudflare-ech.com+udp://185.228.168.9',
  'ech-18': 'cloudflare-ech.com+udp://185.228.169.9',
};

const List<String> kFingerprints = [
  'unsafe',
  'chrome',
  'firefox',
  'safari',
  'random',
  'none',
];

const List<String> kDnsOptions = [
  'https://8.8.8.8/dns-query',
  'https://dns.google/dns-query',
  'https://dns.adguard-dns.com/dns-query',
  'https://dns.quad9.net/dns-query',
];

const List<String> kLogLevels = ['none', 'warning', 'error', 'info', 'debug'];

String? safeAtob(String? str) {
  if (str == null) return null;
  final cleaned = str.trim().replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty) return null;
  if (!RegExp(r'^[A-Za-z0-9+/=_\-]+$').hasMatch(cleaned)) return null;
  var padded = cleaned.replaceAll('-', '+').replaceAll('_', '/');
  final pad = padded.length % 4;
  if (pad == 1) return null;
  if (pad > 0) padded += '=' * (4 - pad);
  try {
    final bytes = base64Decode(padded);
    try {
      return utf8.decode(bytes);
    } catch (_) {
      final raw = latin1.decode(bytes);
      if (RegExp('[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(raw)) return null;
      return raw;
    }
  } catch (_) {
    return null;
  }
}

String safeDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } catch (_) {
    return s;
  }
}

String _str(Map<String, dynamic> p, String k) {
  final v = p[k];
  return v == null ? '' : v.toString();
}

int _int(Map<String, dynamic> p, String k, int dflt) {
  final v = p[k];
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? dflt;
  return dflt;
}

bool _bool(Map<String, dynamic> p, String k) => p[k] == true;


const String echDnsDefault = 'udp://8.8.8.8';

String getEchQueryServer(String? ech) {
  if (ech == null || ech.isEmpty || !ech.contains('://')) return '';
  final head = ech.split(RegExp(r'[+\s]')).first.trim();
  if (head.isEmpty || head.contains('://')) return '';
  return head;
}

bool isBareEchDomain(String? value) {
  if (value == null || value.isEmpty || value.contains('://')) return false;
  if (RegExp(r'[\s+=/]').hasMatch(value)) return false;
  return RegExp(r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
          caseSensitive: false)
      .hasMatch(value);
}

String normalizeEchInput(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (isBareEchDomain(value)) return '$value+$echDnsDefault';
  return value;
}


Map<String, String> _parseQuery(String q) {
  final m = <String, String>{};
  if (q.isEmpty) return m;
  for (final part in q.split('&')) {
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    final k = eq == -1 ? part : part.substring(0, eq);
    final v = eq == -1 ? '' : part.substring(eq + 1);
    String dec(String s) {
      try {
        return Uri.decodeQueryComponent(s);
      } catch (_) {
        return s;
      }
    }

    m[dec(k)] = dec(v);
  }
  return m;
}

String _serializeQuery(Map<String, String> m) {
  final parts = <String>[];
  for (final e in m.entries) {
    parts.add('${Uri.encodeQueryComponent(e.key)}='
        '${Uri.encodeQueryComponent(e.value)}');
  }
  return parts.join('&').replaceAll('+', '%20');
}

({Map<String, String> q, Uri u})? _splitEnhanceable(String url) {
  if (!url.contains('://')) return null;
  final scheme = url.substring(0, url.indexOf('://')).toLowerCase();
  if (scheme != 'vless' && scheme != 'trojan') return null;
  final u = Uri.tryParse(url);
  if (u == null || (u.host.isEmpty && u.userInfo.isEmpty)) return null;
  return (q: _parseQuery(u.query), u: u);
}

bool _isHostShape(String h) =>
    RegExp(r'^[A-Za-z0-9.\-]+$').hasMatch(h) ||
    RegExp(r'^[0-9A-Fa-f:]+$').hasMatch(h);

({String host, int? port})? _serverOverride(String server) {
  var s = server.trim();
  if (s.isEmpty) return null;
  if (s.contains('://') || s.contains('@')) return null;
  if (s.contains(':') && !s.startsWith('[')) s = '[$s]';
  final br = RegExp(r'^\[(.*?)(?::(\d+))?\]$').firstMatch(s);
  if (br != null) {
    final h = br.group(1) ?? '';
    final p = br.group(2) == null ? null : int.tryParse(br.group(2)!);
    if (h.isEmpty || h.contains(' ')) return null;
    if (!_isHostShape(h)) return null;
    if (p != null && (p < 0 || p > 65535)) return null;
    return (host: h, port: p);
  }
  if (s.contains(' ')) return null;
  final ci = s.lastIndexOf(':');
  if (ci > 0 && ci < s.length - 1 && RegExp(r'^\d+$').hasMatch(s.substring(ci + 1))) {
    final p = int.tryParse(s.substring(ci + 1));
    final h = s.substring(0, ci);
    if (!_isHostShape(h)) return null;
    if (p == null || p < 0 || p > 65535) return null;
    return (host: h, port: p);
  }
  if (!_isHostShape(s)) return null;
  return (host: s, port: null);
}

Uri? _rebuild(Uri u, {String? host, int? port, required Map<String, String> q}) {
  var h = host ?? u.host;
  if (h.contains(':') && !h.startsWith('[')) h = '[$h]';
  try {
    return Uri(
      scheme: u.scheme,
      userInfo: u.userInfo,
      host: h,
      port: port ?? (u.hasPort ? u.port : null),
      path: u.path,
      query: _serializeQuery(q),
      fragment: u.fragment,
    );
  } on FormatException {
    return null;
  }
}

Map<String, dynamic> enhanceFragmentUrl(
  String raw, {
  String server = '',
  String fp = '',
  String cs = '',
  String fm = '',
}) {
  final url = raw.trim();
  if (url.isEmpty) return const {'error': 'نشانی لینک خالی است'};
  final parsed = _splitEnhanceable(url);
  if (parsed == null) {
    return raw.contains('://')
        ? const {'error': 'فقط لینک VLESS و Trojan پشتیبانی می‌شود'}
        : const {'error': 'لینک قابل تجزیه نیست'};
  }
  final u = parsed.u;
  final q = parsed.q;
  final security = q['security'] ?? 'none';

  String? newHost;
  int? newPort;
  if (server.trim().isNotEmpty) {
    final ov = _serverOverride(server);
    if (ov == null) return const {'error': 'نشانی سرور نامعتبر است'};
    newHost = ov.host;
    newPort = ov.port;
  }

  final f = fp.trim();
  if (f.isNotEmpty && f != 'none') q['fp'] = f;
  if (security == 'tls') {
    if (cs.trim().isNotEmpty) q['cs'] = cs.trim();
    if (fm.trim().isNotEmpty) q['fm'] = fm.trim();
  }
  final out = _rebuild(u, host: newHost, port: newPort, q: q);
  if (out == null) return const {'error': 'نشانی سرور یا لینک نامعتبر است'};
  return {'url': out.toString()};
}

Map<String, dynamic> enhanceEchUrl(
  String raw, {
  String server = '',
  String fp = '',
  String ech = '',
}) {
  final url = raw.trim();
  if (url.isEmpty) return const {'error': 'نشانی لینک خالی است'};
  final parsed = _splitEnhanceable(url);
  if (parsed == null) {
    return raw.contains('://')
        ? const {'error': 'فقط لینک VLESS و Trojan پشتیبانی می‌شود'}
        : const {'error': 'لینک قابل تجزیه نیست'};
  }
  final u = parsed.u;
  final q = parsed.q;
  final security = q['security'] ?? 'none';

  String? newHost;
  int? newPort;
  if (server.trim().isNotEmpty) {
    final ov = _serverOverride(server);
    if (ov == null) return const {'error': 'نشانی سرور نامعتبر است'};
    newHost = ov.host;
    newPort = ov.port;
  }

  final f = fp.trim();
  if (f.isNotEmpty && f != 'none') {
    q['fp'] = f;
  } else {
    q.remove('fp');
  }
  if (security == 'tls') {
    final e = normalizeEchInput(ech);
    if (e.isNotEmpty) {
      q['ech'] = e;
    } else {
      q.remove('ech');
    }
  }
  final out = _rebuild(u, host: newHost, port: newPort, q: q);
  if (out == null) return const {'error': 'نشانی سرور یا لینک نامعتبر است'};
  return {'url': out.toString()};
}

Map<String, dynamic> parseVless(String url) {
  final u = Uri.tryParse(url);
  if (u == null) {
    return const {'error': 'لینک VLESS قابل تجزیه نیست'};
  }
  if (u.userInfo.isEmpty) {
    return const {'error': 'لینک VLESS نامعتبر است — شناسهٔ کاربری ندارد'};
  }
  final q = _parseQuery(u.query);
  return <String, dynamic>{
    'protocol': 'vless',
    'uuid': u.userInfo,
    'server': u.host,
    'port': u.hasPort ? u.port : 443,
    'remark': safeDecode(u.fragment),
    'type': q['type'] ?? 'tcp',
    'headerType': q['headerType'] ?? 'none',
    'host': q['host'],
    'path': q['path'],
    'serviceName': q['serviceName'],
    'authority': q['authority'],
    'mode': q['mode'],
    'security': q['security'] ?? 'none',
    'sni': q['sni'],
    'fp': (q['fp']?.isNotEmpty ?? false) ? q['fp'] : 'chrome',
    'alpn': q['alpn'],
    'pbk': q['pbk'],
    'sid': q['sid'],
    'spx': q['spx'],
    'flow': q['flow'],
    'encryption': q['encryption'] ?? 'none',
    'ech': q['ech'],
    'allowInsecure': q['allowInsecure'] == '1' ||
        q['allowInsecure'] == 'true' ||
        q['insecure'] == '1' ||
        q['insecure'] == 'true',
  };
}

Map<String, dynamic> parseVmess(String url) {
  try {
    final b64 = url.replaceFirst(RegExp(r'^vmess://', caseSensitive: false), '');
    final decoded = safeAtob(b64);
    if (decoded == null) {
      return const {'error': 'رمزگشایی بیس۶۴ لینک VMess نشد'};
    }
    final cfg = (jsonDecode(decoded) as Map).cast<String, dynamic>();
    final net = (cfg['net'] ?? 'tcp').toString();
    return <String, dynamic>{
      'protocol': 'vmess',
      'uuid': cfg['id']?.toString(),
      'server': cfg['add']?.toString(),
      'port': int.tryParse(cfg['port']?.toString() ?? '') ?? 443,
      'aid': int.tryParse(cfg['aid']?.toString() ?? '') ?? 0,
      'remark': (cfg['ps'] ?? '').toString(),
      'type': net,
      'headerType': (cfg['type'] ?? 'none').toString(),
      'host': cfg['host']?.toString(),
      'path': cfg['path']?.toString(),
      'serviceName': cfg['path']?.toString(),
      'authority': cfg['authority']?.toString(),
      'security': (cfg['tls'] ?? 'none').toString(),
      'sni': cfg['sni']?.toString(),
      'fp': (cfg['fp']?.toString().isNotEmpty ?? false) ? cfg['fp'].toString() : 'chrome',
      'alpn': cfg['alpn']?.toString(),
      'allowInsecure': (cfg['tls'] == 'tls') &&
          (cfg['allowInsecure'] == 1 ||
              cfg['allowInsecure'] == true ||
              cfg['insecure'] == 1 ||
              cfg['insecure'] == true),
    };
  } catch (_) {
    return const {'error': 'لینک VMess قابل تجزیه نیست'};
  }
}

Map<String, dynamic> parseTrojan(String url) {
  final u = Uri.tryParse(url);
  if (u == null) {
    return const {'error': 'لینک Trojan قابل تجزیه نیست'};
  }
  final password = safeDecode(u.userInfo);
  if (u.userInfo.isEmpty || password.isEmpty) {
    return const {'error': 'لینک Trojan نامعتبر است — گذرواژه ندارد'};
  }
  final q = _parseQuery(u.query);
  return <String, dynamic>{
    'protocol': 'trojan',
    'password': password,
    'server': u.host,
    'port': u.hasPort ? u.port : 443,
    'remark': safeDecode(u.fragment),
    'type': q['type'] ?? 'tcp',
    'headerType': q['headerType'] ?? 'none',
    'host': q['host'],
    'path': q['path'],
    'serviceName': q['serviceName'],
    'authority': q['authority'],
    'mode': q['mode'],
    'security': q['security'] ?? 'tls',
    'sni': q['sni'],
    'fp': (q['fp']?.isNotEmpty ?? false) ? q['fp'] : 'chrome',
    'alpn': q['alpn'],
    'pbk': q['pbk'],
    'sid': q['sid'],
    'spx': q['spx'],
    'ech': q['ech'],
    'allowInsecure': q['allowInsecure'] == '1' ||
        q['allowInsecure'] == 'true' ||
        q['insecure'] == '1' ||
        q['insecure'] == 'true',
  };
}

Map<String, dynamic> parseShadowsocks(String url) {
  try {
    var raw = url.replaceFirst(RegExp(r'^ss://', caseSensitive: false), '');
    var remark = '';
    final hashIdx = raw.indexOf('#');
    if (hashIdx != -1) {
      remark = safeDecode(raw.substring(hashIdx + 1));
      raw = raw.substring(0, hashIdx);
    }
    String? method, password, server, portStr;

    if (raw.contains('@')) {
      final at = raw.indexOf('@');
      final userPart = raw.substring(0, at);
      final hostPart = raw.substring(at + 1);
      final decoded = safeAtob(userPart) ?? userPart;
      final colon = decoded.indexOf(':');
      if (colon == -1) return const {'error': 'لینک Shadowsocks نامعتبر است'};
      method = decoded.substring(0, colon);
      password = decoded.substring(colon + 1);
      final m = RegExp(r'^(.+):(\d+)$').firstMatch(hostPart);
      if (m != null) {
        server = m.group(1);
        portStr = m.group(2);
      }
    } else {
      final decoded = safeAtob(raw);
      if (decoded == null) {
        return const {'error': 'رمزگشایی بیس۶۴ لینک Shadowsocks نشد'};
      }
      final m = RegExp(r'^(.+?):(.+)@(.+):(\d+)$').firstMatch(decoded);
      if (m == null) return const {'error': 'لینک Shadowsocks نامعتبر است'};
      method = m.group(1);
      password = m.group(2);
      server = m.group(3);
      portStr = m.group(4);
    }
    if (server == null || server.isEmpty) {
      return const {'error': 'لینک Shadowsocks سرور ندارد'};
    }
    return <String, dynamic>{
      'protocol': 'shadowsocks',
      'method': method,
      'password': password,
      'server': server,
      'port': int.tryParse(portStr ?? '') ?? 0,
      'remark': remark,
    };
  } catch (_) {
    return const {'error': 'لینک Shadowsocks قابل تجزیه نیست'};
  }
}

Map<String, dynamic> _parseCredHosted(String url,
    {required String protocol,
    required List<String> tgSchemes,
    required List<String> bodySchemes,
    required int defaultPort}) {
  try {
    final target = url.trim();
    final lower = target.toLowerCase();

    for (final tg in tgSchemes) {
      if (lower.startsWith(tg)) {
        final rewritten = tg.startsWith('tg://')
            ? target.replaceFirst(RegExp(r'^tg://[^?]*\?', caseSensitive: false),
                'http://localhost/?')
            : target;
        final u = Uri.tryParse(rewritten);
        if (u == null) break;
        final q = _parseQuery(u.query);
        final server = q['server'] ?? q['host'] ?? q['ip'] ?? '';
        if (server.isEmpty) {
          return {'error': 'لینک $protocol سرور ندارد'};
        }
        final hash = u.fragment;
        return <String, dynamic>{
          'protocol': protocol,
          'server': server,
          'port': int.tryParse(q['port'] ?? '') ?? defaultPort,
          'user': (q['user'] ?? q['username']),
          'pass': (q['pass'] ?? q['password']),
          'remark': hash.isNotEmpty ? safeDecode(hash) : (q['remark'] ?? ''),
        };
      }
    }

    var body = target.replaceFirst(
        RegExp('^(${bodySchemes.join('|')})', caseSensitive: false), '');
    var remark = '';
    final hashIdx = body.indexOf('#');
    if (hashIdx != -1) {
      remark = safeDecode(body.substring(hashIdx + 1));
      body = body.substring(0, hashIdx);
    }
    if (!body.contains('@')) {
      final decodedBody = safeAtob(body);
      if (decodedBody != null &&
          (decodedBody.contains(':') || decodedBody.contains('@'))) {
        if (remark.isEmpty && decodedBody.contains('#')) {
          final dHash = decodedBody.indexOf('#');
          remark = safeDecode(decodedBody.substring(dHash + 1));
          body = decodedBody.substring(0, dHash);
        } else {
          body = decodedBody;
        }
      }
    }

    String userPart = '';
    var hostPart = body;
    if (body.contains('@')) {
      final at = body.lastIndexOf('@');
      userPart = body.substring(0, at);
      hostPart = body.substring(at + 1);
    }

    String? user, pass;
    if (userPart.isNotEmpty) {
      if (userPart.contains(':')) {
        final c = userPart.indexOf(':');
        user = safeDecode(userPart.substring(0, c));
        pass = safeDecode(userPart.substring(c + 1));
      } else {
        final du = safeAtob(userPart);
        if (du != null && du.contains(':')) {
          final c = du.indexOf(':');
          user = du.substring(0, c);
          pass = du.substring(c + 1);
        } else {
          user = safeDecode(userPart);
        }
      }
    }

    Map<String, String>? q;
    final qi = hostPart.indexOf('?');
    if (qi != -1) {
      q = _parseQuery(hostPart.substring(qi + 1));
      hostPart = hostPart.substring(0, qi);
    }
    hostPart = hostPart.replaceAll(RegExp(r'/+$'), '');
    final slash = hostPart.indexOf('/');
    if (slash != -1) hostPart = hostPart.substring(0, slash);

    String server;
    int port;
    if (hostPart.startsWith('[')) {
      final close = hostPart.indexOf(']');
      if (close != -1) {
        server = hostPart.substring(1, close);
        final rest = hostPart.substring(close + 1);
        port = rest.startsWith(':')
            ? (int.tryParse(rest.substring(1)) ?? defaultPort)
            : defaultPort;
      } else {
        server = hostPart;
        port = defaultPort;
      }
    } else if (hostPart.contains(':')) {
      final last = hostPart.lastIndexOf(':');
      server = hostPart.substring(0, last);
      port = int.tryParse(hostPart.substring(last + 1)) ?? defaultPort;
    } else {
      server = hostPart;
      port = defaultPort;
    }

    if (q != null) {
      user ??= q['user'] ?? q['username'];
      pass ??= q['pass'] ?? q['password'];
      if (remark.isEmpty) remark = q['remark'] ?? '';
    }
    if (server.isEmpty) {
      return {'error': 'لینک $protocol سرور ندارد'};
    }
    return <String, dynamic>{
      'protocol': protocol,
      'server': server,
      'port': port,
      'user': user,
      'pass': pass,
      'remark': remark,
    };
  } catch (_) {
    return {'error': 'لینک $protocol قابل تجزیه نیست'};
  }
}

Map<String, dynamic> parseSocks(String url) => _parseCredHosted(url,
      protocol: 'socks',
      tgSchemes: const [
        'tg://socks',
        'tg://socks5',
        'https://t.me/socks',
        'http://t.me/socks',
      ],
      bodySchemes: const [r'socks5://', r'socks://'],
      defaultPort: 1080,
    );

Map<String, dynamic> parseHttp(String url) => _parseCredHosted(url,
      protocol: 'http',
      tgSchemes: const [
        'tg://http',
        'https://t.me/http',
        'http://t.me/http',
      ],
      bodySchemes: const [r'https?://'],
      defaultPort: 80,
    );

Map<String, dynamic> parseProxyURLSingle(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return const {'error': 'متن خالی است'};
  final lower = url.toLowerCase();
  if (lower.startsWith('vless://')) return parseVless(url);
  if (lower.startsWith('vmess://')) return parseVmess(url);
  if (lower.startsWith('trojan://')) return parseTrojan(url);
  if (lower.startsWith('ss://')) return parseShadowsocks(url);
  // SOCKS4/4a عمداً پذیرفته نمی‌شود: خروجی‌ها فقط SOCKS5 می‌سازند.
  if (lower.startsWith('tg://socks') ||
      lower.startsWith('tg://socks5') ||
      lower.startsWith('https://t.me/socks') ||
      lower.startsWith('http://t.me/socks') ||
      lower.startsWith('socks://') ||
      lower.startsWith('socks5://')) {
    return parseSocks(url);
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return parseHttp(url);
  }

  final decoded = safeAtob(url);
  if (decoded != null) {
    if (decoded.contains('"add"')) return parseVmess('vmess://$url');
    final dl = decoded.toLowerCase();
    if (dl.startsWith('vless://') ||
        dl.startsWith('vmess://') ||
        dl.startsWith('trojan://') ||
        dl.startsWith('ss://') ||
        dl.startsWith('socks://') ||
        dl.startsWith('socks5://') ||
        dl.startsWith('http://') ||
        dl.startsWith('https://') ||
        dl.startsWith('tg://')) {
      return parseProxyURLSingle(decoded);
    }
    if (decoded.contains('@') && decoded.contains(':')) {
      return parseSocks('socks5://$decoded');
    }
  }
  return const {
    'error': 'پروتکل ناشناخته — پشتیبانی‌شده: vless، vmess، trojan، ss، '
        'socks (فقط socks5)، http'
  };
}

Map<String, dynamic> parseSSH(
    {required String server,
    required String port,
    required String user,
    required String password}) {
  final s = server.trim();
  if (s.isEmpty) return const {'error': 'برای SSH نشانی سرور لازم است'};
  if (password.isEmpty) {
    return const {'error': 'برای SSH گذرواژه لازم است'};
  }
  return <String, dynamic>{
    'protocol': 'ssh',
    'server': s,
    'port': int.tryParse(port.trim()) ?? 22,
    'user': user.trim().isEmpty ? 'root' : user.trim(),
    'password': password,
    'remark': 'SSH $s:${int.tryParse(port.trim()) ?? 22}',
  };
}

Map<String, dynamic> _buildStreamSettings(Map<String, dynamic> p, bool isChain) {
  final stream = <String, dynamic>{};
  final netType = _str(p, 'type').isEmpty ? 'tcp' : _str(p, 'type');
  final security = _str(p, 'security').isEmpty ? 'none' : _str(p, 'security');
  stream['network'] = netType;
  stream['security'] = security;
  stream['sockopt'] = isChain
      ? {'domainStrategy': 'UseIPv4', 'dialerProxy': 'proxy'}
      : {'domainStrategy': 'UseIP'};

  switch (netType) {
    case 'ws':
      final ws = <String, dynamic>{};
      final host = _str(p, 'host');
      final path = _str(p, 'path');
      if (host.isNotEmpty) ws['host'] = host;
      if (path.isNotEmpty) ws['path'] = path;
      if (host.isEmpty && path.isEmpty) ws['path'] = '/';
      stream['wsSettings'] = ws;
      break;
    case 'grpc':
      final g = <String, dynamic>{};
      final authority = _str(p, 'authority');
      if (authority.isNotEmpty) g['authority'] = authority;
      // فقط وقتی mode واقعاً ست شده باشد — عین مرجع؛ حالت خالی multiMode نسازد.
      final mode = _str(p, 'mode');
      if (mode.isNotEmpty) g['multiMode'] = mode == 'multi';
      final service = _str(p, 'serviceName');
      if (service.isNotEmpty) g['serviceName'] = service;
      stream['grpcSettings'] = g;
      break;
    case 'httpupgrade':
      final h = <String, dynamic>{};
      final host = _str(p, 'host');
      if (host.isNotEmpty) h['host'] = host;
      h['path'] = _str(p, 'path').isEmpty ? '/' : _str(p, 'path');
      stream['httpupgradeSettings'] = h;
      break;
    case 'tcp':
    case 'raw':
      if (_str(p, 'headerType') == 'http') {
        final req = <String, dynamic>{
          'headers': <String, dynamic>{},
          'path': _str(p, 'path').isEmpty
              ? ['/']
              : _str(p, 'path').split(','),
          'method': 'GET',
          'version': '1.1',
        };
        final host = _str(p, 'host');
        if (host.isNotEmpty) {
          (req['headers'] as Map)['Host'] = host.split(',');
        }
        stream['rawSettings'] = {
          'header': {
            'type': 'http',
            'request': req,
          }
        };
      }
      break;
  }

  if (security == 'tls') {
    final sni = _str(p, 'sni');
    final fp = _str(p, 'fp');
    final alpnRaw = _str(p, 'alpn');
    final alpn = alpnRaw.isEmpty
        ? ['http/1.1']
        : alpnRaw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final tls = <String, dynamic>{
      'serverName': sni.isEmpty ? _str(p, 'server') : sni,
      'fingerprint': fp.isEmpty ? 'chrome' : fp,
      'alpn': alpn,
      'allowInsecure': _bool(p, 'allowInsecure'),
    };
    final ech = _str(p, 'ech');
    if (ech.isNotEmpty) tls['echConfigList'] = ech;
    stream['tlsSettings'] = tls;
  } else if (security == 'reality') {
    final sni = _str(p, 'sni');
    final fp = _str(p, 'fp');
    stream['realitySettings'] = <String, dynamic>{
      'serverName': sni.isEmpty ? _str(p, 'server') : sni,
      'fingerprint': fp.isEmpty ? 'chrome' : fp,
      'publicKey': _str(p, 'pbk'),
      'shortId': _str(p, 'sid'),
      'spiderX': _str(p, 'spx'),
      'show': false,
      'allowInsecure': _bool(p, 'allowInsecure'),
    };
  }
  return stream;
}

Map<String, dynamic>? _classicOutbound(Map<String, dynamic> p, String tag,
    bool isChain) {
  final proto = _str(p, 'protocol');
  final outbound = <String, dynamic>{'protocol': proto, 'tag': tag};
  Map<String, dynamic>? settings;

  switch (proto) {
    case 'vless':
      final user = <String, dynamic>{
        'id': _str(p, 'uuid'),
        'encryption': _str(p, 'encryption').isEmpty ? 'none' : _str(p, 'encryption'),
      };
      if (_str(p, 'flow').isNotEmpty) user['flow'] = _str(p, 'flow');
      settings = {
        'vnext': [
          {
            'address': _str(p, 'server'),
            'port': _int(p, 'port', 443),
            'users': [user],
          }
        ]
      };
      break;
    case 'vmess':
      settings = {
        'vnext': [
          {
            'address': _str(p, 'server'),
            'port': _int(p, 'port', 443),
            'users': [
              {
                'id': _str(p, 'uuid'),
                'alterId': _int(p, 'aid', 0),
                'security': 'auto',
              }
            ],
          }
        ]
      };
      break;
    case 'trojan':
      settings = {
        'servers': [
          {
            'address': _str(p, 'server'),
            'port': _int(p, 'port', 443),
            'password': _str(p, 'password'),
          }
        ]
      };
      break;
    case 'shadowsocks':
      settings = {
        'servers': [
          {
            'address': _str(p, 'server'),
            'port': _int(p, 'port', 443),
            'method': _str(p, 'method'),
            'password': _str(p, 'password'),
          }
        ]
      };
      break;
    case 'socks':
    case 'http':
      final server = <String, dynamic>{
        'address': _str(p, 'server'),
        'port': _int(p, 'port', 443),
      };
      if (_str(p, 'user').isNotEmpty && _str(p, 'pass').isNotEmpty) {
        server['users'] = [
          {'user': _str(p, 'user'), 'pass': _str(p, 'pass')}
        ];
      }
      settings = {'servers': [server]};
      break;
    default:
      return null;
  }

  outbound['settings'] = settings;
  outbound['streamSettings'] = _buildStreamSettings(p, isChain);
  return outbound;
}

Map<String, dynamic> buildClassicJson(
  Map<String, dynamic> c1,
  Map<String, dynamic> c2, {
  String dnsServer = 'https://8.8.8.8/dns-query',
  int socksPort = 10808,
  String logLevel = 'warning',
}) {
  final proxy = _classicOutbound(c1, 'proxy', false)!;
  final chain = _classicOutbound(c2, 'chain', true)!;
  return <String, dynamic>{
    'remarks': chainRemark(c1, c2),
    'log': {'loglevel': logLevel},
    'dns': {
      'servers': [
        {'address': dnsServer, 'tag': 'remote-dns'}
      ],
      'queryStrategy': 'UseIP',
      'tag': 'dns',
    },
    'inbounds': [
      {
        'listen': '127.0.0.1',
        'port': socksPort,
        'protocol': 'socks',
        'settings': {'auth': 'noauth', 'udp': true},
        'tag': 'mixed-in',
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
      }
    ],
    'outbounds': [
      chain,
      proxy,
      {'protocol': 'dns', 'tag': 'dns-out'},
      {
        'protocol': 'freedom',
        'tag': 'direct',
        'settings': {'domainStrategy': 'UseIP'},
      },
      {'protocol': 'blackhole', 'tag': 'block'},
    ],
    'routing': {
      'domainStrategy': 'IPIfNonMatch',
      'rules': [
        {'inboundTag': ['remote-dns'], 'outboundTag': 'proxy', 'type': 'field'},
        {'network': 'tcp', 'outboundTag': 'chain', 'type': 'field'},
        {'protocol': ['dns'], 'outboundTag': 'dns-out', 'type': 'field'},
      ],
    },
  };
}

Map<String, dynamic> _modernOutbound(Map<String, dynamic> p, String tag,
    {String? detourTag}) {
  final proto = _str(p, 'protocol');
  final out = <String, dynamic>{'tag': tag, 'type': proto};
  if (detourTag != null) out['detour'] = detourTag;
  out['server'] = _str(p, 'server');
  out['server_port'] = _int(p, 'port', 0);

  switch (proto) {
    case 'vless':
      out['uuid'] = _str(p, 'uuid');
      out['packet_encoding'] = '';
      out['network'] = 'tcp';
      if (_str(p, 'flow').isNotEmpty) out['flow'] = _str(p, 'flow');
      break;
    case 'vmess':
      out['uuid'] = _str(p, 'uuid');
      out['security'] = 'auto';
      out['alter_id'] = _int(p, 'aid', 0);
      out['network'] = 'tcp';
      break;
    case 'trojan':
      out['password'] = _str(p, 'password');
      out['network'] = 'tcp';
      break;
    case 'shadowsocks':
      out['method'] = _str(p, 'method');
      out['password'] = _str(p, 'password');
      out['network'] = 'tcp';
      break;
    case 'socks':
      out['version'] = '5';
      out['network'] = 'tcp';
      if (_str(p, 'user').isNotEmpty && _str(p, 'pass').isNotEmpty) {
        out['username'] = _str(p, 'user');
        out['password'] = _str(p, 'pass');
      }
      break;
    case 'http':
      if (_str(p, 'user').isNotEmpty && _str(p, 'pass').isNotEmpty) {
        out['username'] = _str(p, 'user');
        out['password'] = _str(p, 'pass');
      }
      break;
    case 'ssh':
      out['user'] = _str(p, 'user').isEmpty ? 'root' : _str(p, 'user');
      out['password'] = _str(p, 'password');
      return out;
    default:
      return out;
  }

  final security = _str(p, 'security').isEmpty ? 'none' : _str(p, 'security');
  if (security == 'tls' || security == 'reality') {
    final sni = _str(p, 'sni');
    final host = _str(p, 'host');
    final server = _str(p, 'server');
    final tls = <String, dynamic>{
      'enabled': true,
      'server_name': sni.isNotEmpty
          ? sni
          : (host.isNotEmpty ? host : server),
    };
    if (_bool(p, 'allowInsecure')) tls['insecure'] = true;
    final alpnRaw = _str(p, 'alpn');
    if (alpnRaw.isNotEmpty) {
      final list = alpnRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) tls['alpn'] = list;
    }
    final fp = _str(p, 'fp');
    if (fp.isNotEmpty) {
      tls['utls'] = {'enabled': true, 'fingerprint': fp};
    }
    if (security == 'reality' && _str(p, 'pbk').isNotEmpty) {
      tls['reality'] = {
        'enabled': true,
        'public_key': _str(p, 'pbk'),
        'short_id': _str(p, 'sid'),
      };
    }
    final ech = _str(p, 'ech');
    if (ech.isNotEmpty) {
      final qs = getEchQueryServer(ech);
      tls['record_fragment'] = false;
      tls['ech'] = {
        'enabled': true,
        'query_server_name': qs.isNotEmpty
            ? qs
            : (sni.isNotEmpty ? sni : server),
      };
    }
    out['tls'] = tls;
  }

  final transportType = _str(p, 'type').isEmpty ? 'tcp' : _str(p, 'type');
  final pathRaw = _str(p, 'path');
  switch (transportType) {
    case 'ws':
      final ws = <String, dynamic>{
        'type': 'ws',
        'path': pathRaw.split('?ed=').first.isEmpty
            ? '/'
            : pathRaw.split('?ed=').first,
        'headers': <String, dynamic>{},
      };
      final host = _str(p, 'host');
      if (host.isNotEmpty) (ws['headers'] as Map)['Host'] = host;
      final ed = RegExp(r'[?&]ed=(\d+)').firstMatch(pathRaw);
      if (ed != null) {
        ws['max_early_data'] = int.tryParse(ed.group(1) ?? '') ?? 0;
        ws['early_data_header_name'] = 'Sec-WebSocket-Protocol';
      }
      out['transport'] = ws;
      break;
    case 'grpc':
      out['transport'] = {
        'type': 'grpc',
        'service_name': _str(p, 'serviceName'),
      };
      break;
    case 'httpupgrade':
      final t = <String, dynamic>{
        'type': 'httpupgrade',
        'path': pathRaw.split('?ed=').first.isEmpty
            ? '/'
            : pathRaw.split('?ed=').first,
      };
      final host = _str(p, 'host');
      if (host.isNotEmpty) t['host'] = host;
      out['transport'] = t;
      break;
    case 'tcp':
      if (_str(p, 'headerType') == 'http') {
        final t = <String, dynamic>{
          'type': 'http',
          'path': pathRaw.isEmpty ? '/' : pathRaw,
          'method': 'GET',
          'headers': {
            'Connection': ['keep-alive'],
            'Content-Type': ['application/octet-stream'],
          },
        };
        final host = _str(p, 'host');
        if (host.isNotEmpty) t['host'] = host.split(',');
        out['transport'] = t;
      }
      break;
    case 'raw':
      break;
  }

  if (_bool(p, 'tfo')) out['tcp_fast_open'] = true;
  return out;
}

List<String> _bypassDomains(List<Map<String, dynamic>> cfgs) {
  final out = <String>{};
  final ipv4 = RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}$');
  for (final cfg in cfgs) {
    final server = _str(cfg, 'server');
    if (server.isNotEmpty && !ipv4.hasMatch(server)) out.add(server);
    final sni = _str(cfg, 'sni');
    if (sni.isNotEmpty) out.add(sni);
    final host = _str(cfg, 'host');
    if (host.isNotEmpty) {
      for (final h in host.split(',')) {
        final t = h.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    final ech = _str(cfg, 'ech');
    if (ech.isNotEmpty) {
      final d = getEchQueryServer(ech);
      if (d.isNotEmpty) out.add(d);
    }
  }
  return out.toList();
}

Map<String, dynamic> buildModernTunJson(
  Map<String, dynamic> c1,
  Map<String, dynamic> c2, {
  String dnsServer = 'https://8.8.8.8/dns-query',
  int socksPort = 10808,
  String logLevel = 'warning',
}) {
  final proxy = _modernOutbound(c1, 'proxy');
  final chain = _modernOutbound(c2, 'chain', detourTag: 'proxy');

  String? sbLevel;
  if (logLevel != 'none') sbLevel = logLevel == 'warning' ? 'warn' : logLevel;

  var dnsHost = '8.8.8.8';
  var dnsType = 'https';
  final du = Uri.tryParse(dnsServer);
  if (du != null && du.host.isNotEmpty) {
    dnsHost = du.host;
    dnsType = du.scheme;
  }

  final bypass = _bypassDomains([c1, c2]);

  final log = <String, dynamic>{'disabled': logLevel == 'none'};
  if (sbLevel != null) log['level'] = sbLevel;
  log['timestamp'] = true;

  return <String, dynamic>{
    'log': log,
    'dns': {
      'servers': [
        {'type': dnsType, 'server': dnsHost, 'detour': 'chain', 'tag': 'dns-remote'},
        {'type': 'local', 'tag': 'dns-direct'},
      ],
      'rules': [
        {'clash_mode': 'Direct', 'server': 'dns-direct'},
        {'clash_mode': 'Global', 'server': 'dns-remote'},
        {'domain': bypass, 'server': 'dns-direct'},
      ],
      'strategy': 'ipv4_only',
      'independent_cache': true,
    },
    'inbounds': [
      {
        'type': 'tun',
        'tag': 'tun-in',
        'address': ['172.19.0.1/28'],
        'mtu': 9000,
        'auto_route': true,
        'strict_route': true,
        'stack': 'mixed',
      },
      {
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': '127.0.0.1',
        'listen_port': socksPort,
      },
    ],
    'outbounds': [
      chain,
      proxy,
      {'type': 'direct', 'tag': 'direct'},
    ],
    'route': {
      'rules': [
        {'ip_cidr': '172.19.0.2', 'action': 'hijack-dns'},
        {'domain': bypass, 'outbound': 'direct'},
        {'clash_mode': 'Direct', 'outbound': 'direct'},
        {'action': 'sniff'},
        {'protocol': 'dns', 'action': 'hijack-dns'},
        {'ip_is_private': true, 'outbound': 'direct'},
        {'network': 'udp', 'action': 'reject'},
      ],
      'auto_detect_interface': true,
      'default_domain_resolver': {
        'server': 'dns-direct',
        'strategy': 'ipv4_only',
        'rewrite_ttl': 60,
      },
      'final': 'chain',
    },
    'ntp': {
      'enabled': true,
      'server': 'time.cloudflare.com',
      'server_port': 123,
      'domain_resolver': 'dns-direct',
      'interval': '30m',
      'write_to_system': false,
    },
    'experimental': {
      'cache_file': {'enabled': true, 'store_fakeip': true},
      'clash_api': {
        'external_controller': '127.0.0.1:9090',
        'external_ui': 'ui',
        'default_mode': 'Rule',
      },
    },
  };
}

Map<String, dynamic> buildModernPortJson(
  Map<String, dynamic> c1,
  Map<String, dynamic> c2, {
  String dnsServer = 'https://8.8.8.8/dns-query',
  int socksPort = 10808,
  String logLevel = 'warning',
}) {
  final hop1 = _modernOutbound(c1, 'hop-1');
  if (_str(c1, 'protocol') == 'vless' &&
      (hop1['packet_encoding']?.toString().isEmpty ?? true)) {
    hop1['packet_encoding'] = 'xudp';
  }
  final proxy = _modernOutbound(c2, 'proxy', detourTag: 'hop-1');
  if (_str(c2, 'protocol') == 'vless' &&
      (proxy['packet_encoding']?.toString().isEmpty ?? true)) {
    proxy['packet_encoding'] = 'xudp';
  }

  final sbLevel =
      logLevel == 'none' ? 'info' : (logLevel == 'warning' ? 'warn' : logLevel);

  return <String, dynamic>{
    'log': {'level': sbLevel},
    'dns': {
      'servers': [
        {'address': dnsServer, 'detour': 'proxy', 'tag': 'dns-remote'},
        {'address': '1.1.1.1', 'detour': 'direct', 'tag': 'dns-direct'},
      ],
      'rules': [
        {'outbound': 'any', 'server': 'dns-direct'},
      ],
    },
    'inbounds': [
      {
        'listen': '127.0.0.1',
        'listen_port': socksPort,
        'sniff': true,
        'tag': 'mixed-in',
        'type': 'mixed',
      },
    ],
    'outbounds': [
      hop1,
      proxy,
      {'tag': 'direct', 'type': 'direct'},
      {'tag': 'dns-out', 'type': 'dns'},
    ],
    'route': {
      'auto_detect_interface': true,
      'final': 'proxy',
      'rules': [
        {'outbound': 'dns-out', 'protocol': 'dns'},
      ],
    },
  };
}

String chainRemark(Map<String, dynamic> c1, Map<String, dynamic> c2) =>
    '🔗 ${_str(c1, 'protocol').toUpperCase()} → ${_str(c2, 'protocol').toUpperCase()} '
    '| ${_str(c2, 'server')}:${_int(c2, 'port', 0)}';

Map<String, dynamic> linkFromParams(Map<String, dynamic> p) {
  final proto = _str(p, 'protocol');
  final server0 = _str(p, 'server');
  if (server0.isEmpty) return const {'error': 'نشانی سرور خالی است'};
  final server = server0.contains(':') ? '[$server0]' : server0;
  final port = _int(p, 'port', 0);
  final frag = _str(p, 'remark');
  final tail = frag.isEmpty ? '' : '#${Uri.encodeComponent(frag)}';
  final security = _str(p, 'security');
  final netType = _str(p, 'type').isEmpty ? 'tcp' : _str(p, 'type');
  final headerType = _str(p, 'headerType');
  final isTls = security == 'tls' || security == 'reality';

  switch (proto) {
    case 'vless':
      if (_str(p, 'uuid').isEmpty) {
        return const {'error': 'لینک VLESS شناسهٔ کاربری ندارد'};
      }
      break;
    case 'vmess':
      if (_str(p, 'uuid').isEmpty) {
        return const {'error': 'لینک VMess شناسهٔ کاربری ندارد'};
      }
      break;
    case 'trojan':
      if (_str(p, 'password').isEmpty) {
        return const {'error': 'لینک Trojan گذرواژه ندارد'};
      }
      break;
    case 'shadowsocks':
      if (_str(p, 'method').isEmpty || _str(p, 'password').isEmpty) {
        return const {'error': 'لینک Shadowsocks کامل نیست'};
      }
      break;
    case 'socks':
    case 'http':
      break;
    default:
      return const {'error': 'این پروتکل لینکِ استاندارد ندارد'};
  }

  final q = <String, String>{};
  void add(String k, String v) {
    if (v.isNotEmpty) q[k] = v;
  }

  q['type'] = netType;
  if (headerType.isNotEmpty && headerType != 'none') {
    q['headerType'] = headerType;
  }
  add('host', _str(p, 'host'));
  add('path', _str(p, 'path'));
  add('serviceName', _str(p, 'serviceName'));
  add('authority', _str(p, 'authority'));
  add('mode', _str(p, 'mode'));
  if (isTls) {
    q['security'] = security;
    add('sni', _str(p, 'sni'));
    add('alpn', _str(p, 'alpn'));
    add('fp', _str(p, 'fp'));
    if (security == 'reality') {
      add('pbk', _str(p, 'pbk'));
      add('sid', _str(p, 'sid'));
      add('spx', _str(p, 'spx'));
    }
  }
  if (_bool(p, 'allowInsecure')) q['allowInsecure'] = '1';
  add('ech', _str(p, 'ech'));

  switch (proto) {
    case 'vless':
      add('encryption',
          _str(p, 'encryption').isEmpty ? 'none' : _str(p, 'encryption'));
      add('flow', _str(p, 'flow'));
      return {
        'url': 'vless://${_str(p, 'uuid')}@$server:$port'
            '?${_serializeQuery(q)}$tail'
      };
    case 'trojan':
      return {
        'url': 'trojan://${Uri.encodeComponent(_str(p, 'password'))}'
            '@$server:$port?${_serializeQuery(q)}$tail'
      };
    case 'vmess':
      final cfg = <String, dynamic>{
        'v': '2',
        'ps': frag,
        'add': server0,
        'port': '$port',
        'id': _str(p, 'uuid'),
        'aid': '${_int(p, 'aid', 0)}',
        'scy': 'auto',
        'net': netType,
        'type': headerType.isEmpty ? 'none' : headerType,
        'host': _str(p, 'host'),
        'path': _str(p, 'path'),
        'tls': isTls ? security : '',
        'sni': _str(p, 'sni'),
      };
      return {
        'url': 'vmess://'
            '${base64Encode(utf8.encode(jsonEncode(cfg)))}'
      };
    case 'shadowsocks':
      final b64 = base64Encode(
          utf8.encode('${_str(p, 'method')}:${_str(p, 'password')}'));
      return {'url': 'ss://$b64@$server:$port$tail'};
    case 'socks':
    case 'http':
      final scheme = proto == 'socks' ? 'socks' : 'http';
      final user = _str(p, 'user');
      final pass = _str(p, 'pass');
      final cred = (user.isNotEmpty && pass.isNotEmpty)
          ? '${Uri.encodeComponent(user)}:${Uri.encodeComponent(pass)}@'
          : '';
      return {'url': '$scheme://$cred$server:$port$tail'};
    default:
      return const {'error': 'این پروتکل لینکِ استاندارد ندارد'};
  }
}

String prettyJson(Object obj) => const JsonEncoder.withIndent('  ').convert(obj);

String? paramsError(Object? parsed) {
  if (parsed is Map && parsed['error'] != null) {
    return parsed['error'].toString();
  }
  return null;
}
