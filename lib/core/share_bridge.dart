import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShareBridge {
  ShareBridge._();

  static const MethodChannel _channel = MethodChannel('ip_scanner/share');
  static const EventChannel _events = EventChannel('ip_scanner/shared_text');

  static StreamSubscription<dynamic>? _sub;

  static bool get hasNativeSheet => !kIsWeb && Platform.isAndroid;

  static Future<bool> shareText(String text) async {
    if (!hasNativeSheet) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('shareText', {'text': text});
      return ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('shareText failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Stream<String> get incoming => _incoming.stream;
  static final StreamController<String> _incoming = StreamController<String>.broadcast();

  static void startReceiving() {
    if (!hasNativeSheet || _sub != null) return;
    _sub = _events.receiveBroadcastStream().listen(
      (dynamic v) {
        if (v is String && v.isNotEmpty) _incoming.add(v);
      },
      onError: (Object e) => debugPrint('shared_text stream error: $e'),
    );
  }
}
