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
          case '/server-error':
            response.statusCode = HttpStatus.internalServerError;
            await response.close();
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
  });

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
