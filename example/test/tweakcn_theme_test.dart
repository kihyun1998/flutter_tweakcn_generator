// Proves the invariant the generated factory is supposed to hold, by running
// it. The generator's own suite cannot: this package generates Flutter source
// without depending on Flutter, so `dart test` can only compare emitted text
// against text. Here the generated class is a real class that can be built and
// read back.
//
// This also happens to be the use the factory exists for — parse tweakcn CSS
// at runtime and turn the tokens into a theme — so the test doubles as the
// worked example.
import 'dart:io';

import 'package:example/theme/tweakcn_theme.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tweakcn_generator/flutter_tweakcn_generator.dart';

/// Every color the extension carries, by field name.
///
/// Written out because Dart has no reflection here, and checked against
/// [_declaredFields] so it cannot fall behind the generated class.
Map<String, Color> _fields(TweakcnColors c) => {
  'background': c.background,
  'foreground': c.foreground,
  'card': c.card,
  'cardForeground': c.cardForeground,
  'popover': c.popover,
  'popoverForeground': c.popoverForeground,
  'primary': c.primary,
  'primaryForeground': c.primaryForeground,
  'secondary': c.secondary,
  'secondaryForeground': c.secondaryForeground,
  'muted': c.muted,
  'mutedForeground': c.mutedForeground,
  'accent': c.accent,
  'accentForeground': c.accentForeground,
  'destructive': c.destructive,
  'destructiveForeground': c.destructiveForeground,
  'border': c.border,
  'input': c.input,
  'ring': c.ring,
  'chart1': c.chart1,
  'chart2': c.chart2,
  'chart3': c.chart3,
  'chart4': c.chart4,
  'chart5': c.chart5,
  'sidebar': c.sidebar,
  'sidebarForeground': c.sidebarForeground,
  'sidebarPrimary': c.sidebarPrimary,
  'sidebarPrimaryForeground': c.sidebarPrimaryForeground,
  'sidebarAccent': c.sidebarAccent,
  'sidebarAccentForeground': c.sidebarAccentForeground,
  'sidebarBorder': c.sidebarBorder,
  'sidebarRing': c.sidebarRing,
};

/// Every step the radius extension carries, by field name. Policed the same
/// way [_fields] is.
Map<String, double> _radiusFields(TweakcnRadius r) => {
  'sm': r.sm,
  'md': r.md,
  'lg': r.lg,
  'xl': r.xl,
};

/// The names of the fields the generated class [type] declares.
///
/// Read back out of the generated source because Dart has no reflection here.
/// A hand-written field list is the exact drift these factories exist to
/// remove, so it may not be the one thing that silently falls behind.
Set<String> _declaredFields(String type) {
  final source = File('lib/theme/tweakcn_theme.g.dart').readAsStringSync();
  final start = source.indexOf('class $type extends');
  expect(start, isNonNegative, reason: 'no class $type in the generated file');
  final body = source.substring(start);

  return RegExp(r'^  final \w+ (\w+);', multiLine: true)
      .allMatches(body.substring(0, body.indexOf('\n}')))
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  final theme = CssParser.parse(File('tweakcn.css').readAsStringSync());

  test('every field of every extension under test is compared', () {
    // Without this, adding a token to the generator would leave the
    // comparisons below quietly covering a subset.
    for (final entry in {
      'TweakcnColors': _fields(TweakcnColors.light).keys.toSet(),
      'TweakcnRadius': _radiusFields(TweakcnRadius.standard).keys.toSet(),
    }.entries) {
      final declared = _declaredFields(entry.key);

      expect(declared, isNotEmpty, reason: 'found no fields on ${entry.key}');
      expect(entry.value, declared, reason: '${entry.key} is compared partly');
    }
  });

  group('TweakcnColors.fromMap', () {
    test('rebuilds the light constant from this theme\'s own tokens', () {
      expect(
        _fields(TweakcnColors.fromMap(theme.light.colors)),
        _fields(TweakcnColors.light),
      );
    });

    test('rebuilds the dark constant from this theme\'s own tokens', () {
      expect(
        _fields(TweakcnColors.fromMap(theme.dark.colors)),
        _fields(TweakcnColors.dark),
      );
    });

    test('gives a token the CSS never defined the same placeholder', () {
      final withoutPrimary = Map.of(theme.light.colors)..remove('primary');

      expect(
        TweakcnColors.fromMap(withoutPrimary).primary,
        const Color(0x00000000),
      );
    });

    test('builds a usable ThemeData without going through the constants', () {
      // The point of the factory: CSS pasted at runtime, rendered live.
      final colors = TweakcnColors.fromMap(theme.light.colors);

      final data = ThemeData(extensions: [colors]);

      expect(data.extension<TweakcnColors>()?.primary, colors.primary);
    });
  });

  group('TweakcnRadius.fromRadius', () {
    test('rebuilds the constant from this theme\'s own radius', () {
      // A ThemeData carries one radius, so the generator prefers light and
      // falls back to dark — the caller has to hand over the same choice.
      final built = TweakcnRadius.fromRadius(
        theme.light.radius ?? theme.dark.radius,
      );

      expect(_radiusFields(built), _radiusFields(TweakcnRadius.standard));
    });

    test('derives the shadcn steps around the radius', () {
      final built = TweakcnRadius.fromRadius(10);

      expect(_radiusFields(built), {
        'sm': 6.0,
        'md': 8.0,
        'lg': 10.0,
        'xl': 14.0,
      });
    });

    test('never derives a negative step', () {
      // A BorderRadius cannot be negative, and a 1px theme would ask for one.
      final built = TweakcnRadius.fromRadius(1);

      expect(_radiusFields(built), {
        'sm': 0.0,
        'md': 0.0,
        'lg': 1.0,
        'xl': 5.0,
      });
    });

    test('falls back to 8 when the theme declares no radius', () {
      // Not this theme's radius — this theme declares one. It is what a theme
      // that declares none generates, which is what null has to mean here.
      final built = TweakcnRadius.fromRadius(null);

      expect(_radiusFields(built), {
        'sm': 4.0,
        'md': 6.0,
        'lg': 8.0,
        'xl': 12.0,
      });
    });
  });
}
