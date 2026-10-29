import 'package:flutter/material.dart';
import 'levyra_colors.dart';

/// Levyra Typography hierarchy according to Levyra Design System.
abstract final class LevyraTypography {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: LevyraColors.primaryText,
    height: 1.2,
  );

  static const TextStyle pageHeading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: LevyraColors.primaryText,
    height: 1.25,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: LevyraColors.primaryText,
    height: 1.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: LevyraColors.primaryText,
    height: 1.3,
  );

  static const TextStyle navItem = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: LevyraColors.secondaryText,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: LevyraColors.primaryText,
    height: 1.4,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: LevyraColors.secondaryText,
    height: 1.3,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: LevyraColors.mutedText,
    height: 1.2,
  );

  static const TextStyle karaokeActive = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: Colors.white,
    height: 1.35,
  );

  static const TextStyle karaokeInactive = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: Color(0x66FFFFFF),
    height: 1.35,
  );
}
