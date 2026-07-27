import 'dart:io';

import 'package:flutter_tweakcn_generator/src/generator/language_version.dart';
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

    test('gives nothing for a constraint that names no lower bound', () {
      expect(languageVersionFromSdkConstraint(null), isNull);
      expect(languageVersionFromSdkConstraint('any'), isNull);
      expect(languageVersionFromSdkConstraint('<4.0.0'), isNull);
    });

    test('gives nothing for a constraint it cannot read', () {
      expect(languageVersionFromSdkConstraint('not a constraint'), isNull);
      expect(languageVersionFromSdkConstraint(''), isNull);
    });
  });

  group('languageVersionFromPubspec', () {
    test('reads the constraint under environment', () {
      expect(
        languageVersionFromPubspec('''
name: consumer
environment:
  sdk: ">=3.7.0 <4.0.0"
'''),
        Version(3, 7, 0),
      );
    });

    test('gives nothing rather than throwing for an sdk it cannot use', () {
      // YAML hands back whatever type was written, and none of these is a
      // reason to fail a build the consumer did not ask this code to judge.
      for (final pubspec in [
        'name: c\nenvironment:\n  sdk: 3.7\n', // a double
        'name: c\nenvironment:\n  sdk: true\n', // a bool
        'name: c\nenvironment:\n  sdk:\n    min: "3.7.0"\n', // a mapping
        'name: c\nenvironment:\n  flutter: ">=3.0.0"\n', // no sdk at all
        'name: c\nenvironment: nothing\n', // not a mapping
        'name: c\n', // no environment at all
        'name: c\n  bad: [indent\n', // not YAML
        '', // empty
      ]) {
        expect(
          languageVersionFromPubspec(pubspec),
          isNull,
          reason: 'threw or answered for:\n$pubspec',
        );
      }
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
}
