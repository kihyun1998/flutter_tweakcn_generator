import 'dart:io';

/// Runs the generator's real entrypoint with [projectDir] as the project root.
///
/// The CLI reads its config from `Directory.current`, so end-to-end tests give
/// it a throwaway directory rather than the package's own.
///
/// [environment] replaces the child's environment entirely, so a caller that
/// wants to add one variable passes `{...Platform.environment, ...}`. Its use
/// here is to fail the font lookup without a network: `HttpClient` honours
/// `http_proxy`/`https_proxy`, so pointing them at a dead port makes the
/// lookup fail the way a dropped network does.
ProcessResult runGeneratorIn(
  Directory projectDir, {
  Map<String, String>? environment,
}) {
  final repoRoot = Directory.current.path;
  return Process.runSync(
    'dart',
    [
      'run',
      '--packages=$repoRoot/.dart_tool/package_config.json',
      '$repoRoot/bin/flutter_tweakcn_generator.dart',
    ],
    workingDirectory: projectDir.path,
    environment: environment,
  );
}
