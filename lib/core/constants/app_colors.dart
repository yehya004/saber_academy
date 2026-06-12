import 'package:flutter/material.dart';

/// All color tokens derived from the Saber Academy brand (see Design.md).
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────
  static const Color primary   = Color(0xFF154734); // Deep green – AppBars, buttons, nav
  static const Color secondary = Color(0xFFD4AF37); // Gold – active icons, progress, accents

  // ── Backgrounds ────────────────────────────────────────────
  static const Color background = Color(0xFFF9F7F2); // Warm off-white
  static const Color surface    = Color(0xFFFFFFFF); // Cards, dialogs, inputs

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF2D2821); // Main headings & body
  static const Color textSecondary = Color(0xFF736B5E); // Subtitles, dates, placeholders

  // ── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF28A745); // Present
  static const Color error   = Color(0xFFDC3545); // Absent / error
  static const Color warning = Color(0xFFFFC107); // Pending / warning

  // ── Misc ───────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFE0DCD3); // Progress bar background
  static const Color studentBubble = Color(0xFFEAE6DF); // Student chat bubble

  // ── Mushaf Viewer modes ────────────────────────────────────
  static const Color mushafSepiaBg   = Color(0xFFF4EFE6);
  static const Color mushafSepiaText = Color(0xFF1A1A1A);
  static const Color mushafDarkBg    = Color(0xFF121212);
  static const Color mushafDarkText  = Color(0xFFE0E0E0);
}
