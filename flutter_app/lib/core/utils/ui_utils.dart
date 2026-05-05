import 'package:flutter/material.dart';

class UiUtils {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFF4CAF50),
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFFE53935),
      icon: Icons.error_outline,
    );
  }

  static void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    messengerKey.currentState?.removeCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
