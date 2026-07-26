import 'dart:io';

/// Runs the generator's real entrypoint with [projectDir] as the project root.
///
/// The CLI reads its config from `Directory.current`, so end-to-end tests give
/// it a throwaway directory rather than the package's own.
ProcessResult runGeneratorIn(Directory projectDir) {
  final repoRoot = Directory.current.path;
  return Process.runSync('dart', [
    'run',
    '--packages=$repoRoot/.dart_tool/package_config.json',
    '$repoRoot/bin/flutter_tweakcn_generator.dart',
  ], workingDirectory: projectDir.path);
}
