## Unreleased

- **CHANGE**: the exit code now reflects whether the theme's fonts are actually there, rather than whether something went wrong on the way to putting them there. `0` was already documented to mean "the theme is usable as generated", and fonts broke that rule on **both** sides of one axis. A run whose fonts were entirely in place answered `2` because the CSS lookup failed — the shape a re-run with the network briefly down takes, where every file is already downloaded and declared and nothing about the theme is missing; measured, the same project answers `2` offline and `0` online with the theme, pubspec and disk identical. And a run whose theme named a family with nothing behind it answered `0`: `font_mode: custom` with no matching `.ttf`, or a lookup that returns CSS naming no font files, both wrote a theme with `fontFamily` set, declared nothing in `pubspec.yaml`, and reported success — Flutter then falls back to the default font at runtime with no error anywhere, which is precisely the silence an exit code exists to break. Both are now one check, asked at the end: in `local` and `custom` modes, a generated theme naming a family `pubspec.yaml` does not declare exits `2`. It is per family, so a stack whose first font is ready and whose second is not is reported rather than averaged away. A file that failed to *download* still exits `2` as before — that is a weight the theme asked for and did not get. Callers reading only "non-zero" are unaffected; a caller treating `2` as "fonts are fine, ignore" now hears about a case it previously could not

- **ADD**: `FontDownloader.download` takes an optional `cssEndpoint`, and `FontDownloader.defaultCssEndpoint` names where it goes by default. Point it at a mirror and the family lookup happens there instead; the family and weights are appended to whatever query the endpoint already carries, and the font files are still fetched from wherever the returned CSS names them. Purely additive — callers that omit it get exactly what they got before. What motivated it is not configuration but **reach**: the lookup half of the downloader was bound to a hardcoded URL, so no test could run a single line of it, and the same defect hid there twice. #23's fix — reading a non-200's body so its connection is released, without which the CLI finished its work and then never exited — was applied to both halves but could only ever be *tested* on the file-writing half, which had been split out for exactly that reason; the lookup half's copy was pinned by nothing, and a mutation test confirms it: delete that line today and the new suite goes red, where before nothing in the repo would have noticed. The second was never reproduced at all until now — a lookup that answers `200` with CSS containing no `@font-face` returns an empty report with no failure, so the run exits `0` while the generated theme names a font family with no asset behind it. That state now has a test pinning what it does today; whether it *should* report a failure is #28's decision and is deliberately not settled here

- **CHANGE**: a failed lookup now names the host that answered rather than saying "Google Fonts API". With the endpoint configurable, a mirror's failure must not be reported as Google's

- **CHANGE**: the CLI now exits `2` when it wrote a theme but could not put something that theme needs in place — a font it could not download, or a `dart pub add google_fonts` that failed. `1` now means only that nothing was generated at all, and `0` keeps its meaning: the theme is usable as generated. Previously a single failed font and a missing CSS file both answered `1`, so a caller reading the exit code could not tell "no theme was produced" from "the theme is there and one font is missing" — and that ambiguity costs real work: a builder driving this CLI as a pipeline step had moved the step to the end of its pipeline, because one failed font looked exactly like total failure and skipped every step after it. A caller that only checks for non-zero is unaffected; one that branches on `1` keeps catching the case it cared about, since the hard failure stayed there deliberately. Note that `2` is not "worse" than `1` — exit codes are categories, not a scale

- **FIX**: an unexpected failure no longer escapes as an uncaught exception. `main` had no top-level catch, so anything that threw left the VM's own exit code — `255`, a fourth value the three above do not describe — and the paths that reach it fall on *both* sides of the line those values draw: a config value of the wrong YAML type throws before anything is written, while a pubspec this process may not rewrite throws after the theme is already on disk. The one distinction the exit codes promise to make was the one thing they stopped making, and a single word reaches it: `font_exclusive: yes` is a YAML *string*, and the cast to `bool?` throws. Such a failure is now reported like any other and classified the same way — `1` before the theme is written, `2` after — with its stack trace, since by construction these are the unplanned ones

- **FIX**: a commented-out `# google_fonts:` line no longer counts as a declaration. The check was a substring search over the whole `pubspec.yaml` text, so a commented-out entry — or the word appearing under any other key — suppressed `dart pub add` entirely and the run reported success while the generated theme imported a package the project did not declare. That is the same unresolvable project the entry above describes, reached through the one door that skipped the check. The dependency sections are now parsed; `dev_dependencies` and `dependency_overrides` count too, since `pub add` refuses a package already named in any of them

- **FIX**: a `dart pub add google_fonts` that fails no longer reports success. It set no exit code at all, so a run that left the generated theme importing `package:google_fonts` while the project declared no such dependency — a project that cannot resolve — came back as `0`. It is now one of the `2` cases, and the message says what the project is left holding

- Fix the CLI not exiting when a font lookup or download goes wrong. Everything was printed, the theme and pubspec were already written correctly, and the process then sat there until it was killed. A connection returns to the client's pool only once its response completes, and closing the client releases only pooled ones — so any response that was never read to the end kept its socket, and the socket kept a handle on the event loop. Four ways in, all of them reachable: a non-200 whose body was discarded unread; a 200 whose local file could not be opened, where the body arrived in full and nothing ever subscribed to it; a peer that sent headers and then stalled, where the 30-second deadline abandoned the wait without letting go of anything; and the same stall before any headers arrived. The non-200 case is the easy one to hit — `Segoe UI`, `Arial` and `SF Pro Display` all answer 400 and all sit at the front of the font stack tweakcn commonly emits. Reading a response to its end is now what releases it, every read is bounded, and a deadline **cancels** rather than merely stopping the wait, because `Future.timeout` completes a derived future and leaves the original subscription running — which released nothing and turned a hang into a delayed hang. Waiting for headers gives up with `HttpClientRequest.abort`, which is the only release available before there is a response to let go of

- The CSS lookup's response body is now read under the same 30-second deadline as everything else. It had none, so a server that returned 200 and then stalled hung the generator outright rather than failing — the case the deadline's own documentation claimed it prevented

- A download that fails while writing now reports the write's error instead of `Bad state: StreamSink is bound to a stream`. The body is read and handed to the file rather than piped into it, so the sink is never bound to a stream, and `IOSink.close()` — which throws that error *synchronously*, outrunning the `catchError` meant to absorb it — no longer has the case to throw on

## 0.4.0

Generated themes can now be built at runtime, not only baked in at generation
time: each extension gets a factory over the tokens the parser produces. The
generated file still imports Flutter and nothing else.

This release adds `dart_style` and `pub_semver` as dependencies, both used to
format the generated output. `dart_style` is constrained deliberately widely —
see the note in `pubspec.yaml` before changing it.

- Fix generated files failing `dart format` in a project that declares an older SDK. `dart format` takes its language version from the `environment: sdk:` constraint of the package it runs in, and formats differently across versions; the generator was formatting at the newest version it could resolve. A project declaring `>=3.7.0 <4.0.0` — the constraint this package declares for itself — got a file that failed its own format check. Both the CLI and the builder now read the consuming project's constraint and format at that version

- Fix the build_runner builder producing nothing at all. It asked to write `<name>.tweakcn.tweakcn.dart` while declaring `<name>.tweakcn.dart`, and build_runner refuses an output a builder did not declare — so `dart run build_runner build` failed outright rather than writing a misnamed file. One of the two documented ways to use this package had never worked, because nothing exercised the builder: `build_test` was a dev dependency no test used. It now is

- Generated files are now formatted, so a project that runs a format check over its own `lib/` no longer fails it the moment it generates. Previously the output was assembled as strings and written as-is, which left 41 lines of a typical theme past the page width. Note that `dart_style` is now a dependency, deliberately with a wide constraint: the analyzer that the newest one needs wants a newer `meta` than the Flutter SDK pins, so a tight constraint would make this package unresolvable in a Flutter project

- Generated theme extensions now compare by value. They previously had no `==`, so an extension equalled only itself — harmless while the only instances were the baked-in constants, since those are `const`, but not once `fromMap`, `fromRadius` and `fromShadowMap` started building a new one per call. `ThemeData` compares its extensions by value, so a theme rebuilt from unchanged tokens did not equal the previous one and every dependent of `Theme.of` rebuilt. Shadow levels are compared and hashed layer by layer, since a list is equal only to itself too

- Font declarations added to a pubspec that uses CRLF line endings now use them too, instead of leaving the file with two kinds

- Fix `font_exclusive` cleanup turning `pubspec.yaml` into invalid YAML on a file with CRLF line endings — the ordinary state of a checkout on Windows. Family declarations were matched with a pattern that cannot see past the `\r`, so every family read as belonging to no family: the declarations were left in place while the `fonts:` key above them was deleted, leaving `flutter:` mapped to a list and everything after it misindented. It fired on runs that had nothing to clean up, reported success, and exited 0. Cleanup now writes each line back with the ending it came in with, so a run that removes nothing leaves the file byte-identical

- Generated colors extensions now expose a `fromMap` factory, so a tool that parses tweakcn CSS at runtime can turn the parsed tokens into the extension instead of re-writing that mapping by hand — a copy that drifts silently, showing no error when the generator adds a token, only a color that stops updating. Building from a theme's own tokens reproduces that theme's generated constant, and a token the CSS does not define gets the same transparent placeholder the constants use. The signature stays in primitives (`Map<String, int>`), so the generated file still imports Flutter and nothing else
- Generated shadows extensions now expose a `fromShadowMap` factory, completing the set. Shadow layers are the one parsed token that is not a plain number, so the generated file declares a record type for them — `({double offsetX, double offsetY, double blurRadius, double spreadRadius, int color})` — which names no class from this package and still has its field names checked by the compiler, where a map of strings would have turned a typo into a silently missing value. `ThemeModeData.shadowLayers` converts a parsed theme into that shape, and `ShadowData.toLayer` converts one layer
- Generated radius extensions now expose a `fromRadius` factory, for the same reason: the derivation from one parsed radius to the four steps lived only in the generator, so a runtime consumer had to reimplement the shadcn arithmetic and would drift from it if it ever changed. It takes a nullable radius, since the CSS need not declare one, and falls back to the same base the generated constant does

- Fix `--font-sans` being read from the light theme only, so a CSS file that names its font solely in the `.dark` block got no font at all — no text theme, nothing downloaded, and an empty family list feeding `font_exclusive` cleanup. Detection now prefers light and falls back to dark
- Warn when light and dark name different font stacks, since a `ThemeData` carries one font family and only the light stack is used

- Fix only the first `:root` and `.dark` block being read, so a theme split across blocks — a bare `:root` plus another inside `@layer base`, say — silently lost everything after the first. All blocks are now merged in source order, with later declarations overriding earlier ones
- A descendant selector such as `.dark .card` is no longer mistaken for the `.dark` block itself, while a selector list (`.dark, .dark *`) and a qualified selector (`html.dark`) are both recognized
- Declarations inside a conditional at-rule such as `@media print` no longer override the ones that always apply; they are used only when the selector has no unconditional block at all

- Fix `rem` and `em` lengths in `box-shadow` values being used as raw numbers, so a `0.25rem` offset generated 0.25px instead of 4px — a 16× error against the same unit in `--radius`. Radii, spacing and shadows now share one length conversion
- `--radius` and `--spacing` accept `em` as well as `rem`, accept units in any case, and no longer accept malformed values such as `1px2`

- Fix a font that failed to download still being declared in `pubspec.yaml`, which turned into an asset-not-found error on the next Flutter build with nothing to connect it back to the download. Only files present on disk are declared
- Font files are written to a part file and renamed once complete, so an interrupted transfer cannot leave behind something a later run mistakes for a finished font
- A failed download is now reported as an error, counted in the run summary alongside downloaded and already-present files, and makes the CLI exit non-zero
- A font family the Google Fonts API does not serve no longer aborts the whole run with an unhandled exception before the theme is written; it is reported as a failed download like any other
- Font requests now time out after 30 seconds instead of hanging the generator indefinitely on a stalled server
- **Breaking (library API):** `FontDownloader.download` returns a `FontDownloadReport` rather than a `List<DownloadedFont>`. The declarable fonts are on `report.fonts`

- Fix `font_exclusive` cleanup keeping the files of a family whose name merely extends a defined one. Cleanup now takes each file's family from the `flutter > fonts` declarations in pubspec.yaml rather than guessing from the file name, so defining only `Roboto` removes a leftover `RobotoSlab-Bold.ttf` while leaving an `InterVariable.ttf` that `Inter` really does own. Files pubspec has never declared are still matched by name, which errs toward keeping them
- `CustomFontScanner` no longer claims a file that pubspec already declares under another family, so a leftover file is not re-declared under the wrong family and made permanently uncleanable
- Font file names are now matched case-insensitively, so a hand-named `inter-bold.ttf` is recognized as `Inter`'s rather than deleted as an unknown family's, and `.TTF` files are treated as fonts. Note that an unused `.TTF` file is now removed by cleanup where it was previously left in place
- Fix a font family being skipped when its name is a prefix of an already-declared family, so declaring `Roboto` alongside `Roboto Slab` no longer silently does nothing
- Existing font declarations are now read with a YAML parser instead of a substring search, so a family named in a comment, in an asset path, or under a key other than `flutter > fonts` no longer counts as declared, and a quoted family name is recognized as itself
- Fix the last declaration in a `:root` or `.dark` block being dropped when it omits its trailing semicolon, which CSS permits
- Strip `/* ... */` comments before parsing, so a commented-out declaration is no longer read as real and a brace inside a comment no longer breaks block extraction
- Fix generated `ColorScheme` omitting parameters Flutter marks `required`, which made the generated file fail to compile when the CSS did not define every mapped token. Missing colors now fall back to a contrast-derived or Material baseline value, and the CLI warns which tokens were substituted
- Fix `font_exclusive` deleting every font file and font declaration when `--font-sans` could not be found in `:root` or was declared blank. Cleanup is now skipped with a warning; switching to a system font stack still cleans up as before
- Add `font_exclusive_allow_empty` option to opt back into cleaning up when no `--font-sans` is declared
- `FontCleanup.cleanFontsDirectory` and `PubspecFontAdder.removeUndefinedFonts` now ignore an empty family list unless the new `allowEmpty` argument is set

## 0.3.0

- Add `font_mode: custom` for user-provided `.ttf` files not available on Google Fonts
- Auto-scan font directory and infer font weights from file names (e.g. `MyFont-Bold.ttf` → weight 700)
- `font_exclusive` cleanup now supports `custom` mode

## 0.2.3

- Add `font_dir` option to customize local font download directory (default: `fonts`)

## 0.2.2

- Fix `font_exclusive` not cleaning up fonts when switching to system font stack
- Add missing `font_exclusive` and `build.yaml` options to README

## 0.2.1

- Add `font_exclusive: true` option for `font_mode: local`: automatically removes font files and `pubspec.yaml` font declarations not defined in `--font-sans`
- Auto-clean `fonts/` directory: deletes `.ttf` files that don't belong to any defined font family
- Auto-clean `pubspec.yaml`: removes unused `flutter > fonts` family blocks

## 0.2.0

- Add `font_mode: local` option: downloads `.ttf` files from Google Fonts and generates `fontFamily` / `fontFamilyFallback` code without `google_fonts` runtime dependency
- Auto-download font files into `fonts/` directory
- Auto-add `flutter > fonts` declarations to `pubspec.yaml`
- Support both `google_fonts` (default) and `local` font modes via `pubspec.yaml` configuration

## 0.1.4

- Add `fontFamilyFallback` support: multiple Google Fonts in `--font-sans` are now used as primary + fallback fonts (e.g. `Architects Daughter, Noto Sans KR, sans-serif`)

## 0.1.3

- Widen `build` dependency to `>=2.0.0 <5.0.0` for broader compatibility
- Widen `build_test` dependency to `>=2.0.0 <4.0.0`
- Widen `build_runner` dependency to `>=2.0.0 <3.0.0`

## 0.1.2

- Widen `build` dependency to `>=3.0.0 <5.0.0` for broader compatibility
- Widen `build_test` dependency to `>=2.0.0 <4.0.0`

## 0.1.1

- Update `build` dependency to `^4.0.0`
- Remove unused `source_gen` dependency
- Require Dart SDK `>=3.7.0`

## 0.1.0

- Initial release
- CSS parser: `:root` (light) / `.dark` (dark) block parsing
- Color formats: hex, rgb, hsl, oklch
- Shadow parsing: CSS box-shadow to `List<BoxShadow>`
- Google Fonts support: `--font-sans` CSS variable to `GoogleFonts.xxxTextTheme()` generation
- Code generation: `ColorScheme`, `ThemeExtension` (Colors, Radius, Shadows), `ThemeData`
- CLI: `dart run flutter_tweakcn_generator`
- build_runner: `*.tweakcn.css` → `*.tweakcn.dart`
