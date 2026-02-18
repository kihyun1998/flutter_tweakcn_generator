# example

`flutter_tweakcn_generator` 예제 프로젝트.

## Configuration

`pubspec.yaml`:

```yaml
flutter_tweakcn_generator:
  input: tweakcn.css
  output: lib/theme/tweakcn_theme.g.dart
  font_mode: local
  font_exclusive: true
```

## Options

| Option | Default | Description |
|---|---|---|
| `input` | `tweakcn.css` | CSS 파일 경로 |
| `output` | `lib/theme/tweakcn_theme.g.dart` | 생성될 Dart 파일 경로 |
| `class_prefix` | `Tweakcn` | 생성 클래스 접두사 |
| `font_mode` | `google_fonts` | `google_fonts` (런타임) 또는 `local` (.ttf 다운로드) |
| `font_exclusive` | `false` | `font_mode: local`일 때, `--font-sans`에 정의되지 않은 폰트 파일과 pubspec 선언을 자동 정리 |

## font_exclusive 사용 예시

CSS에서 폰트를 변경했을 때:

```css
/* 변경 전 */
--font-sans: Architects Daughter, Noto Sans KR, sans-serif;

/* 변경 후 */
--font-sans: Roboto, sans-serif;
```

`font_exclusive: true` 설정 후 실행하면:

```bash
dart run flutter_tweakcn_generator
```

1. Roboto `.ttf` 파일 다운로드
2. `fonts/` 디렉토리에서 `ArchitectsDaughter-*.ttf`, `NotoSansKR-*.ttf` 자동 삭제
3. `pubspec.yaml`의 `flutter > fonts`에서 해당 family 블록 자동 제거
