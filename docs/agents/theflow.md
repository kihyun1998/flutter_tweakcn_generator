# theflow bindings (flutter_tweakcn_generator)

Project-specific data for the `theflow` skill (the working discipline for a
substantive change). The skill holds the portable *method*; this file holds this
package's *bindings* — which reference to read, where the boundary falls, how to
prove behavior, which surfaces to sweep, which gates to run. The method defers
every concrete value here.

Identity and invariants live in [`CLAUDE.md`](../../CLAUDE.md). `CONTEXT.md` and
`docs/adr/` **do not exist yet** — [`domain.md`](domain.md) says they are created
lazily, when a term or a decision actually needs resolving. Per-incident evidence
belongs in `lessons.md` (not yet created either; see the war-story index below).

## Reasoning bindings (project-wide)

These govern every step, so they sit above the steps.

**The named prior art.** Three sources, each authoritative over a different half
of this package:

| Source | Authoritative over |
|---|---|
| [`jnsahaj/tweakcn`](https://github.com/jnsahaj/tweakcn) (Apache-2.0, active) | the **input** — which tokens exist, what CSS the user actually pastes |
| Flutter SDK `packages/flutter/lib/src/material/` | the **output** — the shape the generated code must have to compile |
| [`google_fonts`](https://pub.dev/packages/google_fonts) package source | the **spelling** — family name → `GoogleFonts.<method>TextTheme()` |

**The tie-breaker is layered, not a single winner.** Whoever owns the layer wins
outright there:

- **Input semantics** → **tweakcn wins.** This package's job is to translate
  tweakcn's output faithfully. shadcn/ui is the upstream *vocabulary*, but the
  user pastes what tweakcn emits, so tweakcn's emitter is the contract and
  shadcn/ui is context. If they disagree, the CSS in front of you decides.
- **Output shape** → **the Flutter SDK wins.** A compile failure is not
  negotiable — which is why the `generated-output` CI job is deliberately *not*
  pinned to a Flutter version (`ci.yml:41-44`): pinning would blind it to the SDK
  moving under generated code.
- **Our own measurement** decides only what both are silent on. The `dart_style`
  constraint is the worked example: neither tweakcn nor Flutter says anything
  about it, and the floor was set by measuring that `3.0.0` and `3.1.1` format
  this generator's output differently while `3.1.1` and the current top do not
  (`pubspec.yaml:21-30`). Prior art never outranks a measurement on ground it
  does not own.

## Crate / module map

Single Dart package, no workspace. **It generates Flutter source without
depending on Flutter** — that one fact shapes every gate below.

| Path | Role | Public? |
|---|---|---|
| `lib/flutter_tweakcn_generator.dart` | barrel — parsers, `DartThemeGenerator`, models, font helpers | ✅ |
| `lib/builder.dart` | the `build_runner` builder entry point | ✅ |
| `bin/flutter_tweakcn_generator.dart` | the CLI — the path most consumers actually use | ✅ (executable) |
| `lib/src/parser/` | `css_parser`, `color_parser`, `css_length`, `shadow_parser` — CSS text → tokens | internal |
| `lib/src/generator/` | `dart_theme_generator`, `color_scheme_resolver`, `source_formatter`, `language_version` — tokens → Dart text | internal (`dart_theme_generator` exported) |
| `lib/src/models/` | `tweakcn_theme_data` — `TweakcnThemeData` / `ThemeModeData`, incl. `shadowLayers` | ✅ |
| `lib/src/font/` | `font_downloader`, `pubspec_font_adder`, `font_cleanup`, `custom_font_scanner`, `font_family`, `pubspec_font_declarations` | mixed |
| `lib/src/builder/` | `tweakcn_builder` | internal |
| `lib/src/config.dart` | `TweakcnConfig.fromPubspec` | ✅ |
| `tool/verify_generated_output.dart` | the compile gate — has its own tests under `test/tool/` | dev |
| `example/` | **a separate Flutter package** — the only place `package:flutter` resolves | outside `dart test` |

**`example/` is the blind spot.** It is excluded from the analyzer
(`analysis_options.yaml:16-24`), from the formatter gate (`ci.yml:33` is scoped
to `lib test tool bin`), and from `dart test` — it is a different package. It has
to be gated explicitly, and Step 7 says how.

`ColorSchemeResolver` is **not** in the barrel. That is a live boundary question,
not an oversight — see Step 2 and issue #22.

## Step 1 — reference routing table

Read real source, then grep the actual lines:

```bash
gh api repos/<owner>/<repo>/contents/<path> --jq .content | base64 -d > /tmp/x
grep -n '<thing>' /tmp/x
```

Do **not** use a summarizing fetch — it silently drops bodies from large files,
so a handler that *is* there reads as absent.

| Change type | Real source to read |
|---|---|
| **A token's existence or meaning** (`--muted`, a new token, what `--radius` covers) | `jnsahaj/tweakcn` → `types/theme.ts`. The zod schema **enumerates every token** — this is the roster, not a sample |
| **What CSS a user actually pastes** (shadow levels, the `.dark` block, variable ordering) | `jnsahaj/tweakcn` → `utils/theme-style-generator.ts`. It emits `--shadow-2xs` … `--shadow-2xl` at lines 62-69 — literally the producer of this package's input. Note the asymmetry it encodes: tweakcn stores shadows as *components* (`shadow-color`/`opacity`/`blur`/`spread`/`offset-x`/`offset-y`) and derives the levels; this package parses the derived levels |
| **Generated code's shape** (a new `required` on `ColorScheme`, `ThemeExtension` signature, `TextTheme.apply`) | Flutter SDK `packages/flutter/lib/src/material/color_scheme.dart`, `theme_data.dart`, `text_theme.dart`. The local SDK is faster to grep than `gh api` |
| **Family name → `GoogleFonts` method name** | the `google_fonts` package's own generated source. README already names this as a failure mode: "a `GoogleFonts` method name derived from a family that the package does not spell that way" |
| **The Google Fonts download** (API response shape, status codes) | the real API response — probe it, do not reason about it. #23 was found by observing an actual HTTP 400 for `Segoe UI` |
| **Formatting / language version** | `dart_style` + `analyzer` package source, and `pubspec.yaml:21-30` for why the constraint is shaped as it is |
| **Downstream bug claim** | the reporting consumer's repo directly (a sibling under `../`, derived on the spot). Verify it; the report may be this package's dartdoc's fault rather than its code's |
| **Hidden state** | `lessons.md` once it exists; until then, this repo's own read sites. Removing a field can unpin behavior held incidentally through it — grep every read site, including ones that only *compute* from it |

**Concept ≠ mechanism.** A feature may be novel here (nothing in tweakcn knows
about Flutter) while its mechanism is not: colour space conversion, CSS length
units, box-shadow layer order, and font stack parsing all have a real
implementation in tweakcn's or the browser's own layer. Read both.

## Step 1 — the project's own map

**This project keeps none.** No `CONTEXT.md`, no `docs/adr/`, no dependency or
territory graph. Recorded here as an answer, not a blank: there is nothing to
read at the start of Step 1 beyond `CLAUDE.md`, this file, and the issue's own
cluster. When the first record lands (Step 6), add it here.

## Step 2 — boundary rule

**The core turns CSS text into Dart text. The consumer decides what to do with
the result.** Nothing in this package may know what an app looks like.

The invariant that makes the boundary checkable in one line, from `README.md:213`:

> **The generated file imports Flutter and nothing else.**

So the generator may never make its output name a type from this package. That is
why the runtime factories (`TweakcnColors.fromMap`, `TweakcnRadius.fromRadius`,
`TweakcnShadows.fromShadowMap`) take plain maps and a structural record type
rather than this package's models — a consumer can pass their results around at
zero dependency cost.

- **Mechanism / core:** CSS parsing (colours, lengths, shadows, font stacks),
  token → `ColorScheme` resolution and its fallbacks, code emission, formatting
  at the consumer's language version, font resolution and download.
- **Policy / consumer:** which theme to apply and when, `ThemeMode`, how
  `ThemeData` is composed at runtime, widget styling, the CSS itself, and
  everything in `pubspec.yaml` outside the fonts block this package writes.

**There are two consumer modes, and they have different boundaries.** Both exist
today in `mobile_init_project`:

- **build time** — `dev_dependencies`, run the CLI or `build_runner`, ship the
  `.g.dart`. The generated file is the entire seam.
- **runtime** — `dependencies`, call `CssParser.parse` on CSS the *end user*
  pasted, and feed the tokens to the generated factories (`README.md:157-218`).
  Here the package's **public API** is the seam, so anything the generator does
  that a live preview must reproduce has to be reachable. This is exactly what
  #22 is about: `ColorSchemeResolver.resolve()` holds the fallback rules the
  generated `ColorScheme` goes through, is not exported, and a consumer therefore
  hand-copies it — a divergence seed of the kind #13–#15 existed to delete.

**The membrane leaks downward, and this package has the scar.** #21: raising the
`dart_style` floor to `^<newest>` would have dragged in an analyzer wanting a
newer `meta` than the Flutter SDK pins — making this package unresolvable in
*every* Flutter project, which is every project that uses it. The rule that fell
out is written into the pubspec: **a Flutter project resolves the floor; this
package resolves the top.** Any constraint change is a downstream change.

**Cross-repo rules are in force** — this package publishes to pub.dev and has
consumers it cannot see. The two-consumer signal, the SDK-floor constraint, and
the duty to report a local guard upstream all apply. So does the after-merge
downstream loop.

**Contract ≠ defect.** Before treating a consumer's report as a bug, ask whose
invariant broke. A transparent placeholder for an undefined token is the
*contract* of `TweakcnColors.fromMap` (it reproduces what the generated constants
do); a consumer unhappy that it differs from `ColorScheme`'s derived fallback has
found a **missing export**, not a wrong fallback. Fixing "the fallback" would
delete a contract.

## Step 4 — proof method per layer

| Layer | Real proof |
|---|---|
| **pure logic** (parsers, colour/length/shadow conversion, `ColorSchemeResolver`, `font_family`) | `dart test` unit tests |
| **emitted text** | `dart test` — `test/generator/dart_theme_generator_test.dart`. **This is not proof the text compiles**; see the trap below |
| **generated code compiles** | `dart run tool/verify_generated_output.dart` — generates six theme shapes (complete, minimal, no colours, `.dark`-only, and one per way the theme class can name a font), analyzes them *inside* `example/` where `package:flutter` resolves, deletes them again |
| **generated code runs** | `cd example && flutter test` |
| **the package ↔ output seam** | **only** `example/`'s `flutter test`. `ThemeModeData.shadowLayers` produces the record type the generated `fromShadowMap` takes, and nothing else in the repo puts those two declarations in the same compilation. Add a field to one and not the other and *this* is the only thing that fails (`CLAUDE.md`) |
| **CLI end-to-end** | `test/cli/cli_harness.dart` and the tests around it — the path most consumers actually run |
| **downstream** | link a local build into a real consumer and run its **full** suite (below) |

**Linking into a consumer.** In-repo, `example/` already does it with
`path: ../`. For an external consumer, add to *its* pubspec:

```yaml
dependency_overrides:
  flutter_tweakcn_generator:
    path: ../flutter_tweakcn_generator
```

then run that consumer's whole suite. The strongest evidence is a consumer test
that pinned the old bug as its expected value now **breaking**, with the rest
green.

**The traps, all of them real here:**

- **`dart test` compares text to text.** A fully green suite says nothing about
  whether the generated file builds — a `ColorScheme` missing a newly-`required`
  parameter, an unbalanced `textTheme: ...apply(...)`, a `GoogleFonts` method
  name the package does not spell that way. This is the headline trap and the
  reason both extra commands exist (#12, #19, #20).
- **A green compile is not a green run.** #19 exists because compiling the
  generated theme did not prove the runtime factories rebuild a theme's own
  constants from its own tokens. Only running them does.
- **The verifier can misread itself.** It runs whichever `dart` is on `PATH`; a
  standalone SDK and Flutter's bundled one can differ by a **language version**,
  so a local result can legitimately disagree with the IDE or with CI
  (`tool/verify_generated_output.dart:26-28`). Formatting is measured through the
  same lens — check which SDK produced a formatting disagreement before treating
  it as a defect.
- **`flutter pub get` in `example/` dirties the tree** by rewriting the
  checked-in platform plugin registrants. Use `dart pub get` there; `flutter test`
  does it anyway, which is why running the example's tests locally leaves those
  files modified (`ci.yml:48-53`).
- **A stale committed example is a failure, not noise.** The theme under
  `example/` is committed exactly as generated; `verify_generated_output.dart`
  fails when it is no longer what the generator writes. Regenerate with
  `cd example && dart run flutter_tweakcn_generator`.

## Step 5 — unconditional completeness triggers

Run the adversarial completeness pass **regardless of the enumeration-risk
judgement**, and no matter how small the diff, for any change touching:

- **`lib/src/font/pubspec_font_adder.dart`** — the only file in the package that
  writes `pubspec.yaml` (`:79`, `:220`), and the rewriter itself.
- **`lib/src/font/font_cleanup.dart`** — deletes font files and directories from
  the consumer's tree (`:58`, `:65`), and its `font_exclusive` path is what
  triggers the rewriter above.

**Why these and nothing else.** They modify things this package does not own, in
a project it does not own, in place. A bug here does not produce a wrong colour;
it produces a consumer whose project **will not resolve at all**, and the damage
is already on their disk before anyone reads a diff. #16 is the precedent:
`font_exclusive` cleanup turned `pubspec.yaml` into invalid YAML on CRLF input —
it fired on a run with nothing to clean up, printed a success line, and exited 0.
The fix landed entirely in `pubspec_font_adder.dart` (`e2e124a`).

`pubspec_font_declarations.dart` is deliberately *not* on this list: it reads
(`:43`) and builds declaration text, but writes nothing.

This list doubles as the **second-lens budget**. The refuting critic — a second
pass over the same material whose job is to break the first one's convergence
claim — is worth its cost only here.

Everywhere else, the ordinary Step 5 judgement applies. The parsers are the usual
enumeration-risk candidates (many CSS shapes, many edges) but a wrong number
there is a wrong colour, and it compiles — a different class of cost.

## Step 6 — behavior-describing surfaces

- **Public dartdoc** — ships verbatim as the pub.dev API reference. The surface
  most likely to still describe the old behavior.
- **`README.md`** — carries *behavior tables* that drift the moment the generator
  moves: the **ColorScheme Mapping** table (`README.md:220-238`, including the
  prose on which fallback is substituted), the **runtime factory** section
  (`157-218`, which documents `fromMap`/`fromRadius`/`fromShadowMap` semantics
  token by token), the font-mode sections, and the **Development** section.
- **`CHANGELOG.md`** — pub.dev **snapshots it at publish**. Never rewrite a
  published entry; open a new version instead. The repo and the registry must not
  claim different things for the same version.
- **`doc/riverpod.md`** — a consumer-facing guide; a public API change can
  falsify it.
- **`example/`** — committed exactly as generated, so it is documentation that a
  gate checks. Regenerate rather than hand-edit.
- **`pubspec.yaml`** — the `environment` floor *and* the `dart_style` comment
  (`21-30`). That comment is load-bearing rationale, not a note: it records a
  measurement and tells the next person to re-check it before moving either end.
- **`CLAUDE.md`** and `docs/agents/*.md` — the verification recipe lives in
  `CLAUDE.md` and goes stale the day a gate changes.
- **Reclaim now-false rationale.** A justification in an earlier issue, commit
  message, or changelog entry can be made false by a later change. `bd4327f`
  ("address the review of the language-version fix") is the shape: a follow-up
  that revises the reasoning of the commit before it.

**Decision records.** Destination: **`docs/adr/`** at the repo root, per
[`domain.md`](domain.md), numbered `NNNN-kebab-title.md`, created lazily. A
promotion (two or more triggers) lands there and the glossary lands in
`CONTEXT.md`.

**Areas that already carry a record: none.** Zero accepted, zero proposed — the
directory does not exist. So the filing step's check is currently trivial: no
cluster has a home yet, and the first sibling pair in any area proposes a spine.
**Update this line when the first record lands**, or the check silently keeps
answering "none".

**Tracker parent/child: available, verified.** GitHub sub-issues work on this
repo (`GET /repos/kihyun1998/flutter_tweakcn_generator/issues/22/sub_issues`
returns `[]`, not `404`; `sub_issues_summary` and `issue_dependencies_summary`
are both present on the issue payload). So the follow-up tree and the spine's
roster both use the real relation — **no prose fallback, no reconciliation step.**
Mechanics are in [`issue-tracker.md`](issue-tracker.md).

## Step 7 — gate matrix + release + downstream loop

### Gates

`.github/workflows/ci.yml` is the real source. Two jobs, in two worlds, because
this package lives in both.

**`test` — plain Dart SDK** (a consumer of a dev dependency has no reason to have
Flutter installed, so nothing here may need it):

```bash
dart pub get --no-example
dart analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib test tool bin
dart test
```

**`generated-output` — Flutter SDK** (the code this package *writes* needs
Flutter, and nothing in `dart test` can tell whether it compiles):

```bash
dart pub get
cd example && dart pub get && cd ..      # the verifier does not resolve it itself
dart run tool/verify_generated_output.dart
cd example && flutter test
```

**The blind spots, explicitly:**

- `--no-example` on the first `pub get` is not a nicety — without it the `test`
  job cannot install its own dependencies, and that is invisible on a developer
  machine that has Flutter.
- The formatter gate is scoped to `lib test tool bin`. **`example/` is not
  format-gated**, deliberately: the formatter reads page width from analysis
  options, and the example's cannot be read without a Flutter SDK.
- The analyzer excludes `example/**` for the same reason.
- `dart test` never builds `example/`. Any rename or public-path change needs the
  second job to catch it.
- **`dart test -P fast` is not a gate.** It excludes the `slow` tag — tests that
  wait out the downloader's real 30-second deadline, which is the only honest
  way to show it releases a stalled peer. Use it in the edit loop; a gate runs
  the bare command. `dart_test.yaml` deliberately makes the *full* run the
  default for this reason: a gate whose scope quietly narrowed reports green
  having inspected less than it claims.
- Run each gate **bare, never piped** — `test … | tail -1 && commit` always
  commits, because a pipeline's exit status is `tail`'s.
- **Never move a threshold to green a build.** Raise it when the real number
  rises.

### Branch / PR convention

Split by size, resolved by **one question: does this change what a consumer
gets?**

**Yes → branch → PR (`Closes #N`) → CI green → squash merge.** That is:

- anything under `lib/src/generator/` or `lib/src/models/` — the emitted text;
- the exported surface (`lib/flutter_tweakcn_generator.dart`, `lib/builder.dart`,
  `bin/`);
- the Step 5 sacred path (the `pubspec.yaml`-writing font files);
- `pubspec.yaml`'s `environment` or dependency constraints — the floor leaks
  straight downstream (Step 2).

**No → commit straight to `main`.** That is: `.github/`, `README.md` / `doc/` /
`docs/`, changes confined to `test/` or `tool/`, and `chore: release X.Y.Z`.

Either way, keep this repo's existing subject convention: reference the issue as
`(#N)` when there is one (`4eb5415`, `de909bb`). Note those two predate this
binding and would both take the PR path under it — the history shows the *message*
convention, not the routing.

CI runs on both `push: [main]` and `pull_request`, so either path is gated.

### Release

Own commit `chore: release X.Y.Z` bumping `pubspec.yaml`'s `version` and adding
the `CHANGELOG.md` section. `dart pub publish --dry-run` must be clean.

**`dart pub publish` is irreversible (retract only) — the agent does not run it;
the user does.**

### Downstream loop (after release)

Derive the consumer list on the spot; **never store it here**:

```bash
for d in /Volumes/T7/GitHub/*/; do
  grep -rl 'flutter_tweakcn_generator:' "$d" --include=pubspec.yaml 2>/dev/null
done
```

A consumer may depend on this package **twice over** — as a `dev_dependency` for
build-time generation and as a `dependency` for runtime parsing (both shapes
exist in `mobile_init_project`). Check both. Then in each: raise the constraint,
remove the workarounds the fix made unnecessary, and flip the tests that pinned
the old bug. A purely additive release (a new export, a new option) obliges
consumers to do nothing — **say so explicitly** rather than leaving it implied.

## War-story index

The precedents that give the rules above their teeth. Per-incident detail belongs
in `lessons.md` once it exists.

| Rule | Precedent |
|---|---|
| Step 5 sacred path | **#16** — `font_exclusive` cleanup corrupted `pubspec.yaml` into invalid YAML on CRLF. The consumer's project stopped resolving |
| `dart test` proves nothing about compilation | **#12** (compile gate added), **#20** (the `build_runner` builder produced no output at all — a green suite throughout) |
| A green compile is not a green run | **#19** — the generated entry points had to be *run* in an app to prove the runtime factories rebuild a theme's own constants |
| The boundary leaks downward | **#21** — formatting at the consumer's language version; and `pubspec.yaml:21-30`, where the `dart_style` top is capped so Flutter projects can still resolve this package |
| Contract ≠ defect / missing export | **#22** — a consumer hand-copies `ColorSchemeResolver` because it is not exported. The fallback is not wrong; the seam is missing |
| Probe the real runtime fact | **#23** — the CLI hung after a non-200 because the response was never read. Reading the code said the shape was wrong; only running it gave the numbers that made it a defect (`download()` returned in 232 ms, the process was still alive at 45 s), and only probing the real API showed *why* the suite missed it — its 400 carries ~6.8 kB of body, while the 404 and 500 the tests already covered carry none, and a bodiless non-200 strands nothing |
| Step 5 is not optional once enumeration risk is real | **#23** again, and the sharpest case in the repo. The first pass enumerated *status codes*, declared convergence, and shipped a fix with a hole in it: on a stalled peer the fix turned an unbounded hang into a 30-second one, and its test passed because the test's peer failed instead of stalling. The lens — one subagent, briefed on the Dart SDK *and* this repo at once — returned three more reproduced states and the rule that collapses them into one fix. A lens given only this repo could have seen the difference but not the direction |
| Divergence seeds get deleted, not documented | **#13 / #14 / #15** — three runtime factories, each removing a hand-copy from a downstream builder |
| Hidden state in an area takes several passes | **#4 / #5 / #6** — font family ownership: substring matching, then file-name inference, then finally settling it from the pubspec |
| Read the *whole* input, not the first match | **#9** (merge every `:root` and `.dark` block), **#10** (fall back to dark's `--font-sans`) |
