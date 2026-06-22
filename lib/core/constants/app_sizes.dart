import 'package:flutter/material.dart';

/// AppSizes provides unified sizing constraints, padding, margins,
/// and border radius values to achieve an elegant, responsive layout.
class AppSizes {
  AppSizes._();

  // Spacing (Padding/Margin)
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radii
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  // Icon Sizes
  static const double iconS = 18.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;

  // Responsive Breakpoints
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  // Helpers to check device profiles
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > mobileMax &&
      MediaQuery.of(context).size.width <= tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMax;

  // Custom height/width calculations helper
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.width;
}
