import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'font_family.dart';

/// A downloaded font file with its metadata.
class DownloadedFont {
  /// Font family name (e.g. `'Inter'`).
  final String family;

  /// Relative path to the downloaded file (e.g. `'fonts/Inter-Regular.ttf'`).
  final String filePath;

  /// CSS font-weight value (100–900).
  final int weight;

  const DownloadedFont({
    required this.family,
    required this.filePath,
    required this.weight,
  });
}

/// A parsed `@font-face` entry from Google Fonts CSS.
class FontEntry {
  final int weight;
  final String url;
  const FontEntry({required this.weight, required this.url});
}

/// Something that could not be obtained, and why.
class FontDownloadFailure {
  /// What failed: a font file name, or the family name when the lookup that
  /// would have named the files is what went wrong.
  final String target;

  /// A human-readable reason, for the CLI to print.
  final String reason;

  const FontDownloadFailure({required this.target, required this.reason});

  @override
  String toString() => '$target: $reason';
}

/// What came of trying to obtain a font's files.
///
/// Only [fonts] may be declared in pubspec.yaml: a declaration pointing at a
/// file that was never written turns into an asset-not-found error on the next
/// Flutter build, with nothing to connect it back to the download.
class FontDownloadReport {
  /// The files that are on disk and safe to declare.
  final List<DownloadedFont> fonts;

  /// How many files this run fetched.
  final int downloaded;

  /// How many files were already on disk and left alone.
  final int skipped;

  /// What could not be obtained.
  final List<FontDownloadFailure> failures;

  const FontDownloadReport({
    required this.fonts,
    required this.downloaded,
    required this.skipped,
    required this.failures,
  });

  /// Nothing was asked for and nothing went wrong.
  static const empty = FontDownloadReport(
    fonts: [],
    downloaded: 0,
    skipped: 0,
    failures: [],
  );

  /// A report covering one failure and nothing else.
  factory FontDownloadReport.failure(String target, String reason) =>
      FontDownloadReport(
        fonts: const [],
        downloaded: 0,
        skipped: 0,
        failures: [FontDownloadFailure(target: target, reason: reason)],
      );

  bool get hasFailures => failures.isNotEmpty;

  /// One line naming what happened, for the CLI summary.
  String get summary =>
      '$downloaded downloaded, $skipped already present, '
      '${failures.length} failed';

  /// Combines the reports of several families into one.
  static FontDownloadReport merge(Iterable<FontDownloadReport> reports) =>
      FontDownloadReport(
        fonts: [for (final r in reports) ...r.fonts],
        downloaded: reports.fold(0, (sum, r) => sum + r.downloaded),
        skipped: reports.fold(0, (sum, r) => sum + r.skipped),
        failures: [for (final r in reports) ...r.failures],
      );
}

/// Downloads .ttf files via a Google Fonts CSS2 API, which is
/// [defaultCssEndpoint] unless a caller names another one.
class FontDownloader {
  FontDownloader._();

  /// Weight value → human-readable suffix for file naming.
  static const weightNames = {
    100: 'Thin',
    200: 'ExtraLight',
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
    800: 'ExtraBold',
    900: 'Black',
  };

  /// Downloads all available weights for [fontName] into [fontsDir].
  ///
  /// [fontsDir] is the absolute path where files are saved.
  /// [relativeDir] is the relative path used in [DownloadedFont.filePath]
  /// (defaults to `'fonts'`).
  ///
  /// Files that already exist on disk are skipped but still reported as
  /// present. Files that could not be obtained are reported as failures and
  /// are left out of [FontDownloadReport.fonts], so nothing declares an asset
  /// that is not there.
  ///
  /// [cssEndpoint] is where the family is looked up, defaulting to
  /// [defaultCssEndpoint]. Point it at a mirror to fetch from somewhere else —
  /// the family and weights are appended to whatever query it already carries,
  /// and the files it names are fetched from wherever the CSS says.
  static Future<FontDownloadReport> download(
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
    Uri? cssEndpoint,
  }) async {
    final List<FontEntry> entries;
    try {
      entries = parseFontEntries(
        await _fetchCss(_buildCssUrl(fontName, cssEndpoint)),
      );
    } catch (error) {
      // A family the endpoint does not serve, or an unreachable endpoint, is
      // a failed download like any other — not a reason to abandon the run
      // before the theme has been written or the other families tried.
      //
      // Whether it should still count as a *failure* once the theme is
      // otherwise usable is #28's decision, not this line's. Left as is.
      final reason = '$error';
      stderr.writeln('  Error: could not look up "$fontName" — $reason');
      return FontDownloadReport.failure(fontName, reason);
    }

    if (entries.isEmpty) {
      stderr.writeln('  Warning: No font files found for "$fontName"');
      return FontDownloadReport.empty;
    }

    return downloadEntries(
      entries,
      fontName,
      fontsDir,
      relativeDir: relativeDir,
    );
  }

  /// Fetches each of [entries] into [fontsDir] for the family [fontName].
  ///
  /// Split out from [download] so the file-writing half can be exercised
  /// against any server, without a CSS lookup in front of it. That used to be
  /// the *only* half a test could reach, and the asymmetry hid two defects
  /// (#27); the lookup is now reachable too, through [download]'s
  /// `cssEndpoint`. This split survives it because entries obtained some other
  /// way are still worth fetching — not because the other half is untestable.
  static Future<FontDownloadReport> downloadEntries(
    Iterable<FontEntry> entries,
    String fontName,
    String fontsDir, {
    String relativeDir = 'fonts',
  }) async {
    final dir = Directory(fontsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final family = FontFamily(fontName);
    final fonts = <DownloadedFont>[];
    final failures = <FontDownloadFailure>[];
    var downloaded = 0;
    var skipped = 0;
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      for (final entry in entries) {
        final weightName = weightNames[entry.weight] ?? 'W${entry.weight}';
        final fileName = family.fileNameFor(weightName);
        final file = File('$fontsDir/$fileName');

        void recordDeclarable() => fonts.add(
          DownloadedFont(
            family: fontName,
            filePath: '$relativeDir/$fileName',
            weight: entry.weight,
          ),
        );

        if (file.existsSync()) {
          stdout.writeln('  Skipping $fileName (already exists)');
          skipped++;
          recordDeclarable();
          continue;
        }

        stdout.writeln('  Downloading $fileName ...');
        final reason = await _fetchTo(client, entry.url, file);
        if (reason != null) {
          stderr.writeln('  Error: could not download $fileName — $reason');
          failures.add(FontDownloadFailure(target: fileName, reason: reason));
          continue;
        }
        downloaded++;
        recordDeclarable();
      }
    } finally {
      client.close();
    }

    return FontDownloadReport(
      fonts: fonts,
      downloaded: downloaded,
      skipped: skipped,
      failures: failures,
    );
  }

  /// Fetches [url] into [file], returning a reason on failure and `null` on
  /// success.
  ///
  /// The body is written to a sibling part file and renamed only once it has
  /// arrived whole, so an interrupted transfer cannot leave behind something
  /// that a later run would mistake for a complete font.
  static Future<String?> _fetchTo(
    HttpClient client,
    String url,
    File file,
  ) async {
    final part = File('${file.path}.part');
    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await _headers(request);
      if (response.statusCode != 200) {
        await _release(response);
        return 'HTTP ${response.statusCode}';
      }

      // Read the body first and hand it to the file, rather than piping the
      // one into the other. `pipe` subscribes to the response only once the
      // sink is ready, so a sink that fails to open leaves the response
      // untouched — a whole body sitting there with nobody reading it, which
      // is the same stranded connection a non-200 used to leave. Feeding the
      // sink by hand separates "did we read the response" from "could we
      // write the file", and only the first one holds a socket.
      sink = part.openWrite();
      await _consume(response, sink.add);
      await sink.close();
      sink = null;

      part.renameSync(file.path);
      return null;
    } catch (error) {
      return '$error';
    } finally {
      // Only reached when the write failed; the happy path already closed it.
      // The sink is never bound to a stream, so `close()` cannot throw the
      // synchronous "StreamSink is bound to a stream" that would escape this
      // `catchError` and displace the failure being reported.
      if (sink != null) await sink.close().catchError((_) {});
      // Cleanup must not become the failure: on a read-only directory the
      // delete throws, and letting it out would abandon the whole run.
      try {
        if (part.existsSync()) part.deleteSync();
      } catch (_) {
        // The part file stays behind. It is never mistaken for a font, and
        // the next successful attempt overwrites it.
      }
    }
  }

  /// Waits for [request]'s response headers, giving up after [_timeout].
  ///
  /// The give-up has to be [HttpClientRequest.abort], not a plain
  /// `.timeout(...)`: at this point there is no response object to let go of,
  /// and abandoning the wait leaves the request in flight on a live socket.
  /// `abort` destroys the connection outright and errors the future we are
  /// awaiting, so the caller sees the timeout and the process can still exit.
  static Future<HttpClientResponse> _headers(HttpClientRequest request) {
    final deadline = Timer(
      _timeout,
      () => request.abort(
        TimeoutException('No response headers within', _timeout),
      ),
    );
    return request.close().whenComplete(deadline.cancel);
  }

  /// Reads [response] to its end, handing every chunk to [onChunk], and lets
  /// the connection go however it ends.
  ///
  /// **A response nobody reads to the end strands its connection.** The client
  /// returns a connection to its pool only once the response completes, and
  /// `HttpClient.close()` without `force` releases only pooled ones — so the
  /// socket outlives the run, keeps a handle on the event loop, and the process
  /// finishes all its work and then never exits.
  ///
  /// **A deadline has to cancel, not merely stop waiting.** `Future.timeout`
  /// completes a *derived* future and leaves the original subscription running,
  /// which releases nothing: a peer that stalls instead of failing still holds
  /// the socket, so the hang comes back with a delay in front of it. Cancelling
  /// the subscription is the release — it closes the incoming message as
  /// *closing*, which destroys the connection rather than pooling it.
  ///
  /// `close(force: true)` would also let go, but [downloadEntries] shares one
  /// client across every file in a family; forcing it would destroy the
  /// transfers still running on it.
  static Future<void> _consume(
    Stream<List<int>> response,
    void Function(List<int> chunk) onChunk,
  ) {
    final completed = Completer<void>();
    StreamSubscription<List<int>>? subscription;
    Timer? deadline;

    void finish([Object? error, StackTrace? stackTrace]) {
      if (completed.isCompleted) return;
      deadline?.cancel();
      subscription?.cancel();
      if (error == null) {
        completed.complete();
      } else {
        completed.completeError(error, stackTrace ?? StackTrace.current);
      }
    }

    subscription = response.listen(
      (chunk) {
        try {
          onChunk(chunk);
        } catch (error, stackTrace) {
          // The write failed, but the socket is ours to release either way.
          finish(error, stackTrace);
        }
      },
      onError:
          (Object error, StackTrace stackTrace) => finish(error, stackTrace),
      onDone: finish,
      cancelOnError: true,
    );

    // Only if the stream did not already finish inside `listen` — an unguarded
    // timer would itself hold the event loop open for [_timeout].
    if (!completed.isCompleted) {
      deadline = Timer(
        _timeout,
        () => finish(TimeoutException('No response body within', _timeout)),
      );
    }
    return completed.future;
  }

  /// Lets go of a response whose body will not be used.
  ///
  /// Reading it is the only way to release the connection (see [_consume]), and
  /// it is cleanup rather than a result: a body that stalls or fails on the way
  /// out must not displace the status the caller is about to report.
  static Future<void> _release(HttpClientResponse response) =>
      _consume(response, (_) {}).catchError((_) {});

  /// How long any one step may take before it counts as failed.
  ///
  /// Applied separately to waiting for headers and to reading a body, because
  /// a server can stall at either point and neither bound implies the other.
  /// [HttpClient.connectionTimeout] does not cover either — it bounds only
  /// establishing the socket.
  static const _timeout = Duration(seconds: 30);

  /// Where a family is looked up unless the caller names somewhere else.
  static final defaultCssEndpoint = Uri.https('fonts.googleapis.com', '/css2');

  /// Builds a CSS2 API URL asking [endpoint] for every standard weight.
  ///
  /// The query is appended as text rather than through [Uri.queryParameters],
  /// which would percent-encode the `:`, `@` and `;` the weight list is made
  /// of. Only the family name is escaped — it is the one part that can carry
  /// a space or a character with its own meaning here.
  static String _buildCssUrl(String fontName, Uri? endpoint) {
    final base = endpoint ?? defaultCssEndpoint;
    final encoded = Uri.encodeComponent(fontName);
    final family = 'family=$encoded:wght@100;200;300;400;500;600;700;800;900';
    final query = base.hasQuery ? '${base.query}&$family' : family;
    return base.replace(query: query).toString();
  }

  /// Fetches CSS from a Google Fonts CSS2 API.
  ///
  /// The default Dart User-Agent causes Google Fonts to return TTF format URLs.
  static Future<String> _fetchCss(String url) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await _headers(request);
      if (response.statusCode != 200) {
        await _release(response);
        // Names the host rather than "Google Fonts": the endpoint is the
        // caller's to choose, and a mirror's failure must not be reported as
        // Google's.
        throw StateError(
          '${Uri.parse(url).host} returned HTTP ${response.statusCode}',
        );
      }
      // Collected through [_consume] rather than `transform(...).join()` so
      // that this read is bounded too. A 200 whose body then stalls used to
      // hang here with nothing to stop it — worse than the non-200 case, which
      // at least finished its work first.
      final body = <int>[];
      await _consume(response, body.addAll);
      return utf8.decode(body);
    } finally {
      client.close();
    }
  }

  /// Parses `@font-face` rules from Google Fonts CSS, extracting weight and URL.
  static List<FontEntry> parseFontEntries(String css) {
    final results = <FontEntry>[];
    final facePattern = RegExp(r'@font-face\s*\{([^}]+)\}', multiLine: true);

    for (final match in facePattern.allMatches(css)) {
      final block = match.group(1)!;

      final weightMatch = RegExp(r'font-weight:\s*(\d+)').firstMatch(block);
      final urlMatch = RegExp(r"url\(([^)]+\.ttf)\)").firstMatch(block);

      if (weightMatch != null && urlMatch != null) {
        results.add(
          FontEntry(
            weight: int.parse(weightMatch.group(1)!),
            url: urlMatch.group(1)!,
          ),
        );
      }
    }

    return results;
  }
}
