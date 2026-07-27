import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Formats generated Dart source the way `dart format` would.
///
/// Assembling source as strings decides where its lines break, and nothing in
/// the writers pushes back on a long token name under a long class prefix. A
/// consumer running a format check over their own `lib/` would fail it the
/// moment they generate, and the usual answer — excluding generated files from
/// the check — is a cost they carry on our behalf.
///
/// [languageVersion] has to be the one of the project being generated into.
/// See `language_version.dart` for where it comes from and why. Null formats
/// at the newest version known, which is right for a project that declares
/// nothing older.
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
