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
