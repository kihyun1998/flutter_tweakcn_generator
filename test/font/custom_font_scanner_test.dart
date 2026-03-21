import 'dart:io';

import 'package:flutter_tweakcn_generator/src/font/custom_font_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('CustomFontScanner.scan', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('custom_font_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('finds matching .ttf files and infers weights', () {
      File('${tempDir.path}/MyFont-Regular.ttf').writeAsStringSync('');
      File('${tempDir.path}/MyFont-Bold.ttf').writeAsStringSync('');
      File('${tempDir.path}/MyFont-Light.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'My Font',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(3));
      // Sorted by weight
      expect(results[0].weight, equals(300)); // Light
      expect(results[1].weight, equals(400)); // Regular
      expect(results[2].weight, equals(700)); // Bold
      expect(results[0].family, equals('My Font'));
      expect(results[0].filePath, equals('fonts/MyFont-Light.ttf'));
    });

    test('returns empty list and warns when directory does not exist', () {
      final results = CustomFontScanner.scan(
        'MyFont',
        '${tempDir.path}/nonexistent',
        relativeDir: 'fonts',
      );

      expect(results, isEmpty);
    });

    test('returns empty list and warns when no matching files found', () {
      File('${tempDir.path}/OtherFont-Regular.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'MyFont',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, isEmpty);
    });

    test('ignores non-ttf files', () {
      File('${tempDir.path}/MyFont-Regular.ttf').writeAsStringSync('');
      File('${tempDir.path}/MyFont-Regular.otf').writeAsStringSync('');
      File('${tempDir.path}/MyFont.txt').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'MyFont',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(1));
      expect(results[0].filePath, equals('fonts/MyFont-Regular.ttf'));
    });

    test('defaults to weight 400 for unknown suffix', () {
      File('${tempDir.path}/MyFont-Custom.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'MyFont',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(1));
      expect(results[0].weight, equals(400));
    });

    test('defaults to weight 400 for file without suffix', () {
      File('${tempDir.path}/MyFont.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'MyFont',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(1));
      expect(results[0].weight, equals(400));
    });

    test('handles all known weight suffixes', () {
      final expected = {
        'Thin': 100,
        'ExtraLight': 200,
        'Light': 300,
        'Regular': 400,
        'Medium': 500,
        'SemiBold': 600,
        'Bold': 700,
        'ExtraBold': 800,
        'Black': 900,
      };

      for (final suffix in expected.keys) {
        File('${tempDir.path}/TestFont-$suffix.ttf').writeAsStringSync('');
      }

      final results = CustomFontScanner.scan(
        'TestFont',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(expected.length));
      for (var i = 0; i < results.length; i++) {
        expect(results[i].weight, equals((i + 1) * 100));
      }
    });

    test('uses custom relativeDir in file paths', () {
      File('${tempDir.path}/MyFont-Regular.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'MyFont',
        tempDir.path,
        relativeDir: 'assets/fonts',
      );

      expect(results, hasLength(1));
      expect(results[0].filePath, equals('assets/fonts/MyFont-Regular.ttf'));
    });

    test('handles font name with spaces', () {
      File('${tempDir.path}/NotoSansKR-Regular.ttf').writeAsStringSync('');
      File('${tempDir.path}/NotoSansKR-Bold.ttf').writeAsStringSync('');

      final results = CustomFontScanner.scan(
        'Noto Sans KR',
        tempDir.path,
        relativeDir: 'fonts',
      );

      expect(results, hasLength(2));
      expect(results[0].family, equals('Noto Sans KR'));
      expect(results[0].weight, equals(400));
      expect(results[1].weight, equals(700));
    });
  });
}
