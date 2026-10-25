# font-download

## What it is
In `font_mode: local`, this territory looks up each family in the Google Fonts
CSS2 API, downloads every weight's `.ttf` into `font_dir`, and reports what
landed, what was skipped and what failed. Only files actually on disk are handed
on to be declared.

## Governing decisions
**None.**

## Design model
From the source (the `FontDownloader` dartdoc) and the incidents behind it.
- **Lookup, then files.** `download` asks for weights 100–900 (`_buildCssUrl`),
  parses the `@font-face` blocks (`parseFontEntries`), then `downloadEntries`
  fetches each file. A file already on disk is skipped but still declared.
- **A file is written to `<name>.part` and renamed only once complete.** An
  interrupted transfer cannot look like a font (`_fetchTo`).
- **A failure is reported, never thrown.** A lookup failure names the family as
  `target`, and a file failure names the file. The CLI tells the two apart
  ([cli-run](cli-run.md)).
- **Every response is read to its end.** A connection returns to the pool only
  once its response completes, and `close()` without `force` releases only
  pooled connections. An unread body keeps the process alive after its work is
  done (`_consume`, `_release`; #23 `9dd3b11`).
- **A deadline cancels; it does not just stop waiting.** `Future.timeout`
  abandons the source subscription. Cancelling the subscription is what releases
  the socket. Before any response exists, the release is
  `HttpClientRequest.abort` (`_headers`).
- **30 seconds per step**, applied separately to the headers and to the body.
  `HttpClient.connectionTimeout` bounds only opening the socket (`_timeout`).
- **The query is built as text.** `Uri.queryParameters` would percent-encode the
  `:`, `@` and `;` in the weight list, so only the family name is escaped
  (`_buildCssUrl`; #27 `5ac204b`).
- **Input bound:** time only. No size limit applies to the CSS body or a font
  file.
- **Testing this territory:**
  - **A test seam above the code makes that code unreachable.** Injecting a lookup
    function replaced `_fetchCss`, and under the #23 mutation the test stayed
    green. The `cssEndpoint` parameter replaces only the address, and the same test
    goes red (#27, `5ac204b`, 2026-08-03). Any new seam here has to sit at the
    address, not above the HTTP code.
  - **`HttpOverrides` intercepts a bare `HttpClient()`.** A nested empty
    `runZoned` override recurses until the stack overflows; escape through
    `Zone.root.run` (lessons.md, `5ac204b`).

## Code
- `lib/src/font/font_downloader.dart`: `FontDownloader.download`, `downloadEntries`, `parseFontEntries`, `weightNames`, `defaultCssEndpoint`, `_buildCssUrl`, `_fetchCss`, `_fetchTo`, `_headers`, `_consume`, `_release`, `_timeout`; `DownloadedFont`, `FontEntry`, `FontDownloadFailure`, `FontDownloadReport` (`merge`, `failure`)
- `lib/src/font/font_family.dart`: `FontFamily.fileNameFor`
- tests: `test/font/font_downloader_test.dart`, `font_downloader_download_test.dart`, `font_downloader_lookup_test.dart` (the `slow` tag; see [verification](verification.md))

## Reference behaviour
Probe the real API rather than reasoning about it. The rows below are
measurements recorded on the issues, carried over from `lessons.md`:
- **The real 400 carries a body; the test 404 and 500 had none.** The API
  answers 400 with about 6.8 kB of body for `Segoe UI`, `Arial` and
  `SF Pro Display`. A bodiless non-200 completes on its own and strands nothing,
  which is why the existing 404/500 tests could not fail. Before the fix,
  `download()` returned in 232 ms and the process was still alive at 45 s (#23,
  `9dd3b11`, 2026-08-02).
- **Three more stranding states.** Each was reproduced before the fix:
  - a 200 whose sink fails to open, so nothing ever subscribes;
  - the fix's own body deadline on a stalled peer;
  - the write deadline on a stalled body.
  Each returned on time and left the process alive. The first fix's test passed
  because its peer *failed* instead of *stalling* (#23, `9dd3b11`, 2026-08-02).
- **`HttpClient()` honours the proxy environment.** It routes through
  `http_proxy` / `https_proxy` / `no_proxy` by default (`http_impl.dart`), so a
  proxy's 407 arrives as an ordinary non-200 whose body is not read (lessons.md,
  `9dd3b11`).

## Cross-cutting invariants
- [weight-names](weight-names.md): `weightNames` names the files the scanner reads back

## Blast radius
- [pubspec-fonts](pubspec-fonts.md): it declares exactly what `FontDownloadReport.fonts` lists, so a file reported here that is not on disk becomes a declaration whose asset is missing.
- [cli-run](cli-run.md): the exit-code rule depends on the `target` convention (family name vs file name).
- [font-cleanup](font-cleanup.md), [custom-font-scan](custom-font-scan.md): the file names written here (`FontFamily.fileNameFor`) are what the name guess later recognizes.
- [font-stack](font-stack.md): a non-Google family in the stack becomes a 400 here.
- [font-file-naming](font-file-naming.md): every file name written here comes from `FontFamily.fileNameFor`.

## Known holes / open
- **No size limit** on downloaded bodies (see `## Design model`).
