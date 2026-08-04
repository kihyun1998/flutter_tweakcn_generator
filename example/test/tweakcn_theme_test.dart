// Proves the invariants the generated code is supposed to hold, by running it.
// The generator's own suite cannot: this package generates Flutter source
// without depending on Flutter, so `dart test` can only compare emitted text
// against text. Here the generated classes are real classes that can be built,
// compared and put in a widget tree.
//
// This also happens to be the use the factories exist for — parse tweakcn CSS
// at runtime and turn the tokens into a theme — so the tests double as the
// worked example.
import 'dart:io';

import 'package:example/theme/tweakcn_theme.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';

void main() {
  final theme = CssParser.parse(File('tweakcn.css').readAsStringSync());

  group('value equality', () {
    test('two extensions built from the same tokens are equal', () {
      expect(
        TweakcnColors.fromMap(theme.light.colors),
        TweakcnColors.fromMap(theme.light.colors),
      );
      expect(TweakcnRadius.fromRadius(10), TweakcnRadius.fromRadius(10));
      expect(
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers),
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers),
      );
    });

    test('equal extensions hash the same', () {
      expect(
        TweakcnColors.fromMap(theme.light.colors).hashCode,
        TweakcnColors.fromMap(theme.light.colors).hashCode,
      );
      expect(
        TweakcnRadius.fromRadius(10).hashCode,
        TweakcnRadius.fromRadius(10).hashCode,
      );
      expect(
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers).hashCode,
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers).hashCode,
      );
    });

    test('copyWith changes what it is given and nothing else', () {
      // Equality is what makes this expressible; before it, "nothing else
      // changed" could only be checked field by field.
      expect(
        TweakcnColors.light.copyWith(primary: const Color(0xFF00FF00)),
        isNot(TweakcnColors.light),
      );
      expect(TweakcnColors.light.copyWith(), TweakcnColors.light);
      expect(TweakcnRadius.standard.copyWith(), TweakcnRadius.standard);
      expect(TweakcnShadows.light.copyWith(), TweakcnShadows.light);
    });

    test('lerp returns each end at its own end of the range', () {
      expect(
        TweakcnColors.light.lerp(TweakcnColors.dark, 0),
        TweakcnColors.light,
      );
      expect(
        TweakcnColors.light.lerp(TweakcnColors.dark, 1),
        TweakcnColors.dark,
      );
      expect(
        TweakcnRadius.standard.lerp(TweakcnRadius.standard, 0.5),
        TweakcnRadius.standard,
      );
      expect(
        TweakcnShadows.light.lerp(TweakcnShadows.dark, 1),
        TweakcnShadows.dark,
      );
    });

    test('one differing field is enough to be unequal', () {
      final tokens = Map.of(theme.light.colors)..['sidebar-ring'] = 0xFF00FF00;

      expect(
        TweakcnColors.fromMap(tokens),
        isNot(TweakcnColors.fromMap(theme.light.colors)),
      );
      expect(TweakcnRadius.fromRadius(10), isNot(TweakcnRadius.fromRadius(11)));
    });

    test('a shadow level differing only in a later layer is unequal', () {
      // The levels are lists, and a list is equal only to itself, so this is
      // the case that would pass if they were compared directly.
      final layers = Map.of(theme.light.shadowLayers);
      final sm = List.of(layers['shadow-sm']!);
      sm[sm.length - 1] = (
        offsetX: sm.last.offsetX,
        offsetY: sm.last.offsetY,
        blurRadius: sm.last.blurRadius + 1,
        spreadRadius: sm.last.spreadRadius,
        color: sm.last.color,
      );
      layers['shadow-sm'] = sm;

      expect(sm.length, greaterThan(1));
      expect(
        TweakcnShadows.fromShadowMap(layers),
        isNot(TweakcnShadows.fromShadowMap(theme.light.shadowLayers)),
      );
    });
  });

  group('TweakcnColors.fromMap', () {
    test('rebuilds the light constant from this theme\'s own tokens', () {
      expect(TweakcnColors.fromMap(theme.light.colors), TweakcnColors.light);
    });

    test('rebuilds the dark constant from this theme\'s own tokens', () {
      expect(TweakcnColors.fromMap(theme.dark.colors), TweakcnColors.dark);
    });

    test('gives a token the CSS never defined the same placeholder', () {
      final withoutPrimary = Map.of(theme.light.colors)..remove('primary');

      expect(
        TweakcnColors.fromMap(withoutPrimary).primary,
        const Color(0x00000000),
      );
    });
  });

  group('TweakcnRadius.fromRadius', () {
    test('rebuilds the constant from this theme\'s own radius', () {
      // A ThemeData carries one radius, so the generator prefers light and
      // falls back to dark — the caller has to hand over the same choice.
      expect(
        TweakcnRadius.fromRadius(theme.light.radius ?? theme.dark.radius),
        TweakcnRadius.standard,
      );
    });

    test('derives tweakcn\'s steps around the radius', () {
      // 10px is the one radius at which tweakcn's offsets and shadcn/ui's
      // scaling agree, so this case cannot tell them apart — see the zero
      // radius below, which can.
      expect(
        TweakcnRadius.fromRadius(10),
        const TweakcnRadius(sm: 6, md: 8, lg: 10, xl: 14),
      );
    });

    test('steps xl above a zero radius', () {
      // tweakcn emits `--radius-xl: calc(var(--radius) + 4px)`, so a theme
      // asking for square corners still rounds xl by 4 in the browser. This
      // reproduces that rather than flattening it.
      expect(
        TweakcnRadius.fromRadius(0),
        const TweakcnRadius(sm: 0, md: 0, lg: 0, xl: 4),
      );
    });

    test('never derives a negative step', () {
      // A BorderRadius cannot be negative, and a 1px theme would ask for one.
      expect(
        TweakcnRadius.fromRadius(1),
        const TweakcnRadius(sm: 0, md: 0, lg: 1, xl: 5),
      );
    });

    test('falls back to 8 when the theme declares no radius', () {
      // Not this theme's radius — this theme declares one. It is what a theme
      // that declares none generates, which is what null has to mean here.
      expect(
        TweakcnRadius.fromRadius(null),
        const TweakcnRadius(sm: 4, md: 6, lg: 8, xl: 12),
      );
    });
  });

  group('TweakcnShadows.fromShadowMap', () {
    test('rebuilds the light constant from this theme\'s own shadows', () {
      expect(
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers),
        TweakcnShadows.light,
      );
    });

    test('rebuilds the dark constant from this theme\'s own shadows', () {
      expect(
        TweakcnShadows.fromShadowMap(theme.dark.shadowLayers),
        TweakcnShadows.dark,
      );
    });

    test('keeps a level\'s layers in the order the CSS lists them', () {
      // --shadow-sm declares two layers, and BoxShadow paints in list order,
      // so reversing them would be a visible change no field count catches.
      final built = TweakcnShadows.fromShadowMap(theme.light.shadowLayers);

      expect(built.shadowSm.length, greaterThan(1));
      expect(
        built.shadowSm.map((s) => s.offset),
        TweakcnShadows.light.shadowSm.map((s) => s.offset),
      );
    });

    test('gives a level the CSS never defined the same empty list', () {
      final withoutMd = Map.of(theme.light.shadowLayers)..remove('shadow-md');

      expect(TweakcnShadows.fromShadowMap(withoutMd).shadowMd, isEmpty);
    });

    test('takes shadow data naming no type from this package', () {
      // Written out structurally: this is what a consumer can hand over
      // without importing the generator at all.
      final built = TweakcnShadows.fromShadowMap({
        'shadow-md': [
          (
            offsetX: 1,
            offsetY: 2,
            blurRadius: 3,
            spreadRadius: -1,
            color: 0x33000000,
          ),
        ],
      });

      expect(built.shadowMd.single.offset, const Offset(1, 2));
      expect(built.shadowMd.single.blurRadius, 3);
      expect(built.shadowMd.single.spreadRadius, -1);
      expect(built.shadowMd.single.color, const Color(0x33000000));
    });
  });

  group('as a ThemeData', () {
    ThemeData buildFromTokens({Map<String, int>? colors}) => ThemeData(
      extensions: [
        TweakcnColors.fromMap(colors ?? theme.light.colors),
        TweakcnRadius.fromRadius(theme.light.radius ?? theme.dark.radius),
        TweakcnShadows.fromShadowMap(theme.light.shadowLayers),
      ],
    );

    test('a theme rebuilt from unchanged tokens equals the previous one', () {
      // ThemeData compares its extensions by value, so this is what decides
      // whether an unchanged rebuild reaches the widget tree.
      expect(buildFromTokens(), buildFromTokens());
    });

    // A bare `Theme` rather than a `MaterialApp`: the app inserts an
    // `AnimatedTheme` and a `Navigator`, both of which decide on their own
    // when to rebuild. What is under test is only whether `Theme` tells its
    // dependents anything, so the child instance is reused too — then a
    // rebuild can only have come from the inherited dependency.
    testWidgets('an unchanged rebuild does not notify Theme.of dependents', (
      tester,
    ) async {
      var builds = 0;
      final child = Builder(
        builder: (context) {
          Theme.of(context);
          builds++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Theme(data: buildFromTokens(), child: child));
      final afterFirstFrame = builds;
      await tester.pumpWidget(Theme(data: buildFromTokens(), child: child));

      expect(afterFirstFrame, 1);
      expect(builds, afterFirstFrame);
    });

    testWidgets('a changed token does reach the tree', (tester) async {
      // The inverse of the test above, and identical to it but for one token:
      // same widgets, same three extensions, so what differs is the token
      // rather than the shape of the theme.
      Color? seen;
      final child = Builder(
        builder: (context) {
          seen = context.tweakcnColors.primary;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Theme(data: buildFromTokens(), child: child));
      final before = seen;

      final changed = Map.of(theme.light.colors)..['primary'] = 0xFF00FF00;
      await tester.pumpWidget(
        Theme(
          data: buildFromTokens(colors: changed),
          child: child,
        ),
      );

      expect(before, isNot(const Color(0xFF00FF00)));
      expect(seen, const Color(0xFF00FF00));
    });
  });
}
