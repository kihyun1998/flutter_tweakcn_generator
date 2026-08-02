# flutter_tweakcn_generator

A Dart build_runner package that generates Flutter theme code from tweakcn theme definitions.

## Verifying a change to the generator

`dart test` only checks the text the generator emits — the package has no Flutter dependency, so the suite cannot tell whether that text compiles. (`dart test -P fast` skips the `slow`-tagged tests, which wait out the font downloader's real 30-second deadline. That is for the edit loop; a gate runs the bare command.) After changing what the generator writes, also run:

```bash
dart run tool/verify_generated_output.dart
cd example && flutter test
```

The first compiles the generated output for six theme shapes against the real SDK inside `example/`, which must have its packages resolved (`flutter pub get`). It also fails when the theme committed under `example/` is no longer what the generator writes — regenerate it with `cd example && dart run flutter_tweakcn_generator`, since the example is committed exactly as generated.

The second runs the generated code. It is also the only thing that type-checks the seam between the package and its output: `ThemeModeData.shadowLayers` produces the record type the generated `fromShadowMap` takes, and nothing else in the repo puts those two declarations in the same compilation. Adding a field to one and not the other fails only here.

See the Development section of `README.md`.

## Agent skills

### Working discipline

Any substantive change — a feature slice, a bug fix, a refactor touching the
public surface — runs through `theflow`. Its project-specific bindings (reference
routing, the mechanism/policy boundary, proof method per layer, the gate matrix,
the paths that always get a completeness pass) live in `docs/agents/theflow.md`,
with the evidence behind them in `docs/agents/lessons.md`. Read the bindings
before applying the method.

### Issue tracker

Issues live as GitHub issues in `kihyun1998/flutter_tweakcn_generator`, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
