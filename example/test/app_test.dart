// Runs the app the generated theme was generated for.
//
// `tweakcn_theme_test.dart` builds the extensions and compares them; this
// mounts them. What it covers is the surface a consumer actually writes —
// `TweakcnTheme.light`, `TweakcnTheme.dark` and the `BuildContext` extensions
// — which nothing reached while the theme was only ever built and inspected.
import 'package:example/main.dart';
import 'package:example/theme/tweakcn_theme.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The colour the app paints behind its content, read back off the widget
  /// the app built — which got it from `context.tweakcnColors`.
  Color? backgroundOf(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;

  group('the example app', () {
    testWidgets('builds and paints its first frame', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starts on the light theme it was generated with', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(backgroundOf(tester), TweakcnColors.light.background);
    });

    testWidgets('switches to the dark theme through the extensions', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      expect(backgroundOf(tester), TweakcnColors.dark.background);
      expect(
        TweakcnColors.dark.background,
        isNot(TweakcnColors.light.background),
        reason: 'this theme paints both modes the same, so nothing is proven',
      );
    });
  });

  group('the BuildContext extensions', () {
    testWidgets('resolve every extension below a generated theme', (
      tester,
    ) async {
      late TweakcnColors colors;
      late TweakcnRadius radius;
      late TweakcnShadows shadows;

      await tester.pumpWidget(
        MaterialApp(
          theme: TweakcnTheme.light,
          home: Builder(
            builder: (context) {
              colors = context.tweakcnColors;
              radius = context.tweakcnRadius;
              shadows = context.tweakcnShadows;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors, TweakcnColors.light);
      expect(radius, TweakcnRadius.standard);
      expect(shadows, TweakcnShadows.light);
    });

    testWidgets('throw rather than answer when the theme carries none', (
      tester,
    ) async {
      // The generated getters end in `!`. A null would surface far from here,
      // as a failure to paint rather than as a theme that was never installed.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              context.tweakcnColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<TypeError>());
    });
  });

  group('a theme transition', () {
    // Flutter animates between two `ThemeData`s, so `lerp` is reached on the
    // frames in between rather than by anyone calling it. Reading a value
    // there that is neither end is what says the animated path ran.
    //
    // The two ends are built rather than taken from the generated constants,
    // because this theme declares the same shadows and the same radius for
    // both modes: with those, every point of the transition equals both ends
    // and a `lerp` that was never called would look identical to one that was.
    late TweakcnColors colors;
    late TweakcnRadius radius;
    late TweakcnShadows shadows;

    ThemeData themeOf(TweakcnColors c, TweakcnRadius r, TweakcnShadows s) =>
        ThemeData(extensions: [c, r, s]);

    Widget app(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          colors = context.tweakcnColors;
          radius = context.tweakcnRadius;
          shadows = context.tweakcnShadows;
          return const SizedBox();
        },
      ),
    );

    final from = themeOf(
      TweakcnColors.light,
      const TweakcnRadius(sm: 0, md: 0, lg: 0, xl: 0),
      const TweakcnShadows(
        shadow2xs: [],
        shadowXs: [],
        shadowSm: [],
        shadow: [],
        shadowMd: [],
        shadowLg: [],
        shadowXl: [],
        shadow2xl: [BoxShadow(blurRadius: 0)],
      ),
    );
    final to = themeOf(
      TweakcnColors.dark,
      const TweakcnRadius(sm: 40, md: 40, lg: 40, xl: 40),
      const TweakcnShadows(
        shadow2xs: [],
        shadowXs: [],
        shadowSm: [],
        shadow: [],
        shadowMd: [],
        shadowLg: [],
        shadowXl: [],
        shadow2xl: [BoxShadow(blurRadius: 40)],
      ),
    );

    testWidgets('reaches every extension mid-flight', (tester) async {
      await tester.pumpWidget(app(from));
      await tester.pumpAndSettle();

      await tester.pumpWidget(app(to));
      await tester.pump(const Duration(milliseconds: 100));

      final ends = <String, (Object, List<Object?>)>{
        'colors': (
          colors,
          [from.extension<TweakcnColors>(), to.extension<TweakcnColors>()],
        ),
        'radius': (
          radius,
          [from.extension<TweakcnRadius>(), to.extension<TweakcnRadius>()],
        ),
        'shadows': (
          shadows,
          [from.extension<TweakcnShadows>(), to.extension<TweakcnShadows>()],
        ),
      };

      for (final entry in ends.entries) {
        final (value, both) = entry.value;
        for (final end in both) {
          expect(
            value,
            isNot(end),
            reason: '${entry.key} mid-transition is an end, so lerp never ran',
          );
        }
      }
    });

    testWidgets('arrives at the theme it was given', (tester) async {
      await tester.pumpWidget(app(from));
      await tester.pumpAndSettle();

      await tester.pumpWidget(app(to));
      await tester.pumpAndSettle();

      expect(colors, TweakcnColors.dark);
      expect(radius, to.extension<TweakcnRadius>());
      expect(shadows, to.extension<TweakcnShadows>());
    });
  });
}
