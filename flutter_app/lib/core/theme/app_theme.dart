import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          surface: AppColors.background,
          onSurface: AppColors.text,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
          headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
          titleLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          titleMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
          bodyLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
          bodyMedium: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          labelSmall: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 52), // WCAG 2.1 мін. 44dp
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.nunito(color: Colors.white54, fontSize: 14),
          labelStyle: GoogleFonts.nunito(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
