import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'aps_cipher.dart';

class CipherUserError implements Exception {
  final String message;
  const CipherUserError(this.message);
  @override
  String toString() => message;
}

enum CipherKind {
  aps,

  aesGcm,

  vigenereFa,

  caesarFa,

  xorBase64,

  base64,

  hex,

  atbashFa,

  reverse,
}

extension CipherKindInfo on CipherKind {
  String get labelFa => switch (this) {
        CipherKind.aps => 'الگوریتم برنامه',
        CipherKind.aesGcm => 'AES‑256‑GCM',
        CipherKind.vigenereFa => 'وینژر فارسی',
        CipherKind.caesarFa => 'سزار فارسی',
        CipherKind.xorBase64 => 'XOR + Base64',
        CipherKind.base64 => 'Base64',
        CipherKind.hex => 'هگزادسیمال',
        CipherKind.atbashFa => 'آتبش فارسی',
        CipherKind.reverse => 'معکوس متن',
      };

  String get descFa => switch (this) {
        CipherKind.aps =>
          'الگوریتم برنامه : نگاشت لاتین↔فارسی، شیفت حروف و کلماتِ نماد.',
        CipherKind.aesGcm =>
          'استاندارد رمزنگاری صنعتی. گذرواژه را گم کنید، متن برگشت‌ناپذیر است.',
        CipherKind.vigenereFa =>
          'وینژر روی الفبای ۳۲تایی + پوششِ کلیدی روی کلِ خروجی.',
        CipherKind.caesarFa =>
          'جابجایی یکنواخت حروف؛ کلید = عدد ۱ تا ۳۱، به‌علاوهٔ پوششِ کلیدی.',
        CipherKind.xorBase64 =>
          'هر بایت متن با بایت‌های کلید XOR می‌شود؛ خروجی Base64.',
        CipherKind.base64 =>
          'پوشش کلیدی روی بایت‌ها و سپس Base64 — بدون کلیدِ درست خوانا نیست.',
        CipherKind.hex =>
          'پوشش کلیدی روی بایت‌ها و سپس هگز — بدون کلیدِ درست خوانا نیست.',
        CipherKind.atbashFa =>
          'آینهٔ الفبا («ا»↔«ی»، «ب»↔«و»…) و سپس پوششِ کلیدی؛ بدون کلید خوانا نیست.',
        CipherKind.reverse =>
          'متن از آخر به اول و سپس پوششِ کلیدی؛ بدون کلید خوانا نیست.',
      };

  bool get needsKey => true;

  String get keyHintFa => switch (this) {
        CipherKind.aps => 'کلید دلخواه — هر چه پیچیده‌تر، رمز محکم‌تر',
        CipherKind.aesGcm => 'گذرواژه (حداقل ۴ نویسه)',
        CipherKind.vigenereFa => 'کلیدِ حرفی، فارسی یا لاتین',
        CipherKind.caesarFa => 'عدد ۱ تا ۳۱',
        CipherKind.xorBase64 => 'کلید دلخواه',
        CipherKind.base64 => 'کلید دلخواه (بایت‌ها پیش از Base64 پوشانده می‌شوند)',
        CipherKind.hex => 'کلید دلخواه (بایت‌ها پیش از هگز پوشانده می‌شوند)',
        CipherKind.atbashFa => 'کلید دلخواه (بدون آن متن خوانا نیست)',
        CipherKind.reverse => 'کلید دلخواه (بدون آن متن خوانا نیست)',
      };
}

class TextCipher {
  TextCipher._();

  static final Random _rng = Random.secure();

  static String encode(CipherKind kind, String text, String key) {
    if (text.isEmpty) return '';
    return switch (kind) {
      CipherKind.aps =>
        _seal(apsEncode(text, _require(key)), key),
      CipherKind.aesGcm => _aesEncrypt(text, _requirePass(key)),
      CipherKind.vigenereFa =>
        _seal(_vigenere(text, _require(key), true), key),
      CipherKind.caesarFa => _seal(_caesar(text, _requireStep(key)), key),
      CipherKind.xorBase64 => _xorB64(text, _require(key), true),
      CipherKind.base64 => base64Encode(
          _wrapKeystream(utf8.encode(text), _require(key))),
      CipherKind.hex =>
          _toHex(_wrapKeystream(utf8.encode(text), _require(key))),
      CipherKind.atbashFa => _seal(_atbash(text), _require(key)),
      CipherKind.reverse => _seal(
          String.fromCharCodes(text.runes.toList().reversed), _require(key)),
    };
  }

  static String decode(CipherKind kind, String text, String key) {
    if (text.isEmpty) return '';
    return switch (kind) {
      CipherKind.aps =>
        apsDecode(_open(text, _require(key)), key),
      CipherKind.aesGcm => _aesDecrypt(text, _requirePass(key)),
      CipherKind.vigenereFa =>
        _vigenere(_open(text, _require(key)), key, false),
      CipherKind.caesarFa => _caesar(_open(text, _require(key)), -_requireStep(key)),
      CipherKind.xorBase64 => _xorB64(text, _require(key), false),
      CipherKind.base64 => _try(() {
          final k = _require(key);
          return utf8.decode(
              _unwrapKeystream(base64Decode(text.trim()), k));
        }, 'متن Base64 معتبر نیست.'),
      CipherKind.hex => _try(() {
          final k = _require(key);
          return utf8.decode(_unwrapKeystream(_fromHex(text), k));
        }, 'متن هگز معتبر نیست (ارقام/حروف a–f).'),
      CipherKind.atbashFa => _atbash(_open(text, _require(key))),
      CipherKind.reverse => String.fromCharCodes(
          _open(text, _require(key)).runes.toList().reversed),
    };
  }

  static String _require(String key) {
    if (key.trim().isEmpty) {
      throw const CipherUserError('این فرمت به کلید نیاز دارد.');
    }
    return key;
  }

  static String _requirePass(String key) {
    if (key.trim().length < 4) {
      throw const CipherUserError('گذرواژه باید حداقل ۴ نویسه باشد.');
    }
    return key;
  }

  static int _requireStep(String key) {
    final n = int.tryParse(key.trim());
    if (n == null || n < 1 || n > 31) {
      throw const CipherUserError('کلید سزار باید عددی بین ۱ تا ۳۱ باشد.');
    }
    return n;
  }

  static T _try<T>(T Function() body, String message) {
    try {
      return body();
    } on CipherUserError {
      rethrow;
    } catch (_) {
      throw CipherUserError(message);
    }
  }

  static int _keyDigest(String key) {
    var h = 0x811C9DC5;
    for (final c in utf8.encode(key)) {
      h ^= c;
      h = (h * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }

  static int _ksByte(int i, List<int> kb, int h) {
    final mix = (i * 2654435761) >> 16;
    final rot = h >> (i % 24);
    return (kb[i % kb.length] ^ rot ^ mix) & 0xFF;
  }

  static int _headCheck(int len) =>
      (0x3C ^ len ^ (len >> 8) ^ (len >> 16)) & 0xFF;

  static List<int> _wrapKeystream(List<int> data, String key) {
    final kb = utf8.encode(key);
    final h = _keyDigest(key);
    final head = [0xA5, 0x5A, _headCheck(data.length)];
    final body = Uint8List(head.length + data.length);
    for (var i = 0; i < body.length; i++) {
      final src = i < head.length ? head[i] : data[i - head.length];
      body[i] = (src ^ _ksByte(i, kb, h)) & 0xFF;
    }
    return body;
  }

  static List<int> _unwrapKeystream(List<int> packed, String key) {
    if (packed.length < 3) {
      throw const CipherUserError('متن کوتاه است؛ کلید یا متن خراب است.');
    }
    final kb = utf8.encode(key);
    final h = _keyDigest(key);
    final out = Uint8List(packed.length - 3);
    var magic = true;
    var chk = 0;
    for (var i = 0; i < packed.length; i++) {
      final d = (packed[i] ^ _ksByte(i, kb, h)) & 0xFF;
      if (i == 0) {
        if (d != 0xA5) magic = false;
      } else if (i == 1) {
        if (d != 0x5A) magic = false;
      } else if (i == 2) {
        chk = d;
      } else {
        out[i - 3] = d;
      }
    }
    if (!magic || chk != _headCheck(out.length)) {
      throw const CipherUserError('رمزگشایی نشد — کلید غلط است یا متن خراب.');
    }
    return out;
  }

  static String _seal(String text, String key) =>
      base64Encode(_wrapKeystream(utf8.encode(text), key));

  static String _open(String text, String key) {
    final k = _require(key);
    final bytes = _try(
        () => base64Decode(text.trim()), 'خروجی رمزشده معتبر نیست (Base64).');
    return _try(() => utf8.decode(_unwrapKeystream(bytes, k)),
        'رمزگشایی نشد — کلید غلط است یا متن خراب.');
  }

  static final String _faAlpha = kApsAlphabet.join();
  static const String _laLower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _laUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static String _caesar(String text, int step) {
    final out = StringBuffer();
    for (final r in text.runes) {
      final c = String.fromCharCode(r);
      final fi = _faAlpha.indexOf(c);
      if (fi >= 0) {
        final n = _faAlpha.length;
        out.write(_faAlpha[((fi + step) % n + n) % n]);
        continue;
      }
      final li = _laLower.indexOf(c);
      if (li >= 0) {
        out.write(_laLower[((li + step) % 26 + 26) % 26]);
        continue;
      }
      final ui = _laUpper.indexOf(c);
      if (ui >= 0) {
        out.write(_laUpper[((ui + step) % 26 + 26) % 26]);
        continue;
      }
      out.write(c);
    }
    return out.toString();
  }

  static String _atbash(String text) {
    final out = StringBuffer();
    for (final r in text.runes) {
      final c = String.fromCharCode(r);
      final fi = _faAlpha.indexOf(c);
      if (fi >= 0) {
        out.write(_faAlpha[_faAlpha.length - 1 - fi]);
        continue;
      }
      final li = _laLower.indexOf(c);
      if (li >= 0) {
        out.write(_laLower[25 - li]);
        continue;
      }
      final ui = _laUpper.indexOf(c);
      if (ui >= 0) {
        out.write(_laUpper[25 - ui]);
        continue;
      }
      final di = '0123456789'.indexOf(c);
      if (di >= 0) {
        out.write('0123456789'[9 - di]);
        continue;
      }
      out.write(c);
    }
    return out.toString();
  }

  static List<int> _keyShifts(String key) {
    final shifts = <int>[];
    for (final r in key.runes) {
      final c = String.fromCharCode(r);
      final fi = _faAlpha.indexOf(c);
      if (fi >= 0) {
        shifts.add(fi);
        continue;
      }
      final li = _laLower.indexOf(c.toLowerCase());
      if (li >= 0) {
        shifts.add(li % _faAlpha.length);
        continue;
      }
      shifts.add(r % _faAlpha.length); 
    }
    if (shifts.isEmpty) shifts.add(0);
    return shifts;
  }

  static String _vigenere(String text, String key, bool encrypt) {
    final shifts = _keyShifts(key);
    final out = StringBuffer();
    var k = 0;
    for (final r in text.runes) {
      final c = String.fromCharCode(r);
      final fi = _faAlpha.indexOf(c);
      if (fi >= 0) {
        final s = encrypt ? shifts[k % shifts.length] : -shifts[k % shifts.length];
        out.write(_faAlpha[((fi + s) % 32 + 32) % 32]);
        k++;
        continue;
      }
      out.write(c);
    }
    return out.toString();
  }

  static String _xorB64(String text, String key, bool encrypt) {
    final data = encrypt
        ? Uint8List.fromList(utf8.encode(text))
        : _try(
            () => base64Decode(text.trim()), 'متن XOR معتبر نیست (Base64).');
    final kb = Uint8List.fromList(utf8.encode(key));
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      out[i] = data[i] ^ kb[i % kb.length];
    }
    if (encrypt) return base64Encode(out);
    try {
      return utf8.decode(out);
    } catch (_) {
      throw const CipherUserError('رمزگشایی نشد — کلید غلط است یا متن خراب.');
    }
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _fromHex(String text) {
    final t = text.replaceAll(RegExp(r'\s'), '');
    if (t.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(t)) {
      throw const CipherUserError('متن هگز معتبر نیست (ارقام/حروف a–f).');
    }
    final out = Uint8List(t.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(t.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static const int _kdfIterations = 25000;

  static Uint8List _deriveKey(String pass, Uint8List salt) {
    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _kdfIterations, 32));
    return kdf.process(Uint8List.fromList(utf8.encode(pass)));
  }

  static String _aesEncrypt(String text, String pass) {
    final salt = Uint8List.fromList(
        List<int>.generate(16, (_) => _rng.nextInt(256)));
    final iv = Uint8List.fromList(
        List<int>.generate(12, (_) => _rng.nextInt(256)));
    final key = _deriveKey(pass, salt);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final ct = gcm.process(Uint8List.fromList(utf8.encode(text)));
    final packed = Uint8List(salt.length + iv.length + ct.length)
      ..setRange(0, salt.length, salt)
      ..setRange(salt.length, salt.length + iv.length, iv)
      ..setRange(salt.length + iv.length, salt.length + iv.length + ct.length, ct);
    return base64Encode(packed);
  }

  static String _aesDecrypt(String text, String pass) {
    final packed = _try(
        () => base64Decode(text.trim()), 'متن AES معتبر نیست (Base64).');
    if (packed.length < 16 + 12 + 16) {
      throw const CipherUserError('بستهٔ AES کوتاه است؛ متن خراب است.');
    }
    final salt = packed.sublist(0, 16);
    final iv = packed.sublist(16, 28);
    final ct = packed.sublist(28);
    final key = _deriveKey(pass, salt);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    try {
      return utf8.decode(gcm.process(ct));
    } on InvalidCipherTextException {
      throw const CipherUserError(
          'گذرواژه غلط است یا متن دست‌خورده.');
    } catch (_) {
      throw const CipherUserError('رمزگشایی نشد — متن یا کلید معتبر نیست.');
    }
  }
}
