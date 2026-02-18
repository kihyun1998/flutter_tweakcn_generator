import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_cleanup.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String fontsDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('font_cleanup_test_');
    fontsDir = '${tempDir.path}/fonts';
    Directory(fontsDir).createSync();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  void createFont(String name) {
    File('$fontsDir/$name').writeAsBytesSync([0]);
  }

  group('FontCleanup.cleanFontsDirectory', () {
    test('removes font files not in definedFamilies', () {
      createFont('Inter-Regular.ttf');
      createFont('Inter-Bold.ttf');
      createFont('Roboto-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Bold.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Roboto-Regular.ttf').existsSync(), isFalse);
    });

    test('keeps fonts matching sanitized family names with spaces', () {
      createFont('NotoSansKR-Regular.ttf');
      createFont('NotoSansKR-Bold.ttf');
      createFont('Inter-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Noto Sans KR']);

      expect(File('$fontsDir/NotoSansKR-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/NotoSansKR-Bold.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isFalse);
    });

    test('deletes empty directory after cleanup', () {
      createFont('Roboto-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(Directory(fontsDir).existsSync(), isFalse);
    });

    test('keeps directory if defined fonts remain', () {
      createFont('Inter-Regular.ttf');
      createFont('Roboto-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(Directory(fontsDir).existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
    });

    test('does nothing if directory does not exist', () {
      final nonExistent = '${tempDir.path}/nonexistent';
      // Should not throw
      FontCleanup.cleanFontsDirectory(nonExistent, ['Inter']);
    });

    test('ignores non-ttf files', () {
      createFont('Inter-Regular.ttf');
      File('$fontsDir/README.md').writeAsStringSync('hello');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/README.md').existsSync(), isTrue);
    });

    test('handles multiple defined families', () {
      createFont('Inter-Regular.ttf');
      createFont('NotoSansKR-Regular.ttf');
      createFont('Roboto-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter', 'Noto Sans KR']);

      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/NotoSansKR-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Roboto-Regular.ttf').existsSync(), isFalse);
    });
  });
}
