import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_adder.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pubspec_font_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String createPubspec(String content) {
    final file = File('${tempDir.path}/pubspec.yaml');
    file.writeAsStringSync(content);
    return file.path;
  }

  String readPubspec(String path) {
    return File(path).readAsStringSync();
  }

  final testFonts = [
    DownloadedFont(
      family: 'Inter',
      filePath: 'fonts/Inter-Regular.ttf',
      weight: 400,
    ),
    DownloadedFont(
      family: 'Inter',
      filePath: 'fonts/Inter-Bold.ttf',
      weight: 700,
    ),
  ];

  group('PubspecFontAdder', () {
    test('adds fonts to pubspec without flutter section', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
''');

      PubspecFontAdder.addFonts(path, testFonts);
      final result = readPubspec(path);

      expect(result, contains('flutter:'));
      expect(result, contains('  fonts:'));
      expect(result, contains('    - family: Inter'));
      expect(result, contains('        - asset: fonts/Inter-Regular.ttf'));
      expect(result, contains('        - asset: fonts/Inter-Bold.ttf'));
      expect(result, contains('          weight: 700'));
    });

    test('adds fonts to pubspec with existing flutter section', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
''');

      PubspecFontAdder.addFonts(path, testFonts);
      final result = readPubspec(path);

      expect(result, contains('flutter:'));
      expect(result, contains('  fonts:'));
      expect(result, contains('    - family: Inter'));
      expect(result, contains('  uses-material-design: true'));
    });

    test('adds fonts to pubspec with existing fonts section', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
''');

      PubspecFontAdder.addFonts(path, testFonts);
      final result = readPubspec(path);

      expect(result, contains('family: Roboto'));
      expect(result, contains('family: Inter'));
    });

    test('skips family if already declared', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
''');

      PubspecFontAdder.addFonts(path, testFonts);
      final result = readPubspec(path);

      // Should only have one "family: Inter"
      final matches = 'family: Inter'.allMatches(result).length;
      expect(matches, equals(1));
    });

    test('adds a family whose name is a prefix of a declared one', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Roboto Slab
      fonts:
        - asset: fonts/RobotoSlab-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.addFonts(path, [
        DownloadedFont(
          family: 'Roboto',
          filePath: 'fonts/Roboto-Regular.ttf',
          weight: 400,
        ),
      ]);
      final result = readPubspec(path);

      expect(result, contains('- family: Roboto\n'));
      expect(result, contains('family: Roboto Slab'));
    });

    test('adds a family whose name extends a declared one', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.addFonts(path, [
        DownloadedFont(
          family: 'Roboto Slab',
          filePath: 'fonts/RobotoSlab-Regular.ttf',
          weight: 400,
        ),
      ]);
      final result = readPubspec(path);

      expect(result, contains('family: Roboto Slab'));
      expect('family: Roboto\n'.allMatches(result).length, 1);
    });

    test('does not count a family named only in a comment as declared', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    # - family: Inter
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.addFonts(path, testFonts);

      expect('- family: Inter'.allMatches(readPubspec(path)).length, 2);
    });

    test('does not count a family named only in an asset path as declared', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  assets:
    - assets/family: Inter/logo.png
''');

      PubspecFontAdder.addFonts(path, testFonts);

      expect(readPubspec(path), contains('- family: Inter'));
    });

    test('treats a quoted declaration as declared', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: "Inter"
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.addFonts(path, testFonts);

      expect('family: "Inter"'.allMatches(readPubspec(path)).length, 1);
      expect(readPubspec(path), isNot(contains('- family: Inter\n')));
    });

    test('recognizes a declaration in a file with CRLF line endings', () {
      final path = createPubspec(
        'name: my_app\r\n'
        'version: 1.0.0\r\n'
        '\r\n'
        'flutter:\r\n'
        '  fonts:\r\n'
        '    - family: Inter\r\n'
        '      fonts:\r\n'
        '        - asset: fonts/Inter-Regular.ttf\r\n'
        '          weight: 400\r\n',
      );

      PubspecFontAdder.addFonts(path, testFonts);

      expect('family: Inter'.allMatches(readPubspec(path)).length, 1);
    });

    test('inserts with the endings the pubspec already uses', () {
      for (final source in [
        'name: my_app\n\nflutter:\n  fonts:\n    - family: Roboto\n',
        'name: my_app\n\nflutter:\n  uses-material-design: true\n',
        'name: my_app\n',
      ]) {
        final path = createPubspec(source.replaceAll('\n', '\r\n'));

        PubspecFontAdder.addFonts(path, testFonts);
        final result = readPubspec(path);

        expect(
          result.replaceAll('\r\n', ''),
          isNot(contains('\n')),
          reason: 'left LF-only lines in a CRLF pubspec:\n$result',
        );
        expect(loadYaml(result), isA<YamlMap>());
      }
    });

    test('ignores a family key outside flutter > fonts', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

some_other_tool:
  fonts:
    - family: Inter
''');

      PubspecFontAdder.addFonts(path, testFonts);

      expect(readPubspec(path), contains('    - family: Inter'));
    });

    test('treats a declaration with a trailing comment as declared', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Inter # the body font
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.addFonts(path, testFonts);

      expect('family: Inter'.allMatches(readPubspec(path)).length, 1);
    });

    test('writes weight for all fonts including 400', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0
''');

      PubspecFontAdder.addFonts(path, [
        DownloadedFont(
          family: 'Inter',
          filePath: 'fonts/Inter-Regular.ttf',
          weight: 400,
        ),
      ]);
      final result = readPubspec(path);

      expect(result, contains('- asset: fonts/Inter-Regular.ttf'));
      expect(result, contains('weight: 400'));
    });

    test('handles multiple font families', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0
''');

      PubspecFontAdder.addFonts(path, [
        DownloadedFont(
          family: 'Inter',
          filePath: 'fonts/Inter-Regular.ttf',
          weight: 400,
        ),
        DownloadedFont(
          family: 'Noto Sans KR',
          filePath: 'fonts/NotoSansKR-Regular.ttf',
          weight: 400,
        ),
        DownloadedFont(
          family: 'Noto Sans KR',
          filePath: 'fonts/NotoSansKR-Bold.ttf',
          weight: 700,
        ),
      ]);
      final result = readPubspec(path);

      expect(result, contains('family: Inter'));
      expect(result, contains('family: Noto Sans KR'));
    });

    test('does nothing for empty font list', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0
''');
      final original = readPubspec(path);

      PubspecFontAdder.addFonts(path, []);
      final result = readPubspec(path);

      expect(result, equals(original));
    });

    test('sorts fonts by weight within a family', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0
''');

      PubspecFontAdder.addFonts(path, [
        DownloadedFont(
          family: 'Inter',
          filePath: 'fonts/Inter-Bold.ttf',
          weight: 700,
        ),
        DownloadedFont(
          family: 'Inter',
          filePath: 'fonts/Inter-Regular.ttf',
          weight: 400,
        ),
        DownloadedFont(
          family: 'Inter',
          filePath: 'fonts/Inter-Light.ttf',
          weight: 300,
        ),
      ]);
      final result = readPubspec(path);

      final lightIndex = result.indexOf('Inter-Light.ttf');
      final regularIndex = result.indexOf('Inter-Regular.ttf');
      final boldIndex = result.indexOf('Inter-Bold.ttf');

      expect(lightIndex, lessThan(regularIndex));
      expect(regularIndex, lessThan(boldIndex));
    });
  });

  group('PubspecFontAdder.removeUndefinedFonts', () {
    /// A pubspec that declares one family and one key after it — the shape
    /// every corruption of this file has taken, since what breaks is the
    /// boundary between a family block and whatever follows it.
    const robotoOnlyPubspec = '''
name: my_app

flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
  uses-material-design: true
''';

    test('removes undefined font families', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, contains('family: Inter'));
      expect(result, isNot(contains('family: Roboto')));
      expect(result, isNot(contains('Roboto-Regular.ttf')));
    });

    test('keeps all defined families', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Noto Sans KR
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter', 'Noto Sans KR']);
      final result = readPubspec(path);

      expect(result, contains('family: Inter'));
      expect(result, contains('family: Noto Sans KR'));
    });

    test('removes fonts key when all families removed', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, isNot(contains('fonts:')));
      expect(result, isNot(contains('Roboto')));
      expect(result, contains('uses-material-design: true'));
    });

    test('leaves a pubspec that needs no cleanup byte-identical', () {
      // The ordinary case: you declared your fonts, and you are still using
      // them. Regenerating has nothing to do here and must prove it by not
      // touching the file — pubspec.yaml is hand-edited and usually the only
      // copy.
      final path = createPubspec(robotoOnlyPubspec);

      PubspecFontAdder.removeUndefinedFonts(path, ['Roboto']);

      expect(readPubspec(path), robotoOnlyPubspec);
    });

    test('leaves a CRLF pubspec that needs no cleanup byte-identical', () {
      // Every other case here is written as a Dart string literal, so the
      // whole group only ever sees LF. A pubspec checked out on Windows has
      // CRLF, and the family lines are matched by pattern.
      final crlf = robotoOnlyPubspec.replaceAll('\n', '\r\n');
      final path = createPubspec(crlf);

      PubspecFontAdder.removeUndefinedFonts(path, ['Roboto']);

      expect(readPubspec(path), crlf);
    });

    test('removes an undefined family from a CRLF pubspec', () {
      final path = createPubspec(
        '''
name: my_app

flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
  uses-material-design: true
'''.replaceAll('\n', '\r\n'),
      );

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, isNot(contains('Roboto')));

      final flutter = (loadYaml(result) as YamlMap)['flutter'] as YamlMap;
      expect((flutter['fonts'] as YamlList).single['family'], 'Inter');
      expect(flutter['uses-material-design'], isTrue);
    });

    test('leaves valid YAML when it removes the last family', () {
      for (final ending in ['\n', '\r\n']) {
        final path = createPubspec(robotoOnlyPubspec.replaceAll('\n', ending));

        PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
        final result = readPubspec(path);

        final parsed = loadYaml(result) as YamlMap;
        expect(
          parsed['flutter'],
          isA<YamlMap>(),
          reason: 'flutter must still be a mapping, not a list, with $ending',
        );
        expect((parsed['flutter'] as YamlMap)['fonts'], isNull);
        expect((parsed['flutter'] as YamlMap)['uses-material-design'], isTrue);
      }
    });

    test('preserves other flutter keys', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
  assets:
    - images/
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, contains('uses-material-design: true'));
      expect(result, contains('family: Inter'));
      expect(result, contains('assets:'));
      expect(result, contains('- images/'));
    });

    test('keeps every family when definedFamilies is empty', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Noto Sans KR
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
          weight: 400
''');
      final original = readPubspec(path);

      PubspecFontAdder.removeUndefinedFonts(path, []);

      // An empty family list means detection failed, not "delete everything".
      expect(readPubspec(path), equals(original));
    });

    test('removes all families and fonts key when empty and allowEmpty', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
    - family: Noto Sans KR
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, [], allowEmpty: true);
      final result = readPubspec(path);

      expect(result, isNot(contains('fonts:')));
      expect(result, isNot(contains('Inter')));
      expect(result, isNot(contains('Noto Sans KR')));
      expect(result, contains('uses-material-design: true'));
    });

    test('keeps a quoted family that is defined', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: "Inter"
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);

      expect(readPubspec(path), contains('family: "Inter"'));
    });

    test('does nothing when no fonts section exists', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  uses-material-design: true
''');
      final original = readPubspec(path);

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, equals(original));
    });

    test('handles multiple weight entries in a family block', () {
      final path = createPubspec('''
name: my_app
version: 1.0.0

flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
        - asset: fonts/Inter-Bold.ttf
          weight: 700
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
          weight: 400
''');

      PubspecFontAdder.removeUndefinedFonts(path, ['Inter']);
      final result = readPubspec(path);

      expect(result, contains('Inter-Regular.ttf'));
      expect(result, contains('Inter-Bold.ttf'));
      expect(result, isNot(contains('Roboto')));
    });
  });
}
