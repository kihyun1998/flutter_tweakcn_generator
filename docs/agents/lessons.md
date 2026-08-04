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
| **An HTTP response nobody reads to the end keeps its connection alive, and the process with it.** | A connection returns to the pool only once its response completes (`http_impl.dart:2373`), and `close()` without `force` releases only pooled ones (`_ConnectionTarget.close`, `http_impl.dart:2628`). The dimension that hides it is the **body**: a bodiless non-200 completes on its own, which is why two existing tests covering a 404 and a 500 could never have failed (#23) |
| **`Future.timeout` abandons work; it does not cancel it.** | It completes a *derived* future and leaves the source future and its subscription untouched (`future_impl.dart`). Every `.timeout()` sitting on a stream subscription is therefore a leak site whenever the peer **stalls** rather than fails — the wait ends, the socket does not. Cancelling the subscription is the release: the parser's `onCancel` closes the incoming message as *closing* (`http_parser.dart:1221-1225`), which destroys the connection instead of pooling it. Before any response exists, the equivalent is `HttpClientRequest.abort()` (`http_impl.dart:1702`) (#23) |
| **A stream that *stalls* is not a stream that *errors*.** | An errored stream tears its connection down on its own; a stalled one does not. Testing the errored case and generalising to "mid-stream failure" is how three of the four leaks in #23 stayed hidden — the suite's `/truncated` route errors, and it was the one case that never leaked |
| **`Stream.pipe` subscribes to the source only once the sink is ready.** | `File.openWrite()` does not open the file; the open starts in the consumer and `addStream` calls `stream.listen` only inside `.then(...)`. When the open fails, **nothing ever subscribes** — a full response body sits there with no reader, which is the same stranded connection a non-200 used to leave, reached from the *success* branch. Reading the response and feeding the sink by hand separates "did we read the response" from "could we write the file"; only the first holds a socket (#23) |
| **`HttpClient.connectionTimeout` bounds establishing the socket and nothing else.** | It never bounds a header read or a body read (`http_impl.dart:2704-2707`). Those need their own deadlines, and neither implies the other |
| **The downloader silently goes through the environment's proxy.** | `HttpClient()` defaults `_findProxy` to `HttpClient.findProxyFromEnvironment` (`http_impl.dart:2790`), so `http_proxy` / `https_proxy` / `no_proxy` are honoured though nothing in this package mentions them. A proxy's 407 arrives as an ordinary undrained non-200 |
| **tweakcn and shadcn/ui derive the radius steps by different formulas, and they agree at exactly one input — tweakcn's default.** | The steps look like "the shadcn convention", so checking them against shadcn/ui v4 (`apps/v4/app/globals.css:50-53`, `* 0.6` / `* 0.8` / `* 1.4`) reads as finding a bug. tweakcn emits the *subtractive* form into both its outputs (`utils/theme-style-generator.ts:174-177` for Tailwind v4's `@theme inline`, `:256-259` for the v3 config), and that block travels inside the globals.css the user copies — so it is what their own app computes. Setting the two equal has one root, `r = 10`, for all three steps at once, and tweakcn's default radius is `0.625rem` (`config/theme.ts:53`) — exactly 10px. Every theme that leaves the radius alone hides the difference (#31) |
| **A file can be declared twice under different family spellings.** | Keyed last-wins, an undefined declaration overruled a defined one and the file was deleted. A file is kept if **any** of its declarations names a defined family (#6) |
| **A seam placed *above* the code you are trying to prove makes that code unreachable.** | It looks like any injection point buys testability. It buys only what sits *below* it: injecting the lookup function (`Future<String> Function(url)`) replaces `_fetchCss`, so every line of the HTTP handling it contains goes dark, and a test written through that seam passes with the defect present. Measured on the same mutation: through an endpoint parameter the leak test goes **red**; through an injected lookup it stays **green** (#27). Put the seam at the outermost edge — the *address* — and everything inside stays real |
| **`HttpOverrides` intercepts the bare `HttpClient()` constructor, and a nested empty scope recurses.** | `HttpClient()` is a factory that consults `HttpOverrides.current` (`http.dart:1348-1354`), so any bare construction is already interceptable zone-locally — the reason "there is no seam" is rarely literally true. But `_HttpOverridesScope` chains to its `_previous` (`_http/overrides.dart:92-107`), so building the delegate inside a nested empty `runZoned` calls straight back into your own override and dies of stack overflow. `Zone.root.run(...)` is the escape: the root zone carries no override token |
| **`Uri.replace(queryParameters:)` would destroy the Google Fonts weight list.** | The query `family=Inter:wght@100;200;…` is made of `:`, `@` and `;`, all of which `queryParameters` percent-encodes. Only the family name may be escaped, and only with `Uri.encodeComponent`. The URL is therefore assembled as text on purpose — and now has a test asserting what the server actually received, rather than what the builder meant to send (#27) |

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

### #27 — the seam has to sit below the thing you are proving

The lookup half of `FontDownloader` was bound to a hardcoded
`https://fonts.googleapis.com/css2`, so no test reached a line of it. Two
defects hid there: #23's connection leak, whose fix was applied to both halves
but testable on only one, and a `200` carrying no `@font-face`, which nobody had
ever reproduced.

The issue framed the decision as *how much public surface to spend*, and listed
four options. **Its stated premise — that the path cannot be measured at all —
was false**, and so was its ranking of the options. Both were settled by
measurement rather than reading.

**First, "unmeasurable" was wrong.** `HttpClient()` is a factory that consults
`HttpOverrides.current`, so the lookup was already interceptable zone-locally
with no production change whatsoever. A throwaway probe reproduced all three
states in one run.

**Then the interesting part.** That discovery pointed at the *cheapest* option,
not the right one, and the difference only showed up under mutation. Delete
`await _release(response)` from `_fetchCss` — the #23 fix, lookup half only —
and run the same defect through two candidate seams:

| Seam the test goes through | Under the mutation |
|---|---|
| an endpoint parameter (real `_fetchCss`, loopback server) | **red** — `Expected: <0>, Actual: <1>` |
| an injected lookup function (`Future<String> Function(url)`) | **green** — passes with the defect present |

The injected function *replaces* `_fetchCss`, so everything inside it goes dark;
the test proves the caller's error handling and nothing about the leak. An
endpoint parameter replaces only the **address**, so URL building, the HTTP
exchange, the status check, the drain and the deadline all stay on the tested
path. That is the rule now in the table above, and it is why the option the
issue dismissed first turned out to be the only one that works.

`HttpOverrides` reaches the same set — it substitutes below everything too — but
it does so by reaching around the module rather than through its contract, and
the test then silently depends on the lookup using a bare `HttpClient()`. The
endpoint parameter says the same thing in the module's own signature, and is
defensible surface on its own terms: it is the address of the font service, not
a test hook.

**Both new tests were confirmed by mutation, not by passing.** The second
mutation — restoring the pre-#23 unbounded `transform(utf8.decoder).join()` —
left the child VM hung until it was killed at 90 s, with no output at all.

### #28 — a status derived from incidents, not from the result

#24 set one rule for the CLI's exit code: **`0` means the theme is usable as
generated.** Fonts broke it on *both* sides of one axis, and both breaks had the
same cause — the code inferred the status from **what happened during the run**
instead of asking **what the run left behind**.

- a lookup failure set `2` even when every file was already downloaded and
  declared. Measured: identical project, identical theme and pubspec, `2`
  offline and `0` online.
- a theme naming a family nothing declared exited `0`. Both `font_mode: custom`
  with no matching file and a `200` naming no font files reached it.

One check replaced both: at the end, do any of the families the theme names go
undeclared in `pubspec.yaml`? That also settled a case neither the issue nor its
measurement had covered — a stack where one family is ready and one is not,
which merging the download reports had averaged away.

**The generalisable part.** Two bugs that look like opposite sign errors are
often one *question asked in the wrong place*. `hasFailures` is a fact about the
process; "is the theme short a font" is a fact about the product, and only the
second one is what the contract promises. When a status is defined in terms of
the result, ask it about the result.

**Two pre-existing tests caught the change**, both asserting `exitCode, 0`
incidentally while testing something else — and both projects named `Inter` and
provided no `Inter`. They had frozen the reported behaviour as expected. That is
the shape worth recognising: an assertion nobody thought of as a contract is
still a contract, and when it breaks the first question is whether it was
encoding the bug.

**Measuring it needed a way to fail the lookup offline.** `HttpClient` honours
`http_proxy`/`https_proxy` (see the hidden-state table), so pointing them at a
dead port fails the lookup deterministically with no network — and gives the
*transient* shape (a real family, an unreachable network) rather than the
permanently-unserved family the issue had measured.

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

### #31 — the only test of a value sat on the one input that could not discriminate

Reported as a defect: the radius steps are derived by adding and subtracting,
while shadcn/ui v4 derives them by scaling. The report was accurate about
shadcn/ui and wrong about which upstream governs. tweakcn emits the subtractive
form itself, in both its Tailwind v3 and v4 outputs, and the block travels inside
the globals.css the user copies — so the generator was reproducing the CSS its
input was made of, at *every* radius. Adopting the proposal would have inverted
the defect: correct at 10px, wrong everywhere else.

**The part worth keeping is why nothing here could have told either way.** The
repo's one test of the actual numbers was `generates radius values from CSS
(0.625rem = 10px)`, asserting `sm: 6.0, md: 8.0, lg: 10.0, xl: 14.0`. Measured
under the proposed change, applied to the baked constant:

| Test | Under `* 0.6 / * 0.8 / * 1.4` |
|---|---|
| `generates radius values from CSS (0.625rem = 10px)` | **green** — 10 × 0.6 = 6, × 0.8 = 8, × 1.4 = 14 |
| `a radius smaller than its steps generates no negative one` (2px) | red |
| `a zero radius still steps xl above it` (added here) | red |

The value test was pinned to the **default** radius, which is the single input
at which the two formulas agree — the equations `0.6r = r - 4`, `0.8r = r - 2`
and `1.4r = r + 4` all have the same root, `r = 10`, and tweakcn's default is
`0.625rem`. So the suite's only assertion about the numbers would have passed
under either formula, and a reader comparing the code against an upstream had
nothing in the repo to check their reading against.

**The general form.** A test written at a system's *default* input is written at
the value most likely to be a fixed point of whatever transformation is under
test — defaults are chosen to look right, and agreement at a default is evidence
of nothing. This is the #23 fixture lesson moved one level out: there the
fixture was simpler than the real response in the dimension the bug lived in;
here the *input* was the one point where the dimension collapses.

**And the durable fix was not in the arithmetic.** Nothing was wrong with it.
What was wrong is that the derivation cited no source anywhere a reader would
look — not in the generator, not in the dartdoc that ships to pub.dev, not in
the README. #14 had called it "the shadcn arithmetic" in passing and a test in
`example/` was still named `derives the shadcn steps around the radius`, which
is false under shadcn v4 and is exactly the sentence that sends the next reader
to file this again.

### #23 — reading the code is not observing what it does

A non-200 from the Google Fonts API left the CLI alive after all its output was
done. Both `_fetchCss` and `_fetchTo` discarded the response without consuming it,
so the connection stayed *active*, and `client.close()` without `force` destroys
only idle ones. Measured: `download()` returned in **232 ms**, and the process was
still alive at **45 s**, when a watchdog killed it. Fixed by draining the body
before reporting the status.

It was easy to reach — `Segoe UI`, `Arial` and `SF Pro Display` all answer 400, and
those sit at the front of the font stack tweakcn commonly emits.

**The part worth keeping is why the suite could not have caught it.** The download
tests already covered a 404 (`/missing`) and a 500 (`/server-error`), and both are
**bodiless**. A non-200 with no body completes on its own, so its connection goes
back to the pool whether or not anyone drains it. Measured, with the client's own
`close()` and no drain:

| Response | Connection left behind |
|---|---|
| 404, no body | none |
| 404, 16-byte body | 1 |
| 400, 6805-byte body (the real API's) | 1 |

A test written against the existing routes would have passed with and without the
fix — a green nobody had ever seen fail. The route added for this fix answers with
a body for exactly that reason.

**The general form**, worth checking whenever a test server stands in for a real
one: *the fixture is a claim about the real service, and a fixture simpler than
the real response can be simpler in the dimension the bug lives in.*

**And the enumeration was wrong on its axis, which is the more useful lesson.**
The first pass enumerated *which status code came back* and concluded it had
converged: two leak sites, both fixed, every other branch consumes its body. A
Step 5 lens found three more, all reproduced. They were invisible because the
right axis was **which local step failed to consume what arrived**:

| Missed state | Measured before the fix |
|---|---|
| 200 OK, the local sink fails to open, so nothing subscribes | returned in 33 ms, process alive at 40 s |
| the fix's *own* deadline expiring on a stalled body | returned at 30 s with the right status, alive at 60 s |
| the write deadline expiring on a stalled body | returned at 30 s, alive at 60 s |

The middle row is the one to remember: **the first fix made one path slower
rather than fixed**, and its test passed, because the test's peer failed instead
of stalling. All three collapse into one rule (`Future.timeout` abandons, it does
not cancel) and one fix — which is what "a divergence is not a direction" buys:
the lens read the SDK *and* this repo, so it returned the shape, not a list.
