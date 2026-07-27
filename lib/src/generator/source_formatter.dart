import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Formats generated Dart source the way `dart format` would.
///
/// Assembling source as strings decides where its lines break, and nothing in
/// the writers pushes back on a long token name under a long class prefix. A
/// consumer running a format check over their own `lib/` would fail it the
/// moment they generate, and the usual answer — excluding generated files from
/// the check — is a cost they carry on our behalf.
///
/// [languageVersion] has to be the one of the project being generated into,
/// not the newest one this package happens to resolve. `dart format` takes it
/// from the `environment: sdk:` constraint of the package it is run in, and
/// formats differently across versions — so output formatted at the newest
/// fails the format check of a project that declares an older SDK, which is
/// most of them.
///
/// ## On the dependency
///
/// `dart_style` is the only way to format Dart from Dart, and it brings
/// `analyzer` with it. That matters more than it looks: the analyzer the
/// newest `dart_style` requires wants a `meta` newer than the one the Flutter
/// SDK pins, so constraining to the newest makes this package unresolvable in
/// every Flutter project — which is every project that uses it. The constraint
/// in pubspec.yaml is deliberately wide at the top so a Flutter project can
/// resolve an older one, and floored at the oldest version whose output was
/// checked against the newest.
String formatGeneratedSource(String source, {Version? languageVersion}) {
  // A new formatter per call. `DartFormatter` remembers the line ending of the
  // first source it sees and applies it to every later one, so a shared
  // instance would let one caller decide how everyone else's output is
  // written. Fixing the ending here also keeps the result the same on Windows
  // as on CI.
  final formatter = DartFormatter(
    languageVersion: languageVersion ?? DartFormatter.latestLanguageVersion,
    lineEnding: '\n',
  );

  try {
    return formatter.format(source);
  } on FormatterException catch (e) {
    // The generator wrote something that does not parse. There is nothing a
    // consumer can do about it, but saying so beats writing the broken source
    // out as if it were fine, or swallowing the reason it is broken.
    throw StateError(
      'flutter_tweakcn_generator produced source it could not format, which '
      'means it produced source that does not parse. This is a bug in the '
      'generator — please report it, with the CSS that triggered it.\n\n$e',
    );
  }
}

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
///
/// Null leaves [formatGeneratedSource] on the newest version it knows, which
/// is right for a project that has not pinned itself to anything older.
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
    return languageVersionFromSdkConstraint(environment['sdk'] as String?);
  } on YamlException {
    return null;
  }
}
