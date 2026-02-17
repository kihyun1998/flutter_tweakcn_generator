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
}
