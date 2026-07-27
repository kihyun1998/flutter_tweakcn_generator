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
/// Written out because Dart has no reflection here, and policed by
/// `compares every field the generated class declares` below — a hand-written
/// list of tokens is the exact drift this factory exists to remove, so it may
/// not be the one thing that silently falls behind.
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

void main() {
  final theme = CssParser.parse(File('tweakcn.css').readAsStringSync());

  test('compares every field the generated class declares', () {
    // Reads the field list back out of the generated file, so adding a color
    // token to the generator fails here until [_fields] covers it. Without
    // this the comparisons below would quietly shrink to a subset.
    final declared = RegExp(r'^  final Color (\w+);', multiLine: true)
        .allMatches(File('lib/theme/tweakcn_theme.g.dart').readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();

    expect(declared, isNotEmpty);
    expect(_fields(TweakcnColors.light).keys.toSet(), declared);
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
}
