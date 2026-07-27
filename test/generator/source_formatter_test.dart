import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/generator/language_version.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final css = File('test/fixtures/sample_hex.css').readAsStringSync();

  /// The oldest language version this package can be generating for, read from
  /// its own SDK constraint rather than copied — a consumer cannot declare a
  /// floor below the one this package makes them accept, and moving that floor
  /// should move what is tested with it.
  final oldest = languageVersionOfProject('.')!;

  /// The newest, which is what output gets formatted at when the consuming
  /// project declares nothing. Taken from the formatter for the same reason:
  /// resolving a newer `dart_style` should move this, not leave a literal
  /// behind pointing at whatever the machine happened to have.
  final newest = DartFormatter.latestLanguageVersion;

  group('generated output', () {
    test('is formatted at the language version it is told to use', () {
      // `dart format` takes the language version from the package it is run
      // in, so output formatted at a different one fails that project's own
      // format check.
      for (final version in {oldest, newest}) {
        final code =
            DartThemeGenerator(
              CssParser.parse(css),
              languageVersion: version,
            ).generate();

        expect(
          DartFormatter(languageVersion: version).format(code),
          code,
          reason: 'output is not stable under language version $version',
        );
      }
    });

    test('is formatted at the newest when told to use none', () {
      // The path every consumer whose pubspec declares no SDK constraint
      // takes, which is otherwise the one path nothing here covers.
      final code = DartThemeGenerator(CssParser.parse(css)).generate();

      expect(DartFormatter(languageVersion: newest).format(code), code);
    });

    test('spans versions that really do format differently', () {
      // Guards the tests above from passing because the version is ignored.
      // Not `oldest` against `newest`: those two may agree, and this asserts
      // about the formatter's behaviour rather than about this package.
      expect(
        DartThemeGenerator(
          CssParser.parse(css),
          languageVersion: Version(3, 7, 0),
        ).generate(),
        isNot(
          DartThemeGenerator(
            CssParser.parse(css),
            languageVersion: Version(3, 11, 0),
          ).generate(),
        ),
      );
    });
  });
}
