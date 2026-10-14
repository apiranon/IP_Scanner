import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<String?> saveTextFile({
  required String text,
  required String suggestedName,
  bool jsonFilter = false,
  String? title,
}) async {
  if (kIsWeb || (!Platform.isWindows && !Platform.isAndroid)) return null;
  if (Platform.isAndroid) {
    try {
      final path = await const MethodChannel('ip_scanner/share')
          .invokeMethod<String>('saveTextTo', {
        'text': text,
        'fileName': suggestedName,
        'mimeType': jsonFilter ? 'application/json' : 'text/plain',
      });
      return path;
    } on PlatformException catch (e) {
      debugPrint('saveTextFile(android) failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
  final textB64 = base64Encode(utf8.encode(text));
  final nameB64 = base64Encode(utf8.encode(suggestedName));
  final filterB64 = base64Encode(utf8.encode(jsonFilter
      ? 'JSON files (*.json)|*.json|All files (*.*)|*.*'
      : 'Text files (*.txt)|*.txt|All files (*.*)|*.*'));
  final titleB64 = base64Encode(utf8.encode(
      title ?? (jsonFilter ? 'ذخیرهٔ فایل جیسون' : 'ذخیرهٔ فایل IPها')));
  final script =
      "\$ErrorActionPreference='Stop';"
      "Add-Type -AssemblyName System.Windows.Forms;"
      "\$d=New-Object Windows.Forms.SaveFileDialog;"
      "\$d.Filter=[Text.Encoding]::UTF8.GetString("
      "[Convert]::FromBase64String('$filterB64'));"
      "\$d.FileName=[Text.Encoding]::UTF8.GetString("
      "[Convert]::FromBase64String('$nameB64'));"
      "\$d.Title=[Text.Encoding]::UTF8.GetString("
      "[Convert]::FromBase64String('$titleB64'));"
      "if(\$d.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){"
      "[IO.File]::WriteAllText(\$d.FileName,"
      "[Text.Encoding]::UTF8.GetString("
      "[Convert]::FromBase64String('$textB64')),"
      "(New-Object Text.UTF8Encoding(\$false)));"
      "Write-Output \$d.FileName}";
  try {
    final path = await _runPowerShellCapture(script);
    return (path == null || path.isEmpty) ? null : path;
  } catch (e) {
    debugPrint('saveTextFile(windows) failed: $e');
    return null;
  }
}

Future<String?> _runPowerShellCapture(String script) async {
  final units = script.codeUnits; // دقیقاً کدهای UTF-16 رشته
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    bytes[i * 2] = units[i] & 0xFF;
    bytes[i * 2 + 1] = (units[i] >> 8) & 0xFF;
  }
  final r = await Process.run('powershell.exe', [
    '-NoProfile',
    '-NonInteractive',
    '-EncodedCommand',
    base64Encode(bytes),
  ]);
  if (r.exitCode != 0) return null;
  return (r.stdout as String).trim();
}
