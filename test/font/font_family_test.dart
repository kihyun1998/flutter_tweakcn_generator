import 'package:flutter_tweakcn_generator/src/font/font_family.dart';
import 'package:test/test.dart';

void main() {
  group('FontFamily.fileNamePrefix', () {
    test('leaves a single-word family alone', () {
      expect(FontFamily('Inter').fileNamePrefix, 'Inter');
    });

    test('removes spaces from a multi-word family', () {
      expect(FontFamily('Noto Sans KR').fileNamePrefix, 'NotoSansKR');
      expect(FontFamily('IBM Plex Mono').fileNamePrefix, 'IBMPlexMono');
    });
  });

  group('FontFamily.ownsFile', () {
    test('claims its own weight files', () {
      final family = FontFamily('Inter');

      expect(family.ownsFile('Inter-Regular.ttf'), isTrue);
      expect(family.ownsFile('Inter-Bold.ttf'), isTrue);
      expect(family.ownsFile('Inter.ttf'), isTrue);
    });

    test('claims files of a multi-word family', () {
      final family = FontFamily('Noto Sans KR');

      expect(family.ownsFile('NotoSansKR-Regular.ttf'), isTrue);
      expect(family.ownsFile('NotoSansKR-Bold.ttf'), isTrue);
    });

    test('does not claim another family', () {
      final family = FontFamily('Inter');

      expect(family.ownsFile('Roboto-Regular.ttf'), isFalse);
      expect(family.ownsFile('NotoSansKR-Regular.ttf'), isFalse);
    });

    test('claims real-world file names that carry no weight separator', () {
      final inter = FontFamily('Inter');

      // Inter's own releases and Google Fonts' variable-font downloads.
      expect(inter.ownsFile('InterVariable.ttf'), isTrue);
      expect(inter.ownsFile('Inter24pt-Bold.ttf'), isTrue);
      expect(FontFamily('Roboto').ownsFile('Roboto[wdth,wght].ttf'), isTrue);
    });

    test('guesses generously, claiming a prefix-sharing family too', () {
      // Nothing in the name separates this from the case above, so the guess
      // is wrong here on purpose. PubspecFontDeclarations is what settles it
      // where being wrong would delete a file.
      expect(FontFamily('Roboto').ownsFile('RobotoSlab-Bold.ttf'), isTrue);
    });

    test('claims files whose case differs', () {
      final family = FontFamily('Inter');

      expect(family.ownsFile('inter-regular.ttf'), isTrue);
      expect(family.ownsFile('INTER-Bold.ttf'), isTrue);
      expect(family.ownsFile('Inter-Bold.TTF'), isTrue);
      expect(family.ownsFile('inter.ttf'), isTrue);
    });

    test('claims files with an unknown or absent weight suffix', () {
      final family = FontFamily('Inter');

      expect(family.ownsFile('Inter.ttf'), isTrue);
      expect(family.ownsFile('Inter-Chonky.ttf'), isTrue);
      expect(family.ownsFile('Inter_Bold.ttf'), isTrue);
    });

    test('does not claim non-font files', () {
      final family = FontFamily('Inter');

      expect(family.ownsFile('Inter-Regular.otf'), isFalse);
      expect(family.ownsFile('README.md'), isFalse);
      expect(family.ownsFile('Inter'), isFalse);
    });
  });

  group('FontFamily.weightSuffixOf', () {
    test('reads the suffix after a dash', () {
      expect(FontFamily('Inter').weightSuffixOf('Inter-Bold.ttf'), 'Bold');
      expect(
        FontFamily('Inter').weightSuffixOf('Inter-ExtraLight.ttf'),
        'ExtraLight',
      );
    });

    test('reads the suffix after an underscore', () {
      expect(FontFamily('Inter').weightSuffixOf('Inter_Bold.ttf'), 'Bold');
    });

    test('reads the suffix of a multi-word family', () {
      expect(
        FontFamily('Noto Sans KR').weightSuffixOf('NotoSansKR-SemiBold.ttf'),
        'SemiBold',
      );
    });

    test('returns an empty suffix for a bare family file', () {
      expect(FontFamily('Inter').weightSuffixOf('Inter.ttf'), '');
    });

    test('returns an empty suffix rather than throwing on a short name', () {
      expect(FontFamily('AVeryLongFamilyName').weightSuffixOf('A.ttf'), '');
    });
  });

  group('FontFamily.fileNameFor', () {
    test('builds a name the same family will claim back', () {
      final family = FontFamily('Noto Sans KR');
      final fileName = family.fileNameFor('Bold');

      expect(fileName, 'NotoSansKR-Bold.ttf');
      expect(family.ownsFile(fileName), isTrue);
      expect(family.weightSuffixOf(fileName), 'Bold');
    });
  });

  group('FontFamily.hasName', () {
    test('matches its own name exactly', () {
      expect(FontFamily('Roboto').hasName('Roboto'), isTrue);
      expect(FontFamily('Noto Sans KR').hasName('Noto Sans KR'), isTrue);
    });

    test('does not match a name that merely extends it', () {
      expect(FontFamily('Roboto').hasName('Roboto Slab'), isFalse);
      expect(FontFamily('Roboto Slab').hasName('Roboto'), isFalse);
    });

    test('is case sensitive, as pubspec and CSS are', () {
      expect(FontFamily('Roboto').hasName('roboto'), isFalse);
    });
  });
}
