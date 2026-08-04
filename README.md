# flutter_tweakcn_generator

A code generator that converts [tweakcn](https://tweakcn.com) CSS themes into Flutter `ThemeData`, `ColorScheme`, and `ThemeExtension` classes.

## Features

- **Color formats**: `hex`, `rgb()`, `hsl()`, `oklch()`
- **Light / Dark mode**: auto-split from `:root` / `.dark` blocks
- **ColorScheme** mapping
- **ThemeExtension** generation: Colors, Radius, Shadows
- **Google Fonts**: auto-detects `--font-sans` and generates `GoogleFonts.xxxTextTheme()` with `fontFamilyFallback` support
- **Local Fonts**: `font_mode: local` downloads `.ttf` files at build time and uses `fontFamily` directly (no runtime dependency)
- **Custom Fonts**: `font_mode: custom` uses user-provided `.ttf` files for fonts not available on Google Fonts
- **BuildContext extensions**: `context.tweakcnColors`, `context.tweakcnRadius`, `context.tweakcnShadows`
- **CLI** and **build_runner** support

## Getting Started

### 1. Install

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_tweakcn_generator: ^0.5.1
```

### 2. Prepare CSS

Customize your theme at [tweakcn.com](https://tweakcn.com), copy the CSS, and save it as `tweakcn.css` in your project root.

```css
:root {
  --background: #ffffff;
  --foreground: #0a0a0a;
  --primary: #171717;
  --primary-foreground: #fafafa;
  /* ... */
  --font-sans: 'Inter', sans-serif;
  --radius: 0.625rem;
}

.dark {
  --background: #0a0a0a;
  --foreground: #fafafa;
  /* ... */
}
```

### 3. Generate

```bash
dart run flutter_tweakcn_generator
```

Reads `tweakcn.css` and generates `lib/theme/tweakcn_theme.g.dart` by default.

If a Google Font is detected in `--font-sans`, the `google_fonts` package is automatically added to your `pubspec.yaml`.

#### Exit codes

**`0` means the theme is usable as generated.** That is the whole rule; the two
non-zero values only say which side of it a run fell on.

| Code | Meaning | Example |
|---|---|---|
| `0` | Everything the theme needs is in place | — |
| `1` | Nothing was generated | no CSS file at the configured `input` |
| `2` | The theme was written, but something it needs is not in place | the theme names a font family `pubspec.yaml` does not declare; a font file could not be downloaded; `dart pub add google_fonts` failed |

For fonts the question is asked **at the end, about the result** — not about
what went wrong on the way there. In `local` and `custom` modes the run exits
`2` when the generated theme names a family that `pubspec.yaml` does not
declare, because Flutter then falls back to the default font at runtime with no
error anywhere. Two consequences worth knowing:

- A failed lookup on its own is **not** `2`. Re-running with the network down,
  when every font is already downloaded and declared, exits `0` — the theme is
  usable, which is the whole rule. The failure is still reported on stderr.
- `font_mode: custom` with no matching `.ttf`, and a lookup that returns no
  font files, now exit `2` rather than `0`. Both used to report success while
  leaving the theme pointing at a font that would silently fall back.

`2` is not "worse" than `1` — exit codes are categories, not a scale. It exists
so a script driving this CLI can tell "no theme was produced" from "the theme is
there and one font is missing" without parsing the output. A caller that only
cares whether anything went wrong can keep checking for non-zero.

These are the only three values. An unexpected failure — an unwritable path, a
config value of the wrong type — is reported the same way: `1` if it happened
before the theme file was written, `2` if after.

### 4. Usage

```dart
import 'theme/tweakcn_theme.g.dart';

MaterialApp(
  theme: TweakcnTheme.light,
  darkTheme: TweakcnTheme.dark,
);
```

Access tokens in widgets:

```dart
// Colors
final bg = context.tweakcnColors.background;
final primary = context.tweakcnColors.primary;
final sidebarBg = context.tweakcnColors.sidebar;

// Radius
final borderRadius = BorderRadius.circular(context.tweakcnRadius.lg);

// Shadows
Container(
  decoration: BoxDecoration(
    boxShadow: context.tweakcnShadows.shadowMd,
  ),
);
```

## Configuration

Customize settings in `pubspec.yaml`:

```yaml
flutter_tweakcn_generator:
  input: tweakcn.css                        # CSS file path (default)
  output: lib/theme/tweakcn_theme.g.dart    # output path (default)
  class_prefix: Tweakcn                     # class name prefix (default)
  font_mode: google_fonts                   # google_fonts (default) | local | custom
  font_dir: fonts                           # local font directory (default: fonts)
  font_exclusive: false                     # auto-clean unused fonts (default: false, local mode only)
  font_exclusive_allow_empty: false         # clean up even when no --font-sans is declared (default: false)
```

When `font_exclusive: true` is set with `font_mode: local`, fonts in the `fonts/` directory that are no longer referenced by `--font-sans` are automatically deleted, and their `flutter > fonts` declarations are removed from `pubspec.yaml`. Useful when switching fonts to keep the project clean.

Cleanup is skipped with a warning when no `--font-sans` is found in the `:root` block, since deleting every font file on the basis of a parsing miss is not recoverable in `custom` mode. Switching `--font-sans` to a pure system stack (`ui-sans-serif, system-ui, ...`) still cleans up as before — that is a declared intent, not a missing value.

Set `font_exclusive_allow_empty: true` to clean up anyway when the CSS declares no `--font-sans` at all.

Changing `class_prefix` renames the generated classes:

```dart
// class_prefix: My
MyTheme.light
context.myColors.primary
context.myRadius.lg
context.myShadows.shadowMd
```

## build_runner

Name the CSS with the `*.tweakcn.css` extension and generate with build_runner:

```bash
dart run build_runner build
```

Each `<name>.tweakcn.css` becomes a `<name>.tweakcn.dart` beside it, so
`lib/app.tweakcn.css` generates `lib/app.tweakcn.dart`. The `input` and
`output` settings under `flutter_tweakcn_generator:` in `pubspec.yaml` are for
the CLI and have no effect here — build_runner decides both from the input's
own path.

Configure builder options in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      flutter_tweakcn_generator|tweakcn:
        options:
          class_prefix: Tweakcn       # class name prefix (default)
          font_mode: google_fonts     # google_fonts (default) | local | custom
```

## Generated Code

| Output | Description |
|---|---|
| `ColorScheme` (light/dark) | CSS colors mapped to Material ColorScheme |
| `TweakcnColors` | All color tokens (ThemeExtension), plus a `fromMap` factory |
| `TweakcnRadius` | sm, md, lg, xl (ThemeExtension) |
| `TweakcnShadows` | shadow-2xs through shadow-2xl (ThemeExtension) |
| `TweakcnTheme` | `ThemeData.light` / `ThemeData.dark` |
| `TweakcnBuildContext` | Convenience extensions like `context.tweakcnColors` |

### Building a theme at runtime

`TweakcnTheme.light` and `TweakcnTheme.dark` are baked in at generation time.
To render a theme the user supplies — pasting tweakcn CSS and previewing it
live, say — parse the CSS and hand the tokens to the generated factory:

```dart
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';

import 'theme/tweakcn_theme.g.dart';

final theme = CssParser.parse(css);

MaterialApp(
  theme: ThemeData(
    extensions: [
      TweakcnColors.fromMap(theme.light.colors),
      TweakcnRadius.fromRadius(theme.light.radius ?? theme.dark.radius),
      TweakcnShadows.fromShadowMap(theme.light.shadowLayers),
    ],
  ),
);
```

`fromMap` takes the parsed token map — CSS variable names without `--`, mapped
to 32-bit ARGB — and covers exactly the tokens the generator writes, so it
keeps covering them when tokens are added. A token the CSS does not define gets
the same transparent placeholder the generated constants use, which means
building from a theme's own tokens reproduces that theme's constants.

`fromRadius` derives the four steps the same way the generated constant does:
`lg` is the radius itself, `md` two less, `sm` four less, `xl` four more, and
no step goes below zero. Pass `null` for a theme that declares no `--radius`
and it falls back to the same base the constant was built from. A `ThemeData`
carries one radius, so hand it light's and fall back to dark's, exactly as the
generator does.

Those offsets are **tweakcn's own**, copied rather than invented: the CSS
tweakcn emits derives the steps as `calc(var(--radius) - 4px)`,
`calc(var(--radius) - 2px)`, `var(--radius)` and `calc(var(--radius) + 4px)`,
so these four values are what a browser computes from the same theme. Holding a
step at zero matches that too — CSS Values 4 §calc-range clamps a negative
`calc()` result to the range its property allows rather than invalidating the
declaration, and its own example is this shape: `width: calc(5px - 10px)` is
equivalent to `width: 0px`. Note that shadcn/ui derives the same steps by
scaling (`* 0.6`, `* 0.8`, `* 1.4`) and the two formulas agree at exactly one
radius, 10px, which happens to be tweakcn's default. This package follows
tweakcn, because tweakcn is what produced the CSS you pasted.

`fromShadowMap` takes the levels keyed by CSS variable name, each holding its
layers in paint order. A level the CSS does not define comes out empty, as it
does in the constants. Shadow layers are the one token that is not a plain
number, so the generated file declares a record type for them:

```dart
typedef TweakcnShadowLayer = ({
  double offsetX,
  double offsetY,
  double blurRadius,
  double spreadRadius,
  int color,
});
```

`ThemeModeData.shadowLayers` produces exactly that shape, so you never write it
out yourself — but because a record is structural, you can, without importing
anything.

None of these factories name a type from this package, so the generated file
keeps importing Flutter and nothing else, and passing their results around
costs you no dependency. Only `CssParser` does — parsing at runtime means moving
`flutter_tweakcn_generator` from `dev_dependencies` to `dependencies`. If your
CSS is fixed at build time you do not need any of this: use `TweakcnTheme.light`
and `TweakcnTheme.dark`.

### ColorScheme Mapping

| CSS Variable | ColorScheme Property |
|---|---|
| `--background` | `surface` |
| `--foreground` | `onSurface` |
| `--primary` | `primary` |
| `--primary-foreground` | `onPrimary` |
| `--secondary` | `secondary` |
| `--secondary-foreground` | `onSecondary` |
| `--destructive` | `error` |
| `--destructive-foreground` | `onError` |
| `--border` | `outline` |
| `--input` | `outlineVariant` |
| `--card` | `surfaceContainerLowest` |
| `--muted` | `surfaceContainerHighest` |
| `--muted-foreground` | `onSurfaceVariant` |

The first eight rows are `required` parameters of Flutter's `ColorScheme`, so they are always emitted. When your CSS does not define one, a fallback is substituted and the token is named in a warning: `on*` colors become black or white by contrast against their base color, a missing `secondary` reuses `primary`, and anything left over falls back to Material's own baseline. The remaining rows are optional and are emitted only when defined.

### Google Fonts

When `--font-sans` contains a specific font name, a `textTheme` is generated using the `google_fonts` package:

```css
/* Generates: GoogleFonts.interTextTheme() */
--font-sans: 'Inter', sans-serif;

/* Generates: GoogleFonts.notoSansKrTextTheme() */
--font-sans: 'Noto Sans KR', sans-serif;

/* No generation (system font stack) */
--font-sans: ui-sans-serif, system-ui, sans-serif;
```

#### Font Fallback

Multiple Google Fonts in `--font-sans` are supported as fallback fonts. The first font becomes the primary `textTheme`, and the rest are added to `fontFamilyFallback`. This is useful for CJK (Korean, Japanese, Chinese) font support:

```css
/* Primary: Architects Daughter, Fallback: Noto Sans KR */
--font-sans: 'Architects Daughter', 'Noto Sans KR', sans-serif;
```

Generates:

```dart
textTheme: GoogleFonts.architectsDaughterTextTheme().apply(
  fontFamilyFallback: [GoogleFonts.notoSansKr().fontFamily!],
),
```

Characters not found in the primary font (e.g. Korean) automatically fall back to the next font.

### Local Fonts

Set `font_mode: local` to download `.ttf` files at generation time instead of using the `google_fonts` package at runtime:

```yaml
flutter_tweakcn_generator:
  font_mode: local
```

When you run `dart run flutter_tweakcn_generator`:

1. `.ttf` files are downloaded from Google Fonts into the `fonts/` directory (customizable via `font_dir`)
2. `pubspec.yaml` is updated with `flutter > fonts` declarations
3. Generated code uses `fontFamily` / `fontFamilyFallback` instead of `GoogleFonts`

```dart
// font_mode: local
static ThemeData get light => ThemeData(
  fontFamily: 'Architects Daughter',
  fontFamilyFallback: ['Noto Sans KR'],
  // ...
);
```

This is useful when you want to avoid runtime font downloads or need to work offline.

### Custom Fonts

Set `font_mode: custom` to use your own `.ttf` files that are not available on Google Fonts:

```yaml
flutter_tweakcn_generator:
  font_mode: custom
  font_dir: fonts   # directory containing your .ttf files
```

Place your `.ttf` files in the `fonts/` directory with the naming convention `{FontName}-{Weight}.ttf`:

```
fonts/
  MyCustomFont-Regular.ttf
  MyCustomFont-Bold.ttf
  MyCustomFont-Light.ttf
```

Supported weight suffixes: `Thin` (100), `ExtraLight` (200), `Light` (300), `Regular` (400), `Medium` (500), `SemiBold` (600), `Bold` (700), `ExtraBold` (800), `Black` (900).

When you run `dart run flutter_tweakcn_generator`:

1. `.ttf` files matching the `--font-sans` font name are scanned from the `fonts/` directory
2. `pubspec.yaml` is updated with `flutter > fonts` declarations (with auto-detected weights)
3. Generated code uses `fontFamily` / `fontFamilyFallback` (same as `local` mode)

If no matching `.ttf` files are found, a warning is printed and font registration is skipped.

## Platform Setup (Google Fonts)

When using `google_fonts`, the app needs network access to download fonts at runtime. The following platform-specific configuration is required:

### macOS

Add `com.apple.security.network.client` to both entitlements files:

**`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`**:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

> Without this, macOS sandbox blocks outgoing connections and you'll get `Operation not permitted` errors.

### Android

Add the `INTERNET` permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    ...
</manifest>
```

> The `debug/AndroidManifest.xml` includes this by default, but **release builds require it in `main`**.

### iOS / Windows / Web

No additional configuration needed. Network access is allowed by default.

## Supported Color Formats

```css
--primary: #171717;                /* hex */
--primary: rgb(23, 23, 23);       /* rgb */
--primary: hsl(0 0% 9%);          /* hsl */
--primary: oklch(0.21 0 0);       /* oklch */
```

## Guides

- [Using with Riverpod](doc/riverpod.md)

## Development

```bash
dart test           # the generator's own test suite
dart test -P fast   # the same, minus the tests that wait out a real deadline
```

`-P fast` is for the edit loop, never for a gate. The tests it skips are tagged
`slow` because they let the downloader's 30-second timeout actually expire —
which is the only honest way to show it lets go of a peer that stalls rather
than fails, and it costs about a minute and a half.

The suite checks the *text* the generator emits. It cannot check that the text
compiles, because this package generates Flutter source without depending on
Flutter. That takes a second command:

```bash
cd example && flutter pub get && cd ..
dart run tool/verify_generated_output.dart
```

It generates a theme for the inputs that stress the generator differently — a
complete theme, a minimal one, one with no colors at all, one that defines only
the `.dark` block, and one per way the theme class can name a font — analyzes
them inside `example/` where `package:flutter` resolves, and deletes them
again. It exits non-zero and reprints the analyzer's own message when any of
them fails to compile.

It also checks that the theme committed under `example/` is still what the
generator writes for the example's CSS. If it is not, regenerate it — the
example is committed exactly as generated, so that it shows what a consumer's
output actually looks like:

```bash
cd example && dart run flutter_tweakcn_generator
```

Run it whenever you change what the generator emits. `dart test` compares the
emitted text against text, so it cannot catch a generated file that does not
build: a `ColorScheme` missing a parameter a new Flutter release made
`required`, an unbalanced `textTheme: ...apply(...)`, or a `GoogleFonts` method
name derived from a family that the package does not spell that way.

CI runs both commands on every push and pull request.

## License

MIT
