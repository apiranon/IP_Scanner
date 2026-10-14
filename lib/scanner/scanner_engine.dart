import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/cert.dart';
import '../core/models.dart';

class ScannerEngine {
  ScannerEngine._();

  static final RegExp _coloRe = RegExp(r'colo=([A-Za-z0-9]+)');

  static Future<ScanResult> probe({
    required String ip,
    required int port,
    required String sni,
    required int timeoutMs,
    required bool requireCert,
  }) async {
    final done = Completer<ScanResult>();
    runZonedGuarded(() async {
      try {
        final r = await _probeInner(
          ip: ip,
          port: port,
          sni: sni,
          timeoutMs: timeoutMs,
          requireCert: requireCert,
        );
        if (!done.isCompleted) done.complete(r);
      } catch (e) {
        if (!done.isCompleted) {
          done.complete(ScanResult(
            ip: ip,
            port: port,
            tcpMs: 0,
            tlsMs: 0,
            colo: '',
            certOk: false,
            sni: sni,
            error: _shortError(e),
          ));
        }
      }
    }, (e, s) {
      if (!done.isCompleted) {
        done.complete(ScanResult(
          ip: ip,
          port: port,
          tcpMs: 0,
          tlsMs: 0,
          colo: '',
          certOk: false,
          sni: sni,
          error: _shortError(e),
        ));
      }
    });
    return done.future;
  }

  static Future<ScanResult> _probeInner({
    required String ip,
    required int port,
    required String sni,
    required int timeoutMs,
    required bool requireCert,
  }) async {
    final tout = Duration(milliseconds: timeoutMs);
    Socket? raw;
    SecureSocket? tls;
    final sw = Stopwatch();

    try {
      sw
        ..start()
        ..reset();
      raw = await Socket.connect(ip, port, timeout: tout);
      raw.setOption(SocketOption.tcpNoDelay, true);
      final tcpMs = sw.elapsedMilliseconds;

      sw.reset();
      tls = await SecureSocket.secure(
        raw,
        host: sni,
        onBadCertificate: (_) => true,
      ).timeout(tout);
      final handshakeMs = sw.elapsedMilliseconds;

      var certOk = true;
      final peer = tls.peerCertificate;
      if (requireCert) {
        try {
          certOk = peer != null && certCoversHost(peer.pem, sni);
        } catch (_) {
          certOk = false;
        }
      }

      sw.reset();
      final completer = Completer<String>();
      final buf = StringBuffer();
      tls.listen(
        (data) {
          buf.write(utf8.decode(data, allowMalformed: true));
          if (_coloRe.hasMatch(buf.toString()) && !completer.isCompleted) {
            completer.complete(buf.toString());
          }
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(buf.toString());
        },
        cancelOnError: true,
      );
      tls.write('GET /cdn-cgi/trace HTTP/1.1\r\n'
          'Host: $sni\r\n'
          'User-Agent: ip-scanner-flutter/1.0\r\n'
          'Accept: */*\r\n'
          'Connection: close\r\n\r\n');
      String body;
      try {
        body = await completer.future.timeout(tout);
      } on TimeoutException {
        body = buf.toString();
      }
      final tlsMs = sw.elapsedMilliseconds;
      final colo = _coloRe.firstMatch(body)?.group(1) ?? '';

      tls.destroy();
      return ScanResult(
        ip: ip,
        port: port,
        tcpMs: tcpMs,
        tlsMs: handshakeMs + tlsMs,
        colo: colo,
        certOk: certOk,
        sni: sni,
      );
    } catch (e) {
      return ScanResult(
        ip: ip,
        port: port,
        tcpMs: 0,
        tlsMs: 0,
        colo: '',
        certOk: false,
        sni: sni,
        error: _shortError(e),
      );
    } finally {
      try {
        tls?.destroy();
      } catch (_) {}
      try {
        raw?.destroy();
      } catch (_) {}
    }
  }

  static Future<List<ScanResult>> scan({
    required List<String> ips,
    required ScanPreset preset,
    void Function(ScanResult)? onResult,
    void Function(int done, int total, int ok)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (ips.isEmpty) return [];
    final total = ips.length;
    final results = <ScanResult>[];
    var done = 0;
    var okCount = 0;
    var cursor = 0;
    final ports = preset.ports.isEmpty ? const [443] : preset.ports;
    final snis = preset.sniList.isEmpty ? const ['www.cloudflare.com'] : preset.sniList;
    bool cancelled() => isCancelled?.call() ?? false;

    Future<void> worker() async {
      while (!cancelled()) {
        final i = cursor++;
        if (i >= total) return;
        final ip = ips[i];
        final port = ports[i % ports.length];
        final sni = snis[i % snis.length];
        final r = await probe(
          ip: ip,
          port: port,
          sni: sni,
          timeoutMs: preset.timeoutMs,
          requireCert: preset.requireCert,
        );
        done++;
        if (r.ok) {
          okCount++;
          results.add(r);
          onResult?.call(r);
        }
        onProgress?.call(done, total, okCount);
      }
    }

    final threads = preset.threads.clamp(4, 256).toInt();
    await Future.wait(List.generate(threads, (_) => worker()));

    results.sort((a, b) => a.score.compareTo(b.score));
    return results;
  }

  static String _shortError(Object e) {
    var s = e.toString();
    final start = s.indexOf('(');
    if (start != -1) s = s.substring(0, start);
    return s.length > 60 ? s.substring(0, 60) : s.trim();
  }
}
