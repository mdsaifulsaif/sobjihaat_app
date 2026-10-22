import 'package:flutter/material.dart';

/// App color palette derived directly from the SobjiHaat Web Design System & Master Prompt
class AppColors {
  AppColors._();

  // Core Theme Colors
  static const Color primary = Color(0xFF619D23); // Fresh leaf green
  static const Color primaryLight = Color(0xFFEBF5E1); // Light tint for badges/accents
  static const Color primaryDark = Color(0xFF52861C); // Dark green for active states
  
  static const Color secondary = Color(0xFF4B5966); // Slate Gray
  static const Color accent = Color(0xFFFF6B6B); // Coral red accent
  static const Color discountBadge = Color(0xFFEA4335); // Vivid red for discounts & plan pills
  static const Color surface = Color(0xFFF8FAFC); // Soft off-white surface
  static const Color background = Color(0xFFFFFFFF); // Pure white

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Deep navy/black
  static const Color textSecondary = Color(0xFF4B5966); // Subdued text
  static const Color textMuted = Color(0xFF94A3B8); // Muted placeholders & hints

  // Status & Feedback Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Borders and Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF619D23);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF619D23), Color(0xFF75B92D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
