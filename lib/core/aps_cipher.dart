library;

const List<String> kApsAlphabet = [
  'ا','ب','پ','ت','ث','ج','چ','ح','خ','د','ذ','ر','ز','ژ','س','ش','ص','ض',
  'ط','ظ','ع','غ','ف','ق','ک','گ','ل','م','ن','و','ه','ی',
];

const Map<String, String> kApsEngToFaSingle = {
  'a': 'ا', 'b': 'ب', 'p': 'پ', 't': 'ت', 's': 'ث', 'j': 'ج', 'h': 'ح',
  'd': 'د', 'z': 'ذ', 'r': 'ر', 'f': 'ف', 'k': 'ک', 'g': 'گ', 'l': 'ل',
  'm': 'م', 'n': 'ن', 'v': 'و', 'y': 'ی',
};

const Map<String, String> kApsEngToFaDigraph = {
  'ch': 'چ', 'kh': 'خ', 'sh': 'ش', 'gh': 'غ', 'zh': 'ژ',
};

final Map<String, String> kApsFaToEng = {
  for (final e in kApsEngToFaSingle.entries) e.value: e.key,
  for (final e in kApsEngToFaDigraph.entries) e.value: e.key,
};

const Map<String, String> kApsSymbolWords = {
  '.': 'شفتول',
  '/': 'منگول',
  '-': 'اژدرکپک',
};

const String _mkLower = '⁠'; 
const String _mkUpper = '⁡'; 
const String _mkWord = '⁢'; 

const List<String> _allMarkers = [_mkLower, _mkUpper, _mkWord];

class _Steps {
  final int latin; 
  final int persian; 
  const _Steps(this.latin, this.persian);
}

int _keyHash(String key) {
  var h = 0x811C9DC5;
  for (final c in key.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7FFFFFFF;
  }
  return h;
}

_Steps _stepsFor(String key) {
  if (key.isEmpty) return const _Steps(2, 0);
  final h = _keyHash(key);
  return _Steps(2 + h % 21, 1 + h % 31);
}

String _shiftLatin(String ch, int k) {
  final c = ch.codeUnitAt(0);
  if (c >= 0x61 && c <= 0x7A) {
    return String.fromCharCode(((c - 0x61 + k) % 26 + 26) % 26 + 0x61);
  }
  if (c >= 0x41 && c <= 0x5A) {
    return String.fromCharCode(((c - 0x41 + k) % 26 + 26) % 26 + 0x41);
  }
  return ch;
}

String _rotatePersian(String ch, int k) {
  if (k == 0) return ch;
  final i = kApsAlphabet.indexOf(ch);
  if (i < 0) return ch;
  final n = kApsAlphabet.length;
  return kApsAlphabet[((i + k) % n + n) % n];
}

String apsEncode(String text, [String key = '']) {
  final st = _stepsFor(key);
  var clean = text;
  for (final m in _allMarkers) {
    clean = clean.replaceAll(m, '');
  }

  final sb = StringBuffer();
  for (final r in clean.runes) {
    final c = String.fromCharCode(r);
    sb.write(_rotatePersian(_shiftLatin(c, st.latin), st.persian));
  }

  final mapped = StringBuffer();
  final s = sb.toString();
  var i = 0;
  while (i < s.length) {
    if (i + 1 < s.length) {
      final two = s.substring(i, i + 2);
      final d = kApsEngToFaDigraph[two.toLowerCase()];
      if (d != null) {
        mapped
          ..write(two[0].toUpperCase() == two[0] ? _mkUpper : _mkLower)
          ..write(two[1].toUpperCase() == two[1] ? _mkUpper : _mkLower)
          ..write(d);
        i += 2;
        continue;
      }
    }
    final one = s[i];
    final f = kApsEngToFaSingle[one.toLowerCase()];
    if (f != null) {
      mapped.write((one.toUpperCase() == one) ? _mkUpper : _mkLower);
      mapped.write(f);
    } else {
      mapped.write(one); 
    }
    i++;
  }

  final out = StringBuffer();
  for (final r in mapped.toString().runes) {
    final c = String.fromCharCode(r);
    final w = kApsSymbolWords[c];
    out.write(w != null ? '$_mkWord$w' : c);
  }
  return out.toString();
}

String apsDecode(String text, [String key = '']) {
  final st = _stepsFor(key);
  var t = text;
  for (final e in kApsSymbolWords.entries) {
    t = t.replaceAll('$_mkWord${e.value}', e.key);
  }
  final sb = StringBuffer();
  var i = 0;
  while (i < t.length) {
    final m = t[i];
    if (m == _mkWord) {
      i++; 
      continue;
    }
    if (m == _mkLower || m == _mkUpper) {
      final marks = <bool>[];
      var j = i;
      while (j < t.length && (t[j] == _mkLower || t[j] == _mkUpper)) {
        marks.add(t[j] == _mkUpper);
        j++;
      }
      final fa = j < t.length ? kApsFaToEng[t[j]] : null;
      if (fa == null) {
        i = j;
        continue;
      }
      if (marks.length == 1) {
        sb.write(marks[0] ? fa.toUpperCase() : fa);
      } else {
        final n = marks.length < fa.length ? marks.length : fa.length;
        for (var c = 0; c < n; c++) {
          sb.write(marks[c] ? fa[c].toUpperCase() : fa[c]);
        }
      }
      i = j + 1;
      continue;
    }
    sb.write(m);
    i++;
  }

  final out = StringBuffer();
  for (final r in sb.toString().runes) {
    final c = String.fromCharCode(r);
    out.write(_shiftLatin(_rotatePersian(c, -st.persian), -st.latin));
  }
  return out.toString();
}

bool apsSelfTest() {
  const samples = [
    'سلام دنیا',
    'Hello world',
    'متن فارسی + English mix — تست 123.',
    'a/b.c-d',
    'چگونه شروع کنم؟',
    'شفتول و منگول و اژدرکپک اصل',
    'AbC xYz p q',
    'نیم‌فاصله را هم نگه می‌دارد',
  ];
  for (final s in samples) {
    if (apsDecode(apsEncode(s)) != s) return false;
    if (apsDecode(apsEncode(s, 'کلیدِ راز'), 'کلیدِ راز') != s) return false;
    if (apsDecode(apsEncode(s, 'k-2'), 'k-2') != s) return false;
  }
  return true;
}
