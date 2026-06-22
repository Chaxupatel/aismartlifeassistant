import 'package:flutter/material.dart';

/// AppColors contains all the color constants for the application,
/// upgraded for a premium, modern iOS 26 inspired hyper-glossy aesthetic.
class AppColors {
  AppColors._();

  // Primary brand colors (Vibrant iOS style)
  static const Color primary = Color(0xFF6366F1);    // Electric Indigo
  static const Color secondary = Color(0xFF06B6D4);  // Cyber Cyan
  static const Color accent = Color(0xFFEC4899);     // Neon Pink
  static const Color success = Color(0xFF10B981);    // Premium Emerald
  static const Color warning = Color(0xFFF59E0B);    // Premium Amber
  static const Color error = Color(0xFFEF4444);      // Coral Red

  // Light theme backgrounds & surfaces (Titanium Silver style)
  static const Color lightBgStart = Color(0xFFF8FAFC);
  static const Color lightBgEnd = Color(0xFFE2E8F0);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightGlass = Color(0x3BFFFFFF); // Frosted translucent white
  static const Color lightGlassBorder = Color(0x73FFFFFF); // Dual outline white

  // Dark theme backgrounds & surfaces (Obsidian Midnight style)
  static const Color darkBgStart = Color(0xFF040408);
  static const Color darkBgEnd = Color(0xFF0B0B12);
  static const Color darkCard = Color(0xFF0F172A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkGlass = Color(0x18FFFFFF); // Frosted translucent black
  static const Color darkGlassBorder = Color(0x28FFFFFF); // Fine white border outline

  // Specular highlights (iOS 26 glass refraction)
  static const Color specularHighlight = Color(0x60FFFFFF);
  static const Color specularShine = Color(0x0CFFFFFF);

  // Shared gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)], // Indigo to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFF43F5E)], // Neon Pink to Rose
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF3B82F6)], // Cyan to Royal Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassLightGradient = LinearGradient(
    colors: [
      Color(0x4DFFFFFF),
      Color(0x13FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassDarkGradient = LinearGradient(
    colors: [
      Color(0x22FFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
