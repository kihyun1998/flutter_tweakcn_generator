# flutter_tweakcn_generator

A Dart build_runner package that generates Flutter theme code from tweakcn theme definitions.

## Verifying a change to the generator

`dart test` compares the generator's output as text. The package has no Flutter
dependency, so the suite cannot tell whether that text compiles. A gate runs the
bare `dart test`; `-P fast` is for the edit loop (`dart_test.yaml`). After
changing what the generator writes, also run:

```bash
cd example && dart pub get && cd ..
dart run tool/verify_generated_output.dart
cd example && flutter test
```

The verifier compiles generated themes inside `example/` and fails when the
committed example theme is stale. `flutter test` is the only command that runs
the generated code, and the only one that type-checks the package↔output seam
([shadow-layer-record](docs/map/shadow-layer-record.md)). When the verifier
reports a stale example, or you need setup details, read `README.md` →
"Development".

## Boundary

The core turns CSS text into Dart text; the consumer decides what to do with
the result. Nothing here may know what an app looks like.

- Core: CSS parsing, token → `ColorScheme` resolution and its fallbacks, code
  emission, formatting at the consumer's language version, font resolution and
  download.
- Consumer: which theme and when, `ThemeMode`, runtime `ThemeData` composition,
  widget styling, the CSS itself, and all of `pubspec.yaml` outside the fonts
  block this package writes.

Before changing the exports or answering a consumer's report, read
[`docs/map/public-api.md`](docs/map/public-api.md).

## Shipping

- Does it change what a consumer gets? Yes → branch, PR (`Closes #N`), squash
  merge. No (`.github/`, docs, `test/` or `tool/` only, release commits) →
  straight to `main`.
- Before a release, run `pub-ready`, and read
  [`docs/map/shipping.md`](docs/map/shipping.md) for what this package adds.

## Comments

A comment says what the code is. Why it is this way, what it deliberately
leaves out, the trap and the measured value go to the territory note under
`docs/map/`. Where none seems to hold it, search the folder and the code
symbol first; only then start a new note, named for what the system does
there, not for the file. History goes to the commit message. Comments
written before this rule still carry the rest: never delete one whose
content the map does not yet hold — move it there first.

## Agent skills

### Working discipline

Any substantive change runs through `thegraph`; its build is
`docs/agents/thegraph.md`.

### Territory map

The map's hub is [`docs/map/README.md`](docs/map/README.md). Read it before
designing a change: open the territories the change touches and follow their
blast radius and invariants. After the change lands, update the notes it
falsified. When a fix reveals a fact, ask whether it holds at every site that
shares the same assumption. If yes, the fix lands with an invariant note.

### Issue tracker

Issues live as GitHub issues in `kihyun1998/flutter_tweakcn_generator`, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, using their default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
