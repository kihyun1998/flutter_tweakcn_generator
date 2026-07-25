import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/font_cleanup.dart';
import 'package:flutter_tweakcn_generator/src/font/pubspec_font_declarations.dart';
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

    test('keeps every font when definedFamilies is empty', () {
      createFont('Inter-Regular.ttf');
      createFont('Inter-Bold.ttf');
      createFont('NotoSansKR-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, []);

      // An empty family list means detection failed, not "delete everything".
      expect(Directory(fontsDir).existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Bold.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/NotoSansKR-Regular.ttf').existsSync(), isTrue);
    });

    test('removes all fonts when definedFamilies is empty and allowEmpty', () {
      createFont('Inter-Regular.ttf');
      createFont('Inter-Bold.ttf');
      createFont('NotoSansKR-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, [], allowEmpty: true);

      expect(Directory(fontsDir).existsSync(), isFalse);
    });

    test('allowEmpty has no effect when families are defined', () {
      createFont('Inter-Regular.ttf');
      createFont('Roboto-Regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter'], allowEmpty: true);

      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Roboto-Regular.ttf').existsSync(), isFalse);
    });

    test('ignores non-ttf files', () {
      createFont('Inter-Regular.ttf');
      File('$fontsDir/README.md').writeAsStringSync('hello');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(File('$fontsDir/Inter-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/README.md').existsSync(), isTrue);
    });

    test('removes a declared family that is no longer defined', () {
      createFont('Roboto-Regular.ttf');
      createFont('RobotoSlab-Bold.ttf');
      createFont('RobotoSlab.ttf');

      // pubspec still records which family each file was declared under.
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
    - family: Roboto Slab
      fonts:
        - asset: fonts/RobotoSlab-Bold.ttf
        - asset: fonts/RobotoSlab.ttf
''');

      FontCleanup.cleanFontsDirectory(fontsDir, [
        'Roboto',
      ], declarations: declarations);

      expect(File('$fontsDir/Roboto-Regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/RobotoSlab-Bold.ttf').existsSync(), isFalse);
      expect(File('$fontsDir/RobotoSlab.ttf').existsSync(), isFalse);
    });

    test('keeps a file the defined family declares, whatever its name', () {
      createFont('InterVariable.ttf');
      createFont('Inter24pt-Bold.ttf');

      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/InterVariable.ttf
        - asset: fonts/Inter24pt-Bold.ttf
''');

      FontCleanup.cleanFontsDirectory(fontsDir, [
        'Inter',
      ], declarations: declarations);

      expect(File('$fontsDir/InterVariable.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Inter24pt-Bold.ttf').existsSync(), isTrue);
    });

    test('keeps a file any one of its declarations defines', () {
      createFont('NotoSansKR-Regular.ttf');

      // The same asset listed under two spellings, the defined one first.
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Noto Sans KR
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
    - family: NotoSansKR
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
''');

      FontCleanup.cleanFontsDirectory(fontsDir, [
        'Noto Sans KR',
      ], declarations: declarations);

      expect(File('$fontsDir/NotoSansKR-Regular.ttf').existsSync(), isTrue);
    });

    test('keeps an undeclared file that a defined family might own', () {
      createFont('InterVariable.ttf');
      createFont('Roboto[wdth,wght].ttf');

      // pubspec has never heard of either file, so the name is all there is.
      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(File('$fontsDir/InterVariable.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Roboto[wdth,wght].ttf').existsSync(), isFalse);
    });

    test('keeps files whose case differs from the family name', () {
      createFont('inter-regular.ttf');
      createFont('INTER-Bold.ttf');
      createFont('Inter-Light.TTF');
      createFont('roboto-regular.ttf');

      FontCleanup.cleanFontsDirectory(fontsDir, ['Inter']);

      expect(File('$fontsDir/inter-regular.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/INTER-Bold.ttf').existsSync(), isTrue);
      expect(File('$fontsDir/Inter-Light.TTF').existsSync(), isTrue);
      expect(File('$fontsDir/roboto-regular.ttf').existsSync(), isFalse);
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
