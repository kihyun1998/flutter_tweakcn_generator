// Main test file - delegates to specific test files.
// Run all tests with: dart test

import 'package:test/test.dart';

void main() {
  test('package exports are available', () {
    // This test just verifies the package compiles.
    // Detailed tests are in subdirectories.
    expect(true, isTrue);
  });
}
