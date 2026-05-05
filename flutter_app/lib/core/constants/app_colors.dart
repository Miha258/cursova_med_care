import 'package:flutter/material.dart';

// MedCare CRM — Design tokens (відповідає medcare-tokens.jsx)
class AppColors {
  AppColors._();

  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFF1E88E5);
  static const accent = Color(0xFFFFC107);

  static const background = Color(0xFFF5F7FA);
  static const white = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const text = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);

  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  static const border = Color(0xFFE5E7EB);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );
}
