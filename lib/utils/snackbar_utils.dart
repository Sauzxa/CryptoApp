import 'package:flutter/material.dart';

class SnackbarUtils {
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _shortDuration = Duration(seconds: 2);

  /// Show a success snackbar with optimized timing
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: duration ?? _shortDuration,
    );
  }

  /// Show an error snackbar with optimized timing
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.red,
      duration: duration ?? _defaultDuration,
    );
  }

  /// Show a warning snackbar with optimized timing
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: duration ?? _defaultDuration,
    );
  }

  /// Show an info snackbar with optimized timing
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.blue,
      duration: duration ?? _shortDuration,
    );
  }

  /// Show a loading snackbar (for temporary operations)
  static void showLoading(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.grey[600]!,
      duration: duration ?? _shortDuration,
    );
  }

  /// Internal method to show snackbar with consistent styling
  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Duration duration,
  }) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Clear all snackbars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Show a custom snackbar with specific styling
  static void showCustom(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: backgroundColor ?? Colors.grey[600]!,
      duration: duration ?? _defaultDuration,
    );
  }
}
