## Unreleased

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
