import 'package:flutter/material.dart';
import '../../main.dart' show appNavigatorKey;
import 'haptic_helper.dart';

enum ToastType { success, error, warning, info }

/// Branded floating SnackBar and Toast system for Matrimony Mobile & Admin Panel
class AppToast {
  static void showSuccess(
    dynamic contextOrTitle, [
    dynamic messageOrSubtitle,
    String? title,
  ]) {
    HapticHelper.success();
    _parseAndShow(
      contextOrTitle: contextOrTitle,
      messageOrSubtitle: messageOrSubtitle,
      explicitTitle: title,
      defaultTitle: 'വിജയം (Success)',
      type: ToastType.success,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981),
    );
  }

  static void showError(
    dynamic contextOrTitle, [
    dynamic messageOrSubtitle,
    String? title,
  ]) {
    HapticHelper.error();
    _parseAndShow(
      contextOrTitle: contextOrTitle,
      messageOrSubtitle: messageOrSubtitle,
      explicitTitle: title,
      defaultTitle: 'പിശക് (Error)',
      type: ToastType.error,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  static void showWarning(
    dynamic contextOrTitle, [
    dynamic messageOrSubtitle,
    String? title,
  ]) {
    HapticHelper.mediumImpact();
    _parseAndShow(
      contextOrTitle: contextOrTitle,
      messageOrSubtitle: messageOrSubtitle,
      explicitTitle: title,
      defaultTitle: 'മുന്നറിയിപ്പ് (Warning)',
      type: ToastType.warning,
      icon: Icons.warning_amber_rounded,
      backgroundColor: const Color(0xFFF59E0B),
    );
  }

  static void showInfo(
    dynamic contextOrTitle, [
    dynamic messageOrSubtitle,
    String? title,
  ]) {
    HapticHelper.lightImpact();
    _parseAndShow(
      contextOrTitle: contextOrTitle,
      messageOrSubtitle: messageOrSubtitle,
      explicitTitle: title,
      defaultTitle: 'വിവരം (Info)',
      type: ToastType.info,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF000080),
    );
  }

  static void _parseAndShow({
    required dynamic contextOrTitle,
    required dynamic messageOrSubtitle,
    String? explicitTitle,
    required String defaultTitle,
    required ToastType type,
    required IconData icon,
    required Color backgroundColor,
  }) {
    BuildContext? ctx;
    String displayTitle = explicitTitle ?? defaultTitle;
    String displayMessage = '';

    if (contextOrTitle is BuildContext) {
      ctx = contextOrTitle;
      if (messageOrSubtitle is String) {
        displayMessage = messageOrSubtitle;
      }
    } else if (contextOrTitle is String) {
      ctx = appNavigatorKey.currentContext;
      displayTitle = explicitTitle ?? contextOrTitle;
      if (messageOrSubtitle is String) {
        displayMessage = messageOrSubtitle;
      }
    }

    if (ctx == null || !ctx.mounted) {
      ctx = appNavigatorKey.currentContext;
    }

    if (ctx == null || !ctx.mounted) return;

    _showFloatingSnackBar(
      ctx,
      message: displayMessage.isNotEmpty ? displayMessage : displayTitle,
      title: displayTitle,
      type: type,
      icon: icon,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
    );
  }

  static void _showFloatingSnackBar(
    BuildContext context, {
    required String message,
    required String title,
    required ToastType type,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    if (message != title) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
