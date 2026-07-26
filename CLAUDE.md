# flutter_tweakcn_generator

A Dart build_runner package that generates Flutter theme code from tweakcn theme definitions.

## Verifying a change to the generator

`dart test` only checks the text the generator emits — the package has no Flutter dependency, so the suite cannot tell whether that text compiles. After changing what the generator writes, also run:

```bash
dart run tool/verify_generated_output.dart
```

It compiles the generated output for four theme shapes against the real SDK inside `example/`, which must have its packages resolved (`flutter pub get`). See the Development section of `README.md`.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `kihyun1998/flutter_tweakcn_generator`, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
