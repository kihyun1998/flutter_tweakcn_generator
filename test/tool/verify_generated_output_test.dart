import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/verify_generated_output.dart';

void main() {
  final repoRoot = Directory.current;

  group('verification cases', () {
    final cases = verificationCases(repoRoot);

    test('covers the theme shapes that break the generator differently', () {
      expect(
        cases.map((c) => c.name),
        containsAll([
          'complete_theme',
          'minimal_theme',
          'color_free_theme',
          'dark_only_theme',
        ]),
      );
    });

    test('every case carries CSS the parser can read', () {
      for (final verificationCase in cases) {
        expect(
          verificationCase.css.trim(),
          isNotEmpty,
          reason: '${verificationCase.name} has no CSS to generate from',
        );
      }
    });

    test('the complete case is the fixture the unit tests assert on', () {
      final complete = cases.firstWhere((c) => c.name == 'complete_theme');

      expect(
        complete.css,
        File('test/fixtures/sample_hex.css').readAsStringSync(),
      );
    });
  });

  group('generated case files', () {
    late Directory target;

    setUp(() {
      target = Directory.systemTemp.createTempSync('tweakcn_verify_test');
    });

    tearDown(() {
      if (target.existsSync()) target.deleteSync(recursive: true);
    });

    test('writes one Dart file per case and nothing else', () {
      final cases = verificationCases(repoRoot);

      final written = writeGeneratedCases(target, cases);

      expect(written, hasLength(cases.length));
      expect(
        target.listSync().map((e) => e.path),
        unorderedEquals(written.map((f) => f.path)),
      );
      for (final file in written) {
        expect(file.path, endsWith('.dart'));
        expect(file.readAsStringSync(), contains('class TweakcnColors'));
      }
    });

    test('replaces whatever a previous run left in the target', () {
      final stale = File(p.join(target.path, 'stale.dart'))
        ..writeAsStringSync('// left over');

      writeGeneratedCases(target, verificationCases(repoRoot));

      expect(stale.existsSync(), isFalse);
    });
  });

  test('the scratch directory is visible to the analyzer', () {
    // Guards the silent-pass failure mode described on [generatedCaseDirName].
    expect(generatedCaseDirName, isNot(startsWith('.')));
  });
}
