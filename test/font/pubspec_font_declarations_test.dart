import 'package:flutter_tweakcn_generator/src/font/pubspec_font_declarations.dart';
import 'package:test/test.dart';

void main() {
  group('PubspecFontDeclarations.parse', () {
    test('reads families and the family each asset belongs to', () {
      final declarations = PubspecFontDeclarations.parse('''
name: my_app

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
          weight: 400
        - asset: fonts/Inter-Bold.ttf
          weight: 700
    - family: Roboto Slab
      fonts:
        - asset: fonts/RobotoSlab-Regular.ttf
          weight: 400
''');

      expect(declarations.families, ['Inter', 'Roboto Slab']);
      expect(declarations.familiesOf('Inter-Regular.ttf'), {'Inter'});
      expect(declarations.familiesOf('Inter-Bold.ttf'), {'Inter'});
      expect(declarations.familiesOf('RobotoSlab-Regular.ttf'), {
        'Roboto Slab',
      });
    });

    test('answers empty for a file it has never heard of', () {
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
''');

      expect(declarations.familiesOf('Roboto-Regular.ttf'), isEmpty);
    });

    test('keys assets by file name, ignoring the directory', () {
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/type/vendor/Inter-Regular.ttf
''');

      expect(declarations.familiesOf('Inter-Regular.ttf'), {'Inter'});
    });

    test('unquotes a quoted family name', () {
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: "Noto Sans KR"
      fonts:
        - asset: fonts/NotoSansKR-Regular.ttf
''');

      expect(declarations.families, ['Noto Sans KR']);
      expect(declarations.familiesOf('NotoSansKR-Regular.ttf'), {
        'Noto Sans KR',
      });
    });

    test('reads a file with CRLF line endings', () {
      final declarations = PubspecFontDeclarations.parse(
        'flutter:\r\n'
        '  fonts:\r\n'
        '    - family: Inter\r\n'
        '      fonts:\r\n'
        '        - asset: fonts/Inter-Regular.ttf\r\n',
      );

      expect(declarations.families, ['Inter']);
      expect(declarations.familiesOf('Inter-Regular.ttf'), {'Inter'});
    });

    test('ignores a fonts key outside flutter', () {
      final declarations = PubspecFontDeclarations.parse('''
some_other_tool:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
''');

      expect(declarations.families, isEmpty);
      expect(declarations.familiesOf('Inter-Regular.ttf'), isEmpty);
    });

    test('declares nothing for a pubspec with no fonts section', () {
      final declarations = PubspecFontDeclarations.parse('''
name: my_app

flutter:
  uses-material-design: true
''');

      expect(declarations.families, isEmpty);
    });

    test('declares nothing for content that does not parse', () {
      final declarations = PubspecFontDeclarations.parse(
        '{ this: is: not: yaml',
      );

      expect(declarations.families, isEmpty);
      expect(declarations.familiesByFileName, isEmpty);
    });

    test('skips a family entry that names no family', () {
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - fonts:
        - asset: fonts/Mystery-Regular.ttf
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
''');

      expect(declarations.families, ['Inter']);
      expect(declarations.familiesOf('Mystery-Regular.ttf'), isEmpty);
    });

    test('empty declares nothing', () {
      expect(PubspecFontDeclarations.empty.families, isEmpty);
      expect(
        PubspecFontDeclarations.empty.familiesOf('Inter-Regular.ttf'),
        isEmpty,
      );
    });

    test('keeps every family an asset is declared under', () {
      // Nothing stops a pubspec listing the same file under two spellings.
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

      expect(declarations.familiesOf('NotoSansKR-Regular.ttf'), {
        'Noto Sans KR',
        'NotoSansKR',
      });
    });

    test('matches file names regardless of case', () {
      final declarations = PubspecFontDeclarations.parse('''
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: fonts/Inter-Regular.ttf
''');

      expect(declarations.familiesOf('inter-regular.TTF'), {'Inter'});
    });

    test('read declares nothing when the pubspec does not exist', () {
      expect(
        PubspecFontDeclarations.read('/nonexistent/pubspec.yaml').families,
        isEmpty,
      );
    });
  });
}
