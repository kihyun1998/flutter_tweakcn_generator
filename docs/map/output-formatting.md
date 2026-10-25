# output-formatting

## What it is
This territory formats the generated source the way `dart format` would in the
*consumer's* project, at the language version that project's
`environment: sdk:` constraint declares.

## Governing decisions
**None** as a record. The `dart_style` constraint's rationale lives in the
comment above it in `pubspec.yaml`.

## Design model
From the source (`formatGeneratedSource`, `language_version.dart`).
- **The language version is the consumer's lower bound, without the patch.**
  `>=3.7.0 <4.0.0` gives 3.7 (`languageVersionFromSdkConstraint`). With no
  readable constraint it is the newest version the formatter knows.
- **Every way of reading it returns `null` rather than throwing.** An unreadable
  pubspec is not a reason to refuse to generate (library doc).
- **The CLI reads the version off disk** (`languageVersionOfProject`). The
  builder reads the consumer's pubspec as an asset (`languageVersionFromPubspec`).
- **A new `DartFormatter` per call, with `\n` line endings.** A shared formatter
  instance keeps the line ending of the first source it sees and applies it to
  every later one.
- **Output that does not parse is a generator bug.** It throws a `StateError`
  asking for a report, instead of writing broken source.
- **The `dart_style` range is wide at the top on purpose.** The newest
  `dart_style` pulls an `analyzer` that wants a newer `meta` than the Flutter SDK
  pins, so a narrow range would make this package unresolvable in every Flutter
  project. The floor is 3.1.1 because 3.0.0 formats this output differently
  (`pubspec.yaml` comment; #21 `de909bb`, `bd4327f`).

## Code
- `lib/src/generator/source_formatter.dart`: `formatGeneratedSource`
- `lib/src/generator/language_version.dart`: `languageVersionFromSdkConstraint`, `languageVersionOfProject`, `languageVersionFromPubspec`
- `pubspec.yaml`: the `dart_style` constraint and its comment
- tests: `test/generator/source_formatter_test.dart`, `test/generator/language_version_test.dart`

## Reference behaviour
- The `dart_style` and `analyzer` package source settle how formatting varies
  with the language version. This was measured once for the 3.0.0 / 3.1.1 floor
  (`pubspec.yaml` comment).

## Cross-cutting invariants
**None.**

## Blast radius
- [shipping](shipping.md): changing either end of the `dart_style` range changes what every Flutter consumer can resolve. "A Flutter project resolves the floor; this package resolves the top" (`pubspec.yaml`).
- [verification](verification.md): `tool/verify_generated_output.dart` runs whichever `dart` is on `PATH`. A standalone SDK and Flutter's bundled one can differ by a language version, so a formatting disagreement there may come from the SDK rather than a defect (the verifier's library doc).
- [build-runner-builder](build-runner-builder.md), [cli-run](cli-run.md): each supplies the language version in its own way.
- The theme committed under `example/` has to match byte for byte, so a formatter change shows up as a stale example.

## Known holes / open
**None.**
