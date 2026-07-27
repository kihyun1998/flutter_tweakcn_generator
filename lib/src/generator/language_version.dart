/// Where the language version to generate at comes from.
///
/// `dart format` takes it from the `environment: sdk:` constraint of the
/// package it is run in, and formats differently across versions — so a
/// generated file has to be formatted at the version of the project it lands
/// in, not the newest one this package happens to resolve.
///
/// Everything here answers with null rather than throwing. A pubspec that says
/// nothing about its SDK is ordinary, and one that says something unreadable
/// is still not a reason to refuse to generate a theme.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// The language version an `environment: sdk:` constraint puts a package at,
/// or null when it names none.
///
/// The lower bound, because that is what a package is versioned at: declaring
/// `>=3.7.0 <4.0.0` says the code may use 3.7, not 3.11. Without the patch,
/// because language versions do not have one.
Version? languageVersionFromSdkConstraint(String? constraint) {
  if (constraint == null) return null;
  try {
    final parsed = VersionConstraint.parse(constraint);
    final min = parsed is VersionRange ? parsed.min : null;
    return min == null ? null : Version(min.major, min.minor, 0);
  } on FormatException {
    return null;
  }
}

/// The language version the project at [projectDir] declares, or null when its
/// pubspec is missing or says nothing.
Version? languageVersionOfProject(String projectDir) {
  final pubspec = File(p.join(projectDir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return null;
  return languageVersionFromPubspec(pubspec.readAsStringSync());
}

/// The language version the contents of a `pubspec.yaml` declare.
///
/// Split from [languageVersionOfProject] because the build_runner builder
/// reads the consumer's pubspec as an asset rather than off disk.
Version? languageVersionFromPubspec(String pubspecYaml) {
  try {
    final doc = loadYaml(pubspecYaml);
    if (doc is! YamlMap) return null;
    final environment = doc['environment'];
    if (environment is! YamlMap) return null;
    // Checked rather than cast: YAML gives `sdk: 3.7` as a double and a
    // sub-mapping as a YamlMap, and neither is a reason to crash a build.
    final sdk = environment['sdk'];
    return sdk is String ? languageVersionFromSdkConstraint(sdk) : null;
  } on YamlException {
    return null;
  }
}
