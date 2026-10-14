library;

class Ipv4Cidr {
  final int start; 
  final int prefix; 

  const Ipv4Cidr(this.start, this.prefix);

  int get size => 1 << (32 - prefix);

  int get end => start + size - 1;

  static Ipv4Cidr? parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final slash = t.indexOf('/');
    String ipPart;
    int prefix;
    if (slash == -1) {
      ipPart = t;
      prefix = 32;
    } else {
      ipPart = t.substring(0, slash);
      prefix = int.tryParse(t.substring(slash + 1)) ?? -1;
    }
    if (prefix < 0 || prefix > 32) return null;
    final v = Ipv4.toIntOrNull(ipPart);
    if (v == null) return null;
    // انطباق با مرز بلوک (ماسک‌کردن).
    final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    return Ipv4Cidr(v & mask, prefix);
  }

  String get cidr => '${Ipv4.dotted(start)}/$prefix';

  @override
  String toString() => cidr;
}

class Ipv4 {
  Ipv4._();

  static int? toIntOrNull(String dotted) {
    final parts = dotted.trim().split('.');
    if (parts.length != 4) return null;
    var v = 0;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return null;
      v = (v << 8) | n;
    }
    return v;
  }

  static int? toIntOrNullLoose(String s) => toIntOrNull(s);

  static String dotted(int v) {
    final a = (v >> 24) & 0xFF;
    final b = (v >> 16) & 0xFF;
    final c = (v >> 8) & 0xFF;
    final d = v & 0xFF;
    return '$a.$b.$c.$d';
  }

  static bool inRanges(String ip, List<Ipv4Cidr> ranges) {
    final v = toIntOrNull(ip);
    if (v == null) return false;
    for (final r in ranges) {
      if (v >= r.start && v <= r.end) return true;
    }
    return false;
  }
}

List<String> sampleIps({
  required List<Ipv4Cidr> blocks,
  required int total,
  required int perRangeLimit,
  required int Function(int max) rand,
}) {
  if (blocks.isEmpty || total <= 0) return [];

  final quota = <int>[];
  var sum = 0;
  for (final b in blocks) {
    final q = b.size < perRangeLimit ? b.size : perRangeLimit;
    quota.add(q);
    sum += q;
  }
  if (sum > total) {
    for (var i = 0; i < quota.length; i++) {
      quota[i] = (quota[i] * total / sum).floor().clamp(1, perRangeLimit).toInt();
    }
  }

  final out = <String>[];
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    final q = quota[i];
    if (b.size <= q) {
      for (var k = 0; k < b.size; k++) {
        out.add(Ipv4.dotted(b.start + k));
      }
    } else {
      final step = b.size / q;
      var pos = 0.0;
      for (var k = 0; k < q; k++) {
        var idx = pos.round();
        final jitterMax = (step / 4).floor();
        if (jitterMax > 0) {
          idx += rand(jitterMax * 2 + 1) - jitterMax;
        }
        if (idx < 0) idx = 0;
        if (idx >= b.size) idx = b.size - 1;
        out.add(Ipv4.dotted(b.start + idx));
        pos += step;
      }
    }
  }
  out.shuffle();
  return out.length > total ? out.sublist(0, total) : out;
}
