import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_adder.dart';
import 'package:test/test.dart';

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
