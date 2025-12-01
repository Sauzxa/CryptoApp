import 'dart:math';

/// Manages adaptive socket timeout based on recent response times
/// to prevent premature timeouts under server load
class SocketTimeoutManager {
  static final SocketTimeoutManager _instance =
      SocketTimeoutManager._internal();
  factory SocketTimeoutManager() => _instance;
  SocketTimeoutManager._internal();

  final List<int> _recentResponseTimes = [];
  static const int _maxSamples = 10;
  static const int _minTimeoutMs = 5000; // 5 seconds minimum
  static const int _maxTimeoutMs = 15000; // 15 seconds maximum
  static const int _defaultTimeoutMs = 10000; // 10 seconds default

  /// Get adaptive timeout based on recent response times
  Duration getTimeout() {
    if (_recentResponseTimes.isEmpty) {
      return const Duration(milliseconds: _defaultTimeoutMs);
    }

    // Calculate average response time
    final avgTime =
        _recentResponseTimes.reduce((a, b) => a + b) /
        _recentResponseTimes.length;

    // Timeout = 2x average + 3 second buffer
    final timeoutMs = (avgTime * 2 + 3000).toInt();

    // Clamp between min and max
    final clampedTimeout = max(_minTimeoutMs, min(_maxTimeoutMs, timeoutMs));

    print(
      '📊 Adaptive timeout: ${clampedTimeout}ms (avg response: ${avgTime.toInt()}ms)',
    );

    return Duration(milliseconds: clampedTimeout);
  }

  /// Record a successful response time
  void recordResponseTime(int milliseconds) {
    _recentResponseTimes.add(milliseconds);

    // Keep only last N samples
    if (_recentResponseTimes.length > _maxSamples) {
      _recentResponseTimes.removeAt(0);
    }
  }

  /// Reset statistics (e.g., after network change)
  void reset() {
    _recentResponseTimes.clear();
  }
}
