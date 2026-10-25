# build-runner-builder

## What it is
The `build_runner` path. Each `<name>.tweakcn.css` in the consumer's package
becomes `<name>.tweakcn.dart` beside it, written to source.

## Governing decisions
**None** as a record.
- **Not touching project files is intended** (maintainer, 2026-10-25). The
  builder only generates source. It does no font downloading, scanning, pubspec
  declarations or `google_fonts` dependency add, and has no exit-code contract.

## Design model
From the source (`TweakcnBuilder`, `build.yaml`).
- **Output path:** `inputId.changeExtension('.dart')`, not `'.tweakcn.dart'`.
  `changeExtension` replaces only the last extension, and build_runner refuses
  an output the builder did not declare. The old code failed outright with no
  output (#20 `fa95d76`).
- **Options:** `class_prefix` and `font_mode` come from `build.yaml` builder
  options. The `input`/`output` settings under `flutter_tweakcn_generator:` in
  pubspec do not apply here (`README.md` → "build_runner").
- **Language version:** read from the consumer's `pubspec.yaml` as an asset, or
  `null` when it is not readable ([output-formatting](output-formatting.md)).
- `auto_apply: root_package`, `build_to: source` (`build.yaml`).

## Code
- `lib/builder.dart`: `tweakcnBuilder`
- `lib/src/builder/tweakcn_builder.dart`: `TweakcnBuilder.build`, `buildExtensions`
- `build.yaml`
- tests: `test/builder/tweakcn_builder_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [generated-file](generated-file.md): this path emits the same file as the CLI. In `local`/`custom` mode it names a `fontFamily` that nothing declares, and in google_fonts mode it imports a package that nothing adds.
- [output-formatting](output-formatting.md): the asset read of the pubspec is a separate code path from the CLI's disk read.
- [shipping](shipping.md): the `build` dependency range (`>=2.0.0 <5.0.0`) is wide on purpose, so consumers on older `build` majors can still resolve the package (#33).

## Known holes / open
**None.** `README.md` → "build_runner" says font handling is CLI-only.
