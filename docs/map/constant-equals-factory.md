# constant-equals-factory

## The fact
For each generated extension, the runtime factory given a theme's own tokens
must return a value equal to the constant baked from those same tokens:
- `TweakcnColors.fromMap(theme.light.colors) == TweakcnColors.light`, and the same for dark
- `TweakcnRadius.fromRadius(light.radius ?? dark.radius) == TweakcnRadius.standard`
- `TweakcnShadows.fromShadowMap(theme.light.shadowLayers) == TweakcnShadows.light`, and the same for dark

## Why it is cross-cutting
The constant is computed in Dart by the generator. The factory is Dart *text*
the generator emits, and it runs later in the consumer's app. Each extension
writes the two in separate methods:
- **colors:** `_writeColorsInstance` / `_writeColorsFromMap`. Both use the shared
  `_missingColorArgb` placeholder.
- **radius:** `_writeRadiusExtension` computes `_atLeastZero(radius - 4)` and so
  on. `_writeRadiusFromRadius` emits its own `atLeastZero(base - 4)`, so the
  offsets 4/2/4 and the clamp are written twice.
- **shadows:** `_writeShadowInstance` / `_writeShadowsFromMap`. A missing level
  comes out as `[]` on both sides.

Value equality ([generated-file](generated-file.md)) is what makes "equal"
testable at all.

## Territories it holds in
- [color-extension](color-extension.md): placeholder for a missing token
- [radius-steps](radius-steps.md): derivation and clamp, written once in Dart and once as emitted text
- [shadows](shadows.md): missing level → empty list, layer order kept
- [generated-file](generated-file.md): `_writeValueEquality`, without which "equal" means "the same object"
- [public-api](public-api.md): the runtime consumer is who relies on it
- [verification](verification.md): `example/test/tweakcn_theme_test.dart` is the only place it is checked

## What a violation looks like
A live preview built from parsed CSS differs from the shipped constants for the
same CSS. In #22 the user reports exactly that symptom for `ColorScheme`, which
has no factory at all ([colorscheme-resolution](colorscheme-resolution.md)).

## Discovery history
- #13, #14, #15 (`7218097`, `18721c6`, `2b5ce8b`) added the factories, so that a
  downstream builder could stop hand-copying them.
- #19 (`4eb5415`): only running the factories proves this property. Compiling
  them does not.
- Pinned by `example/test/tweakcn_theme_test.dart`: the `rebuilds the … constant
  from this theme's own …` tests.

## Where it will recur
Any function that emits both a baked value and code computing the same value at
runtime. Change both in one commit, then run `cd example && flutter test`.
