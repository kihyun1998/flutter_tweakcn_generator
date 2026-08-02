import 'dart:convert';
import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:test/test.dart';

/// Exercises the file-fetching half of [FontDownloader] against a server bound
/// to the loopback interface, so nothing leaves the machine.
void main() {
  late HttpServer server;
  late Directory fontsDir;
  late String base;

  /// Paths the test server understands, so each case can pick a behavior.
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://${server.address.host}:${server.port}';
    fontsDir = Directory.systemTemp.createTempSync('font_download_test_');

    server.listen((request) async {
      final response = request.response;
      // Deliberately broken responses make the server throw too; that is the
      // test's own business, not a failure.
      try {
        switch (request.uri.path) {
          case '/ok':
            response.add(List.filled(64, 7));
            await response.close();
          case '/missing':
            response.statusCode = HttpStatus.notFound;
            await response.close();
          case '/missing-with-body':
            // A non-200 that carries a body, which is what the real Google
            // Fonts API sends: an unsupported family answers 400 with ~6.8 kB
            // of HTML. The bodiless cases above cannot stand in for it — a
            // response with no body completes on its own, so the connection
            // returns to the pool whether or not the client drains it, and a
            // test written against them passes with and without the fix.
            response.statusCode = HttpStatus.badRequest;
            response.write('x' * 6805);
            await response.close();
          case '/server-error':
            response.statusCode = HttpStatus.internalServerError;
            await response.close();
          // The three stalls. Each promises a body and then never finishes it,
          // or never answers at all — a peer that goes quiet rather than
          // failing. An errored stream tears its own connection down; a
          // stalled one does not, which is why `/truncated` below never
          // reproduced any of this.
          case '/stall-headers':
            // Accept and say nothing. Nothing to release but the request.
            break;
          case '/stall-body-200':
            response.contentLength = 100000;
            response.add(List.filled(100, 7));
          case '/stall-body-400':
            response.statusCode = HttpStatus.badRequest;
            response.contentLength = 100000;
            response.add(List.filled(100, 7));
          case '/truncated':
            // Promise a kilobyte, deliver 16 bytes, then hang up. The client
            // sees the body end early.
            response.contentLength = 1024;
            response.add(List.filled(16, 7));
            await response.close();
          default:
            response.statusCode = HttpStatus.notFound;
            await response.close();
        }
      } catch (_) {
        // ignored — see above
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (fontsDir.existsSync()) fontsDir.deleteSync(recursive: true);
  });

  FontEntry entry(int weight, String path) =>
      FontEntry(weight: weight, url: '$base$path');

  File fileFor(String name) => File('${fontsDir.path}/$name');

  /// Waits for the server to stop seeing any connection, up to [within].
  ///
  /// Returns the last count observed, so a failure reports the number rather
  /// than only that it timed out. Polling rather than a fixed delay keeps the
  /// passing case fast; only a genuine leak waits out the deadline.
  Future<int> connectionsAfterSettling({
    Duration within = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(within);
    var total = server.connectionsInfo().total;
    while (total > 0 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      total = server.connectionsInfo().total;
    }
    return total;
  }

  test('reports a downloaded file and writes it', () async {
    final report = await FontDownloader.downloadEntries(
      [entry(400, '/ok')],
      'Inter',
      fontsDir.path,
    );

    expect(report.downloaded, 1);
    expect(report.skipped, 0);
    expect(report.failures, isEmpty);
    expect(report.fonts.single.filePath, 'fonts/Inter-Regular.ttf');
    expect(fileFor('Inter-Regular.ttf').existsSync(), isTrue);
    expect(fileFor('Inter-Regular.ttf').lengthSync(), 64);
  });

  test('leaves a failed download out of the declarable fonts', () async {
    final report = await FontDownloader.downloadEntries(
      [entry(400, '/missing')],
      'Inter',
      fontsDir.path,
    );

    expect(report.fonts, isEmpty, reason: 'nothing may be declared');
    expect(report.downloaded, 0);
    expect(report.hasFailures, isTrue);
    expect(report.failures.single.target, 'Inter-Regular.ttf');
    expect(report.failures.single.reason, contains('404'));
    expect(fileFor('Inter-Regular.ttf').existsSync(), isFalse);
  });

  test('keeps the fonts that succeeded when a sibling fails', () async {
    final report = await FontDownloader.downloadEntries(
      [entry(400, '/ok'), entry(700, '/server-error'), entry(300, '/ok')],
      'Inter',
      fontsDir.path,
    );

    expect(report.downloaded, 2);
    expect(report.failures.map((f) => f.target), ['Inter-Bold.ttf']);
    expect(report.fonts.map((f) => f.filePath), [
      'fonts/Inter-Regular.ttf',
      'fonts/Inter-Light.ttf',
    ]);
  });

  test('leaves no file behind when the transfer is cut short', () async {
    final report = await FontDownloader.downloadEntries(
      [entry(400, '/truncated')],
      'Inter',
      fontsDir.path,
    );

    expect(report.hasFailures, isTrue);
    expect(report.fonts, isEmpty);
    expect(
      fileFor('Inter-Regular.ttf').existsSync(),
      isFalse,
      reason: 'a truncated body must not look like a complete font',
    );
    expect(
      fileFor('Inter-Regular.ttf.part').existsSync(),
      isFalse,
      reason: 'the part file must be cleaned up too',
    );
    expect(
      await connectionsAfterSettling(),
      0,
      reason: 'a body that ends early must not strand its connection either',
    );
  });

  test(
    'releases the connection when the response is a non-200 with a body',
    () async {
      final report = await FontDownloader.downloadEntries(
        [entry(400, '/missing-with-body')],
        'Inter',
        fontsDir.path,
      );

      // Side conditions: the failure is still reported and nothing is written,
      // so a green here cannot come from the request having been skipped.
      expect(report.failures, hasLength(1));
      expect(report.failures.single.reason, contains('400'));
      expect(report.downloaded, 0);
      expect(report.fonts, isEmpty);
      expect(fileFor('Inter-Regular.ttf').existsSync(), isFalse);

      expect(
        await connectionsAfterSettling(),
        0,
        reason:
            'downloadEntries closes its client, but an unread response body '
            'leaves that connection active, and HttpClient.close() without '
            'force only destroys idle ones — so the socket outlives the run '
            'and holds the process open',
      );
    },
  );

  // A peer that stalls instead of failing is the case a deadline exists for,
  // and the one where `Future.timeout` is not enough: it completes a derived
  // future and leaves the original subscription running, so the wait ends and
  // the socket does not.
  //
  // This one runs in a child VM, because the claim *is* about a process. The
  // in-process check the other tests use — has the server stopped seeing the
  // connection — cannot stand in for it here: a stalling server never closes
  // its own response, so it keeps counting the connection no matter what the
  // client did, and asking it proves nothing. Whether the VM exits is the
  // observable, and only another process can watch that.
  //
  // All three stalls go through one child, so the cost is one deadline each
  // rather than a process launch each, and the assertion is the real-world
  // one: after meeting every way a peer can go quiet, the run still ends.
  test(
    'lets go of every kind of stalled peer, so the process can still exit',
    () async {
      final child = File('${fontsDir.path}/child.dart')..writeAsStringSync('''
import 'dart:io';
import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';

Future<void> main() async {
  for (final path in ['/stall-headers', '/stall-body-200', '/stall-body-400']) {
    final report = await FontDownloader.downloadEntries(
      [FontEntry(weight: 400, url: '$base\$path')],
      'Inter',
      Directory.systemTemp.createTempSync('stall_child_').path,
    );
    stdout.writeln('\$path -> \${report.failures.single.reason}');
  }
  stdout.writeln('CHILD DONE');
}
''');

      final repoRoot = Directory.current.path;
      final process = await Process.start('dart', [
        'run',
        '--packages=$repoRoot/.dart_tool/package_config.json',
        child.path,
      ]);
      final output = process.stdout.transform(utf8.decoder).join();

      var exited = true;
      final code = await process.exitCode
          .timeout(
            // Three 30-second deadlines, plus room for the VM to start.
            const Duration(seconds: 150),
            onTimeout: () {
              exited = false;
              process.kill(ProcessSignal.sigkill);
              return -1;
            },
          )
          .whenComplete(() => process.exitCode);

      final printed = await output;
      expect(
        exited,
        isTrue,
        reason:
            'the child finished its work and then had to be killed: a socket '
            'nobody let go of is still holding the event loop open\n$printed',
      );
      expect(code, 0);
      // The deadline must not swallow what actually happened, and each stall
      // has to be reported as the step that timed out — not as the one before.
      expect(printed, contains('/stall-headers -> TimeoutException'));
      expect(printed, contains('No response headers'));
      expect(printed, contains('/stall-body-200 -> TimeoutException'));
      expect(printed, contains('No response body'));
      expect(printed, contains('/stall-body-400 -> HTTP 400'));
      expect(printed, contains('CHILD DONE'));
    },
    tags: 'slow',
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test('still reports a file that was already on disk', () async {
    fileFor('Inter-Regular.ttf').writeAsBytesSync([1, 2, 3]);

    final report = await FontDownloader.downloadEntries(
      [entry(400, '/missing')],
      'Inter',
      fontsDir.path,
    );

    // The URL would have failed, but the file is present so it is declarable.
    expect(report.skipped, 1);
    expect(report.downloaded, 0);
    expect(report.failures, isEmpty);
    expect(report.fonts.single.filePath, 'fonts/Inter-Regular.ttf');
    expect(fileFor('Inter-Regular.ttf').readAsBytesSync(), [1, 2, 3]);
  });

  test('creates the fonts directory when it does not exist', () async {
    final nested = '${fontsDir.path}/nested/fonts';

    final report = await FontDownloader.downloadEntries(
      [entry(400, '/ok')],
      'Inter',
      nested,
    );

    expect(report.downloaded, 1);
    expect(File('$nested/Inter-Regular.ttf').existsSync(), isTrue);
  });

  test(
    'reports a refused connection as a failure rather than throwing',
    () async {
      await server.close(force: true);

      final report = await FontDownloader.downloadEntries(
        [entry(400, '/ok')],
        'Inter',
        fontsDir.path,
      );

      expect(report.hasFailures, isTrue);
      expect(report.fonts, isEmpty);
    },
  );

  test(
    'reports rather than throws when the part file cannot be removed',
    () async {
      // A crashed earlier run left a part file, and the directory is now
      // read-only. Cleanup must not become the failure.
      fileFor('Inter-Regular.ttf.part').writeAsStringSync('junk');
      Process.runSync('chmod', ['500', fontsDir.path]);
      addTearDown(() => Process.runSync('chmod', ['700', fontsDir.path]));

      final report = await FontDownloader.downloadEntries(
        [entry(400, '/ok'), entry(700, '/ok')],
        'Inter',
        fontsDir.path,
      );

      // Both entries were attempted; neither crashed the run.
      expect(report.failures, hasLength(2));
      expect(report.fonts, isEmpty);
      expect(
        await connectionsAfterSettling(),
        0,
        reason:
            'these are 200s: the body arrived in full and the sink failed to '
            'open, so nothing ever subscribed to the response. Releasing only '
            'on the non-200 branch does not reach this',
      );
    },
    testOn: '!windows',
  );

  test('uses the custom relative directory in reported paths', () async {
    final report = await FontDownloader.downloadEntries(
      [entry(400, '/ok')],
      'Noto Sans KR',
      fontsDir.path,
      relativeDir: 'assets/fonts',
    );

    expect(report.fonts.single.filePath, 'assets/fonts/NotoSansKR-Regular.ttf');
  });

  group('FontDownloadReport', () {
    test('merge adds up the parts', () {
      final merged = FontDownloadReport.merge([
        FontDownloadReport(
          fonts: const [
            DownloadedFont(family: 'A', filePath: 'fonts/a.ttf', weight: 400),
          ],
          downloaded: 1,
          skipped: 2,
          failures: const [],
        ),
        FontDownloadReport.failure('B-Bold.ttf', 'HTTP 500'),
      ]);

      expect(merged.downloaded, 1);
      expect(merged.skipped, 2);
      expect(merged.fonts, hasLength(1));
      expect(merged.failures.single.target, 'B-Bold.ttf');
      expect(merged.hasFailures, isTrue);
      expect(merged.summary, '1 downloaded, 2 already present, 1 failed');
    });

    test('merge of nothing is empty', () {
      final merged = FontDownloadReport.merge([]);

      expect(merged.fonts, isEmpty);
      expect(merged.hasFailures, isFalse);
      expect(merged.summary, '0 downloaded, 0 already present, 0 failed');
    });
  });
}
