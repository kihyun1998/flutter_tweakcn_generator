import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:flutter_tweakcn_generator/src/generator/dart_theme_generator.dart';
import 'package:flutter_tweakcn_generator/src/generator/source_formatter.dart';
import 'package:flutter_tweakcn_generator/src/parser/css_parser.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('languageVersionFromSdkConstraint', () {
    test('takes the lower bound, which is what a package is versioned at', () {
      expect(
        languageVersionFromSdkConstraint('>=3.7.0 <4.0.0'),
        Version(3, 7, 0),
      );
      expect(languageVersionFromSdkConstraint('^3.9.2'), Version(3, 9, 0));
    });

    test('drops the patch, which no language version carries', () {
      expect(
        languageVersionFromSdkConstraint('>=3.11.5 <4.0.0'),
        Version(3, 11, 0),
      );
    });

    test('gives nothing for a constraint it cannot read', () {
      expect(languageVersionFromSdkConstraint(null), isNull);
      expect(languageVersionFromSdkConstraint('any'), isNull);
      expect(languageVersionFromSdkConstraint('not a constraint'), isNull);
    });
  });

  group('languageVersionOfProject', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('lang_version'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('reads the SDK constraint the project declares', () {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: consumer
environment:
  sdk: ">=3.7.0 <4.0.0"
''');

      expect(languageVersionOfProject(dir.path), Version(3, 7, 0));
    });

    test('gives nothing when there is no pubspec to read', () {
      expect(languageVersionOfProject(dir.path), isNull);
    });
  });

  group('generated output', () {
    final css = File('test/fixtures/sample_hex.css').readAsStringSync();

    test('is formatted at the language version it is told to use', () {
      // `dart format` takes the language version from the package it is run
      // in, so output formatted at a different one fails that project's own
      // format check. These are the ends of what this package supports.
      for (final version in [Version(3, 7, 0), Version(3, 11, 0)]) {
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

    test('differs between language versions that format differently', () {
      // Guards the test above from passing because the version is ignored.
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
