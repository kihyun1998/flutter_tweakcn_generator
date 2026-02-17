# flutter_tweakcn_generator

A code generator that converts [tweakcn](https://tweakcn.com) CSS themes into Flutter `ThemeData`, `ColorScheme`, and `ThemeExtension` classes.

## Features

- **Color formats**: `hex`, `rgb()`, `hsl()`, `oklch()`
- **Light / Dark mode**: auto-split from `:root` / `.dark` blocks
- **ColorScheme** mapping
- **ThemeExtension** generation: Colors, Radius, Shadows
- **Google Fonts**: auto-detects `--font-sans` and generates `GoogleFonts.xxxTextTheme()` with `fontFamilyFallback` support
- **BuildContext extensions**: `context.tweakcnColors`, `context.tweakcnRadius`, `context.tweakcnShadows`
- **CLI** and **build_runner** support

## Getting Started

### 1. Install

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_tweakcn_generator: ^0.1.4
  

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
```

Changing `class_prefix` renames the generated classes:

```dart
// class_prefix: My
MyTheme.light
context.myColors.primary
context.myRadius.lg
context.myShadows.shadowMd
```

## build_runner

Use the `*.tweakcn.css` extension to generate via build_runner:

```bash
dart run build_runner build
```

## Generated Code

| Output | Description |
|---|---|
| `ColorScheme` (light/dark) | CSS colors mapped to Material ColorScheme |
| `TweakcnColors` | All color tokens (ThemeExtension) |
| `TweakcnRadius` | sm, md, lg, xl (ThemeExtension) |
| `TweakcnShadows` | shadow-2xs through shadow-2xl (ThemeExtension) |
| `TweakcnTheme` | `ThemeData.light` / `ThemeData.dark` |
| `TweakcnBuildContext` | Convenience extensions like `context.tweakcnColors` |

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

## License

MIT
