import 'package:build/build.dart';

import 'src/builder/tweakcn_builder.dart';

/// Entry point for build_runner.
///
/// Usage in `build.yaml`:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       flutter_tweakcn_generator|tweakcn:
///         enabled: true
/// ```
Builder tweakcnBuilder(BuilderOptions options) {
  final classPrefix = options.config['class_prefix'] as String? ?? 'Tweakcn';
  final fontMode = options.config['font_mode'] as String? ?? 'google_fonts';
  return TweakcnBuilder(classPrefix: classPrefix, fontMode: fontMode);
}
