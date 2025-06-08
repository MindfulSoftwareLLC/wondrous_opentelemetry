import 'dart:ui';

/// Web stub for desktop_window package
/// This provides no-op implementations for web platform
class DesktopWindow {
  /// No-op implementation for web
  static Future<void> setMinWindowSize(Size size) async {
    // Do nothing on web platform
    return;
  }
  
  /// No-op implementation for web  
  static Future<void> setMaxWindowSize(Size size) async {
    // Do nothing on web platform
    return;
  }
  
  /// No-op implementation for web
  static Future<void> setWindowSize(Size size) async {
    // Do nothing on web platform
    return;
  }
}
