import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// A reusable scaffold message component that can display success, warning, or error messages
/// with dynamic text and optional additional info
class ScaffoldMessage {
  /// Show a success message with optional additional info
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showMessage(
      context,
      message: message,
      additionalInfo: additionalInfo,
      type: MessageType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show a warning message with optional additional info
  static void showWarning(
    BuildContext context, {
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showMessage(
      context,
      message: message,
      additionalInfo: additionalInfo,
      type: MessageType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an error message with optional additional info
  static void showError(
    BuildContext context, {
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showMessage(
      context,
      message: message,
      additionalInfo: additionalInfo,
      type: MessageType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an info message with optional additional info
  static void showInfo(
    BuildContext context, {
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showMessage(
      context,
      message: message,
      additionalInfo: additionalInfo,
      type: MessageType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Internal method to show the message
  static void _showMessage(
    BuildContext context, {
    required String message,
    String? additionalInfo,
    required MessageType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _MessageContent(
          message: message,
          additionalInfo: additionalInfo,
          type: type,
        ),
        backgroundColor: _getBackgroundColor(type),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Get background color based on message type
  static Color _getBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.success:
        return const Color(AppConfig.successColor);
      case MessageType.warning:
        return const Color(AppConfig.warningColor);
      case MessageType.error:
        return const Color(AppConfig.errorColor);
      case MessageType.info:
        return const Color(AppConfig.primaryColor);
    }
  }
}

/// Message types enum
enum MessageType {
  success,
  warning,
  error,
  info,
}

/// Content widget for the scaffold message
class _MessageContent extends StatelessWidget {
  final String message;
  final String? additionalInfo;
  final MessageType type;

  const _MessageContent({
    required this.message,
    this.additionalInfo,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Icon(
          _getIcon(),
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main message
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              // Additional info if provided
              if (additionalInfo != null) ...[
                const SizedBox(height: 4),
                Text(
                  additionalInfo!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Get icon based on message type
  IconData _getIcon() {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.error:
        return Icons.error;
      case MessageType.info:
        return Icons.info;
    }
  }
}

/// Extension methods for easy access to scaffold messages
extension ScaffoldMessageExtension on BuildContext {
  /// Show success message
  void showSuccessMessage({
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessage.showSuccess(
      this,
      message: message,
      additionalInfo: additionalInfo,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show warning message
  void showWarningMessage({
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessage.showWarning(
      this,
      message: message,
      additionalInfo: additionalInfo,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show error message
  void showErrorMessage({
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessage.showError(
      this,
      message: message,
      additionalInfo: additionalInfo,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show info message
  void showInfoMessage({
    required String message,
    String? additionalInfo,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessage.showInfo(
      this,
      message: message,
      additionalInfo: additionalInfo,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
