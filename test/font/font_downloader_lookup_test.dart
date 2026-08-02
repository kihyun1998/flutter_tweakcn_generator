import 'dart:convert';
import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:test/test.dart';

/// Exercises the CSS lookup half of [FontDownloader] against a server bound to
/// the loopback interface.
///
/// The sibling file covers the file-writing half. This one exists because that
/// asymmetry hid two defects: the non-200 leak of #23 was only ever fixed on
/// the half a test could reach, and the "200 with no `@font-face`" state of #28
/// could not be reproduced at all. Both are pinned below.
void main() {
  late HttpServer server;
  late Directory fontsDir;
  late Uri endpoint;

  /// Every request the server has answered, so a test can assert what the
  /// lookup actually asked for rather than what it meant to ask for.
  final requested = <Uri>[];

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    endpoint = Uri.parse('http://${server.address.host}:${server.port}/css2');
    fontsDir = Directory.systemTemp.createTempSync('font_lookup_test_');
    requested.clear();

    server.listen((request) async {
      requested.add(request.uri);
      final response = request.response;
      // The family name doubles as the instruction for what to answer, so one
      // server can stand in for every shape the real API returns.
      final family = request.uri.queryParameters['family']?.split(':').first;
      try {
        switch (family) {
          case 'Unserved':
            // What the real API sends for a family it does not serve: 400
            // with ~6.8 kB of HTML. A bodiless non-200 cannot stand in for it
            // — it completes on its own, so the connection returns to the pool
            // whether or not the client drains it (#23).
            response.statusCode = HttpStatus.badRequest;
            response.write('x' * 6805);
            await response.close();
          case 'NoFaces':
            // A 200 that parses to nothing. Reaching this at all is what #27
            // was filed about.
            response.write('body { font-family: sans-serif; }');
            await response.close();
          case 'Stalled':
            // Promises a body and never finishes it. A stalled peer is not an
            // errored one: an errored stream tears its own connection down.
            response.contentLength = 100000;
            response.add(List.filled(100, 7));
          default:
            response.write(_cssFor(family ?? 'Inter', server.port));
            await response.close();
        }
      } catch (_) {
        // A deliberately broken response makes the server throw too; that is
        // the test's own business, not a failure.
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (fontsDir.existsSync()) fontsDir.deleteSync(recursive: true);
  });

  /// How many connections the server still sees once things have settled.
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

  group('the lookup request', () {
    test('asks for the family and every standard weight', () async {
      await FontDownloader.download(
        'Noto Sans',
        fontsDir.path,
        cssEndpoint: endpoint,
      );

      expect(requested.first.path, '/css2');
      expect(
        requested.first.queryParameters['family'],
        'Noto Sans:wght@100;200;300;400;500;600;700;800;900',
        reason:
            'the weight list must survive the trip unencoded, and the '
            'space in the family name must not',
      );
    });

    test('defaults to the Google Fonts CSS2 API', () {
      expect(
        FontDownloader.defaultCssEndpoint,
        Uri.parse('https://fonts.googleapis.com/css2'),
      );
    });

    test('keeps a query the caller put on the endpoint', () async {
      await FontDownloader.download(
        'Inter',
        fontsDir.path,
        cssEndpoint: endpoint.replace(queryParameters: {'key': 'abc'}),
      );

      expect(requested.first.queryParameters['key'], 'abc');
      expect(
        requested.first.queryParameters['family'],
        startsWith('Inter:wght@'),
      );
    });
  });

  group('what the lookup reports', () {
    test('downloads the files the CSS names', () async {
      final report = await FontDownloader.download(
        'Inter',
        fontsDir.path,
        cssEndpoint: endpoint,
      );

      expect(report.downloaded, 1);
      expect(report.fonts.single.family, 'Inter');
      expect(report.fonts.single.weight, 400);
      expect(report.hasFailures, isFalse);
      expect(File('${fontsDir.path}/Inter-Regular.ttf').existsSync(), isTrue);
    });

    test('reports a non-200 as a failure rather than throwing', () async {
      final report = await FontDownloader.download(
        'Unserved',
        fontsDir.path,
        cssEndpoint: endpoint,
      );

      expect(report.failures, hasLength(1));
      expect(report.failures.single.target, 'Unserved');
      expect(report.failures.single.reason, contains('400'));
      expect(report.fonts, isEmpty);
      expect(report.downloaded, 0);
    });

    test('reports an unreachable endpoint as a failure', () async {
      await server.close(force: true);

      final report = await FontDownloader.download(
        'Inter',
        fontsDir.path,
        cssEndpoint: endpoint,
      );

      expect(report.failures, hasLength(1));
      expect(report.failures.single.target, 'Inter');
      expect(report.fonts, isEmpty);
    });

    // The state #27 was filed because nobody could reach, and the one #28 had
    // to leave unmeasured. A 200 that parses to no entries reports *success
    // with nothing in it*: no failure, so the CLI exits 0, while the generated
    // theme names a family with no asset behind it. Pinned as it stands today
    // — changing it is #28's decision, not this test's.
    test(
      'a 200 that names no font files reports nothing, not a failure',
      () async {
        final report = await FontDownloader.download(
          'NoFaces',
          fontsDir.path,
          cssEndpoint: endpoint,
        );

        expect(report.fonts, isEmpty);
        expect(report.downloaded, 0);
        expect(report.skipped, 0);
        expect(report.hasFailures, isFalse);
      },
    );
  });

  group('letting go of the connection', () {
    // #23, on the half its fix could never be tested against. The file-writing
    // half has the same test; until the endpoint became nameable, this one
    // could not be written, and the lookup's fix was pinned by nothing.
    test('releases the connection when a non-200 carries a body', () async {
      final report = await FontDownloader.download(
        'Unserved',
        fontsDir.path,
        cssEndpoint: endpoint,
      );

      // Side conditions: a green here must not come from the request having
      // been skipped or the failure having been swallowed.
      expect(report.failures, hasLength(1));
      expect(report.failures.single.reason, contains('400'));
      expect(requested, hasLength(1));

      expect(
        await connectionsAfterSettling(),
        0,
        reason:
            'an unread response body leaves its connection active, and '
            'HttpClient.close() without force destroys only idle ones — so '
            'the socket outlives the run and holds the process open',
      );
    });

    // Whether the VM exits is the observable, and only another process can
    // watch it. The in-process check above cannot stand in: a stalling server
    // never closes its own response, so it keeps counting the connection no
    // matter what the client did.
    test(
      'lets go of a stalled lookup, so the process can still exit',
      () async {
        final child = File('${fontsDir.path}/child.dart')..writeAsStringSync('''
import 'dart:io';
import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';

Future<void> main() async {
  final report = await FontDownloader.download(
    'Stalled',
    Directory.systemTemp.createTempSync('stall_lookup_').path,
    cssEndpoint: Uri.parse('$endpoint'),
  );
  stdout.writeln('REASON \${report.failures.single.reason}');
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
              // One 30-second deadline, plus room for the VM to start.
              const Duration(seconds: 90),
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
              'the child finished its work and then had to be killed: a '
              'socket nobody let go of is still holding the event loop open\n'
              '$printed',
        );
        expect(code, 0);
        // The deadline must not swallow what happened, and it has to be
        // reported as the step that timed out.
        expect(printed, contains('REASON TimeoutException'));
        expect(printed, contains('No response body'));
        expect(printed, contains('CHILD DONE'));
      },
      tags: 'slow',
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Google Fonts CSS naming one weight, served from the same test server.
String _cssFor(String family, int port) => '''
@font-face {
  font-family: '$family';
  font-style: normal;
  font-weight: 400;
  src: url(http://127.0.0.1:$port/f.ttf) format('truetype');
}
''';
