# flutter_tweakcn_generator

[tweakcn](https://tweakcn.com)에서 복사한 CSS 테마를 Flutter `ThemeData` 코드로 변환하는 코드 제너레이터.

## Features

- **4가지 색상 포맷** 지원: `hex`, `rgb()`, `hsl()`, `oklch()`
- **Light / Dark** 모드 자동 분리 (`:root` / `.dark`)
- **ColorScheme** 매핑 생성
- **ThemeExtension** 생성: Colors, Radius, Shadows
- **BuildContext extension** 생성: `context.tweakcnColors`, `context.tweakcnRadius`, `context.tweakcnShadows`
- **CLI** 및 **build_runner** 지원

## Getting Started

### 1. 설치

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_tweakcn_generator: ^0.1.0
```

### 2. CSS 파일 준비

[tweakcn.com](https://tweakcn.com)에서 테마를 커스터마이징한 뒤 CSS를 복사하여 프로젝트 루트에 `tweakcn.css`로 저장합니다.

```css
:root {
  --background: #ffffff;
  --foreground: #0a0a0a;
  --primary: #171717;
  --primary-foreground: #fafafa;
  /* ... */
  --radius: 0.625rem;
}

.dark {
  --background: #0a0a0a;
  --foreground: #fafafa;
  /* ... */
}
```

### 3. 코드 생성

```bash
dart run flutter_tweakcn_generator
```

기본적으로 `tweakcn.css`를 읽어 `lib/theme/tweakcn_theme.g.dart`를 생성합니다.

### 4. 사용

```dart
import 'theme/tweakcn_theme.g.dart';

MaterialApp(
  theme: TweakcnTheme.light,
  darkTheme: TweakcnTheme.dark,
);
```

위젯에서 직접 접근:

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

`pubspec.yaml`에서 설정을 변경할 수 있습니다:

```yaml
flutter_tweakcn_generator:
  input: tweakcn.css                        # CSS 파일 경로 (기본값)
  output: lib/theme/tweakcn_theme.g.dart    # 출력 경로 (기본값)
  class_prefix: Tweakcn                     # 클래스 접두사 (기본값)
```

`class_prefix`를 변경하면 생성되는 클래스 이름이 바뀝니다:

```dart
// class_prefix: My
MyTheme.light
context.myColors.primary
context.myRadius.lg
context.myShadows.shadowMd
```

## build_runner

`*.tweakcn.css` 확장자를 사용하면 build_runner로도 생성할 수 있습니다:

```bash
dart run build_runner build
```

## Generated Code

생성되는 코드에는 다음이 포함됩니다:

| 생성 항목 | 설명 |
|---|---|
| `ColorScheme` (light/dark) | CSS 색상 → Material ColorScheme 매핑 |
| `TweakcnColors` | 모든 색상 토큰 (ThemeExtension) |
| `TweakcnRadius` | sm, md, lg, xl (ThemeExtension) |
| `TweakcnShadows` | shadow-2xs ~ shadow-2xl (ThemeExtension) |
| `TweakcnTheme` | `ThemeData.light` / `ThemeData.dark` |
| `TweakcnBuildContext` | `context.tweakcnColors` 등 편의 extension |

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

## Supported Color Formats

```css
--primary: #171717;                /* hex */
--primary: rgb(23, 23, 23);       /* rgb */
--primary: hsl(0 0% 9%);          /* hsl */
--primary: oklch(0.21 0 0);       /* oklch */
```

## License

MIT
