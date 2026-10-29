import 'package:flutter/material.dart';
import 'levyra_colors.dart';
import 'levyra_typography.dart';

/// Geometry, Layout Insets, and global ThemeData for Levyra.
abstract final class LevyraTheme {
  // Geometry & Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  // Layout Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2Xl = 32.0;

  // Dimensions
  static const double sidebarWidth = 220.0;
  static const double desktopPlayerHeight = 88.0;
  static const double mobileMiniPlayerHeight = 64.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LevyraColors.canvas,
      primaryColor: LevyraColors.cyan,
      colorScheme: const ColorScheme.dark(
        surface: LevyraColors.baseSurface,
        primary: LevyraColors.cyan,
        secondary: LevyraColors.violet,
        tertiary: LevyraColors.mint,
        error: LevyraColors.error,
        onSurface: LevyraColors.primaryText,
        onPrimary: Colors.black,
      ),
      fontFamily: '.SF Pro Display', // System native stack fallback
      cardTheme: CardTheme(
        color: LevyraColors.container,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: LevyraColors.hairline, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(
        color: LevyraColors.primaryText,
        size: 22,
      ),
    );
  }
}
