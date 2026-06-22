import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Light theme configurations for the app, upgraded for iOS 26 styling.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBgStart,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.lightCard,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.lightTextPrimary,
    onError: Colors.white,
  ),
  cardColor: AppColors.lightCard,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    titleTextStyle: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w800, // Thicker header
      letterSpacing: -0.8,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 34,
      fontWeight: FontWeight.w900, // Ultra bold display
      letterSpacing: -1.2,
    ),
    headlineMedium: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    titleLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    bodyLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500, // Semi-bold body
      letterSpacing: -0.1,
    ),
    bodyMedium: TextStyle(
      color: AppColors.lightTextSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: AppColors.primary,
    textTheme: ButtonTextTheme.primary,
  ),
  cardTheme: CardThemeData(
    color: AppColors.lightCard,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusL), // Increased radius
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0x1F000000),
    thickness: 1,
    space: AppSizes.m,
  ),
);
