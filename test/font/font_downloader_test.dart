import 'package:flutter_tweakcn_generator/src/font/font_downloader.dart';
import 'package:test/test.dart';

void main() {
  group('FontDownloader.parseFontEntries', () {
    test('parses single @font-face block', () {
      const css = '''
@font-face {
  font-family: 'Inter';
  font-style: normal;
  font-weight: 400;
  src: url(https://fonts.gstatic.com/s/inter/v18/UcCo3FwrK3iLTcvio.ttf) format('truetype');
}
''';
      final entries = FontDownloader.parseFontEntries(css);
      expect(entries, hasLength(1));
      expect(entries[0].weight, equals(400));
      expect(entries[0].url, contains('.ttf'));
    });

    test('parses multiple @font-face blocks', () {
      const css = '''
@font-face {
  font-family: 'Inter';
  font-style: normal;
  font-weight: 400;
  src: url(https://fonts.gstatic.com/s/inter/v18/regular.ttf) format('truetype');
}
@font-face {
  font-family: 'Inter';
  font-style: normal;
  font-weight: 700;
  src: url(https://fonts.gstatic.com/s/inter/v18/bold.ttf) format('truetype');
}
@font-face {
  font-family: 'Inter';
  font-style: normal;
  font-weight: 900;
  src: url(https://fonts.gstatic.com/s/inter/v18/black.ttf) format('truetype');
}
''';
      final entries = FontDownloader.parseFontEntries(css);
      expect(entries, hasLength(3));
      expect(entries[0].weight, equals(400));
      expect(entries[1].weight, equals(700));
      expect(entries[2].weight, equals(900));
    });

    test('returns empty list for CSS without @font-face', () {
      const css = 'body { font-family: sans-serif; }';
      final entries = FontDownloader.parseFontEntries(css);
      expect(entries, isEmpty);
    });

    test('skips @font-face without TTF url', () {
      const css = '''
@font-face {
  font-family: 'Inter';
  font-weight: 400;
  src: url(https://fonts.gstatic.com/s/inter/v18/regular.woff2) format('woff2');
}
''';
      final entries = FontDownloader.parseFontEntries(css);
      expect(entries, isEmpty);
    });

    test('skips @font-face without weight', () {
      const css = '''
@font-face {
  font-family: 'Inter';
  src: url(https://fonts.gstatic.com/s/inter/v18/regular.ttf) format('truetype');
}
''';
      final entries = FontDownloader.parseFontEntries(css);
      expect(entries, isEmpty);
    });
  });

  group('FontDownloader.weightNames', () {
    test('maps all standard weights', () {
      expect(FontDownloader.weightNames[100], equals('Thin'));
      expect(FontDownloader.weightNames[200], equals('ExtraLight'));
      expect(FontDownloader.weightNames[300], equals('Light'));
      expect(FontDownloader.weightNames[400], equals('Regular'));
      expect(FontDownloader.weightNames[500], equals('Medium'));
      expect(FontDownloader.weightNames[600], equals('SemiBold'));
      expect(FontDownloader.weightNames[700], equals('Bold'));
      expect(FontDownloader.weightNames[800], equals('ExtraBold'));
      expect(FontDownloader.weightNames[900], equals('Black'));
    });
  });
}
