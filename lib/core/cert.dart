library;

String base64DecodeToString(String s) {
  final t = s.replaceAll(RegExp(r'\s'), '');
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final out = <int>[];
  var buf = 0, bits = 0;
  for (final c in t.codeUnits) {
    final i = alpha.indexOf(String.fromCharCode(c));
    if (i < 0) continue; 
    buf = (buf << 6) | i;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.add((buf >> bits) & 0xFF);
    }
  }
  return String.fromCharCodes(out);
}

List<String> extractSans(String pem) {
  final decoded = base64DecodeToString(
    pem.replaceAll('-----BEGIN CERTIFICATE-----', '').replaceAll('-----END CERTIFICATE-----', ''),
  );
  final hay = '$decoded\n$pem';
  final re = RegExp(r'DNS:([A-Za-z0-9*._-]+)');
  return re.allMatches(hay).map((m) => m.group(1)!).toSet().toList();
}

bool certCoversHost(String pem, String host) {
  final h = host.trim().toLowerCase();
  if (h.isEmpty) return true;
  final sans = extractSans(pem).map((e) => e.toLowerCase()).toList();
  for (final s in sans) {
    if (s == h) return true;
    if (s.startsWith('*.')) {
      final base = s.substring(2);
      if (h == base || h.endsWith('.$base') && !h.substring(0, h.length - base.length - 1).contains('.')) {
        return true;
      }
    }
  }
  return false;
}
