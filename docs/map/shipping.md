# shipping

## What it is
This territory covers how the package reaches consumers:
- the pub.dev release, with its version and `CHANGELOG.md`;
- what is published (`.pubignore`);
- the dependency ranges consumers must resolve against;
- the docs that ship with it (`README.md`, `doc/riverpod.md`, public dartdoc);
- keeping dependencies current (#33).

## Governing decisions
**None** as a record. The release rules are the maintainer's (carried from `CLAUDE.md` → "Shipping", 2026-10-25). `CLAUDE.md` keeps the PR-or-`main` rule and the publish guardrail.

## Design model
- **Release:** a dedicated commit `chore: release X.Y.Z` bumps `version` and adds
  the changelog section, and `dart pub publish --dry-run` must be clean. The
  maintainer runs `dart pub publish`; the agent never does. A published changelog
  entry is never rewritten. 0.5.1 corrects 0.4.0's "shadcn arithmetic" line
  instead of editing it (`CHANGELOG.md` 0.5.1).
- **PR or straight to `main`:** the question is whether the change alters what a
  consumer gets (`CLAUDE.md` → "Shipping").
- **Ranges are wide on purpose.** A Flutter project resolves the floor; this
  package resolves the top (`pubspec.yaml` comment). `build` spans several majors
  so that consumers on older stacks can still add the package (#33).
- **`.pubignore` excludes** `CLAUDE.md`, `docs/` (this map included),
  `example/test/` and `example/`'s platform folders.
- **An emitted-text change is a consumer-visible diff,** even when it is dartdoc
  only (`CHANGELOG.md` 0.5.1).
- **After a release, check each consumer.** Consumers are sibling repos under
  `/Volumes/T7/GitHub` on the maintainer's machine; derive the list at the
  time, never store it. A consumer may depend on the package twice, as a
  `dev_dependency` and as a `dependency`.

## Code
- `pubspec.yaml`: `version`, `environment`, dependency ranges
- `CHANGELOG.md`, `README.md`, `doc/riverpod.md`, `LICENSE`, `.pubignore`
- `example/`: shipped as the package's example

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [output-formatting](output-formatting.md): moving either end of the `dart_style` range changes what every Flutter consumer can resolve.
- [public-api](public-api.md): pub.dev publishes the exported dartdoc as the API reference.
- [cli-run](cli-run.md), [colorscheme-resolution](colorscheme-resolution.md), [radius-steps](radius-steps.md): `README.md` restates their behaviour in tables and prose, so a behaviour change here drifts the README.

## Known holes / open
- **No automation reports a release outside a declared range.** Dependabot with
  `versioning-strategy: widen` is proposed but not built. Tracked: #33.
