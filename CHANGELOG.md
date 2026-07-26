## Unreleased

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
