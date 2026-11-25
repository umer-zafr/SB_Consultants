import 'package:flutter/material.dart';

/// Defines the full Material 3 typescale for the application.
///
/// Prefer accessing styles through [BuildContext] extensions:
/// ```dart
/// Text('Hello', style: context.textTheme.titleLarge);
/// ```
TextTheme buildTextTheme() {
  const baseTextTheme = TextTheme(
    // ── Display ──────────────────────────────────────────────────────────────
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),

    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),

    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),

    // ── Headline ─────────────────────────────────────────────────────────────
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),

    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),

    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),

    // ── Title ─────────────────────────────────────────────────────────────────
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),

    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),

    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),

    // ── Body ──────────────────────────────────────────────────────────────────
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),

    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),

    bodySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),

    // ── Label ─────────────────────────────────────────────────────────────────
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),

    labelMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),

    labelSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  return baseTextTheme;
}