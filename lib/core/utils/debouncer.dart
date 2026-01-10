import 'dart:async';

/// Utility class for debouncing function calls
/// Prevents excessive function calls by waiting for a quiet period
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Call the function after the delay period
  /// If called again before the delay expires, the previous call is cancelled
  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel any pending calls
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of the debouncer
  void dispose() {
    cancel();
  }
}
