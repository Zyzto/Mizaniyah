import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Custom scroll behavior for mobile platforms (Android/iOS)
/// Enables touch and stylus input for scrolling
class AppScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
  };
}
