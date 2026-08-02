# lessons

The evidence log [`theflow.md`](theflow.md) points at. Two things live here:

1. **Hidden state** — the facts a first-principles model of this package omits
   because the model "looks correct". Step 1 says to enumerate these *before*
   writing anything in the area.
2. **War stories** — per-incident detail behind the bindings' war-story index.
   The index says which rule a case proves; this says what actually happened.

Add an entry when a change teaches something that would otherwise be rediscovered.
An entry that only restates what the issue already says is not worth writing —
write the part that is true *after* the issue closes.

## Hidden state

Each of these was learned by getting it wrong. A model that ignores any of them
passes its unit tests and corrupts a real round-trip.

| The state | Why a naive model misses it |
|---|---|
| **A font file's owning family is recorded in `pubspec.yaml`, not derivable from its name.** | The name looks authoritative. It is not: `RobotoSlab-Bold.ttf` is indistinguishable by name from `InterVariable.ttf`, `Inter24pt-Bold.ttf` and `Roboto[wdth,wght].ttf` — the names Inter's own releases and fonts.google.com actually use. Under `font_mode: custom` those files are **user-supplied and unrecoverable** (#6) |
| **The consumer's `pubspec.yaml` has its own line endings, and they are load-bearing.** | `\r` is a regex line terminator, so `(.+)$` cannot reach past one — while `\s` *does* match `\r`, so anchored `^…\s*$` patterns keep matching. A rewriter that splits on `\n` therefore half-works, which is worse than failing (#16, and again in `4f6110f`) |
| **The consumer's language version decides how the output is formatted**, not this package's. | Formatting looks like a property of the formatter. It is a property of the *target project* (#21). The same fact makes `tool/verify_generated_output.dart` able to misread itself: it runs whichever `dart` is on `PATH`, and a standalone SDK differs from Flutter's bundled one by a language version |
| **`dart_style` → `analyzer` → `meta` → the Flutter SDK's pin is one chain.** | Raising the `dart_style` floor to `^<newest>` drags in an analyzer wanting a newer `meta` than Flutter pins, making this package unresolvable in **every** Flutter project. A Flutter project resolves the floor; this package resolves the top (`pubspec.yaml:21-30`) |
| **A family name can be quoted or unquoted, and every reader must agree on which.** | `addFonts` recognised a quoted declaration and skipped; cleanup did not recognise it and deleted the block — leaving the family undeclared. Two correct-looking halves, one broken pair (#5) |
| **tweakcn stores shadows as *components* and derives the levels.** | `types/theme.ts` holds `shadow-color`/`opacity`/`blur`/`spread`/`offset-x`/`offset-y`; `utils/theme-style-generator.ts:62-69` derives `--shadow-2xs` … `--shadow-2xl` from them. This package parses the *derived* values, so a question about shadow semantics is answered upstream of the CSS it reads |
| **A file can be declared twice under different family spellings.** | Keyed last-wins, an undefined declaration overruled a defined one and the file was deleted. A file is kept if **any** of its declarations names a defined family (#6) |

## War stories

### #4 / #5 / #6 — the same fact, learned three times

The clearest rediscovery in this repo's history, and the reason an invariant is
worth naming before the third site.

**Four places independently translated a font family name** into the form it
takes in a file name — the pubspec updater, the cleanup step, the custom font
scanner, and the downloader that *produces* the names the other three try to
recognise. Each had its own `replaceAll(' ', '')` and its own prefix test.

`afc4a66` (#4) says the cost out loud: *"Issues #5 and #6 both need that logic
corrected, and would otherwise have to correct it twice."* `FontFamily` was
extracted to own the translation and every question asked of it.

Then the two corrections landed anyway, and neither was a naming bug:

- **#5** — declaration was tested with a substring search for `family: <name>`, so
  any family whose name is a *prefix* of a declared one answered yes. Declaring
  `Roboto` alongside `Roboto Slab` silently did nothing: no entry, no error, the
  app fell back to the default font. Fixed by reading declarations with the YAML
  parser the package already depends on — which also stops a family named in a
  comment, in an asset path, or under some other key from counting.
- **#6** — cleanup decided ownership by testing whether a file name *starts with*
  a family's. Tightening that to "family, separator, weight" does fix the case
  **and cannot be done safely** — it would trade a stale file for the failure
  class of #1, deleting user-supplied files. Ownership is now read from
  `flutter > fonts` in the pubspec; a file the pubspec has never declared falls
  back to the name, which stays deliberately generous and **errs toward keeping**.

**What it teaches.** Extracting a helper (#4) did not prevent #5 or #6 — it only
made them cheap to fix once each. A helper prevents nothing, because the author
of a *new* site never looks for it. The durable output is the rule, not the
function: *ownership of a font file is a fact the pubspec records, and any name-
based inference must err toward keeping.*

Two further defects in #6 were found **in review and reproduced through the CLI
before fixing** — the custom font scanner fed its own guess back into the pubspec,
so a leftover file was re-declared under the wrong family and could never be
cleaned again.

### #16 — a destructive path that reported success

`font_exclusive` cleanup turned `pubspec.yaml` into invalid YAML on a CRLF
checkout — the ordinary state on Windows. It **fired on a run with nothing to
clean up, printed a success line, and exited 0.** The file it left behind fails to
parse at all, so every later `flutter pub get` fails on it, and `pubspec.yaml` is
hand-edited and usually the only copy.

The mechanism: the rewriter splits on `\n`, leaving `\r` on every line. The family
pattern matched nothing, while `^flutter:\s*$` and `^  fonts:\s*$` kept matching.
So it entered the fonts section, recognised no families, copied their declarations
through the belongs-to-no-family path, and deleted the `fonts:` key because its
kept-family count was still zero.

**Why this is the Step 5 sacred path.** The blast radius is not a wrong colour —
it is a consumer whose project will not resolve, with the damage already on disk
before anyone reads a diff, in a file this package does not own. The fix landed
entirely in `pubspec_font_adder.dart` (`e2e124a`).

### #12 / #19 / #20 — a green suite that proved nothing

`dart test` compares the generator's output *text* against text. It cannot tell
whether that text compiles, because this package generates Flutter source without
depending on Flutter.

- **#20** — the `build_runner` builder produced **no output at all**, with the
  suite green throughout.
- **#12** — added `tool/verify_generated_output.dart`: generate six theme shapes,
  analyze them inside `example/` where `package:flutter` resolves, delete them.
- **#19** — compiling still was not the whole claim. The generated runtime
  factories are supposed to rebuild a theme's own constants from that theme's own
  tokens, and **only running them says whether they do**.

This is why `CLAUDE.md` names three commands and not one.

### #22 — a missing seam, not a wrong fallback

A consumer building a live preview must render exactly what the generator emits.
`TweakcnColors.fromMap` resolves a missing token to transparent — correct, because
the generated extension does the same. But the generated **`ColorScheme`** does not
go through the extension: it goes through `ColorSchemeResolver.resolve()`, which
substitutes a derived fallback. The two disagree for CSS that omits a token.

Neither behaviour is wrong. `ColorSchemeResolver` is simply **not exported**, so
the resolution rule lives somewhere a consumer cannot call, and they hand-copy it —
the divergence seed #13–#15 existed to delete. The bug is in the boundary, not in
the code on either side of it.

### #23 — reading the code is not observing what it does

With `font_mode: local`, a non-200 from the Google Fonts API leaves the CLI alive
after all its output is done. `_fetchCss` throws without consuming the response, so
the socket stays open and the VM never exits; `client.close()` without `force`
closes only idle connections.

It matters because `Segoe UI`, `Arial` and `SF Pro Display` **all return 400**, and
those sit at the front of the font stack tweakcn commonly emits. Found by observing
an actual HTTP 400, not by reading the code.
