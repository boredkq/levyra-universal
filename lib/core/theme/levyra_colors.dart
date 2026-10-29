import 'package:flutter/material.dart';

/// Levyra Dark-First Design System Color Tokens.
/// Follows the surface ladder and functional palette of Levyra Desktop & Mobile.
abstract final class LevyraColors {
  // Surface Ladder
  static const Color canvas = Color(0xFF07090D);
  static const Color baseSurface = Color(0xFF0B0E14);
  static const Color container = Color(0xFF0F131B);
  static const Color elevatedContainer = Color(0xFF151A23);
  static const Color highestContainer = Color(0xFF1B2230);

  // Text & Content Hierarchy
  static const Color primaryText = Color(0xFFF4F7FB);
  static const Color secondaryText = Color(0xFFA7B0BE);
  static const Color mutedText = Color(0xFF6B7687);

  // Borders & Structure
  static const Color hairline = Color(0xFF202734);
  static const Color strongOutline = Color(0xFF303949);

  // Functional Accents
  static const Color cyan = Color(0xFF27D9F5);       // Active playback, primary navigation, focus
  static const Color violet = Color(0xFF8B7CFF);     // «Твоя орбита», personal mixes
  static const Color mint = Color(0xFF50E3B3);       // «Открытие», fresh releases, verified badges
  static const Color error = Color(0xFFFF7485);      // Network errors, critical alerts
  static const Color warning = Color(0xFFFFB347);

  // Overlays & Scrims
  static const Color scrim = Color(0xCC000000);
  static const Color glassOverlay = Color(0x26FFFFFF);
}
