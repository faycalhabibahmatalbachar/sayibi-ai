import 'package:flutter/material.dart';

/// SAYIBI AI Design System — Colors
/// Palette inspirée de : Linear, Notion, Apple Design
class AppColors {
  AppColors._();

  // ==================== PRIMARY COLORS ====================

  /// Violet profond — couleur principale SAYIBI
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9F93FF);
  static const primaryDark = Color(0xFF4A42CC);

  /// Teal accent — couleur secondaire
  static const accent = Color(0xFF00D4AA);
  static const accentLight = Color(0xFF33DDBB);
  static const accentDark = Color(0xFF00A885);

  // ==================== GRADIENTS ====================

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF5B4FE8)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF00BF9A)],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
  );

  static const glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  // ==================== DARK THEME (DEFAULT) ====================

  static const darkBackground = Color(0xFF0A0E27);
  static const darkSurface = Color(0xFF1A1F3A);
  static const darkCard = Color(0xFF242B47);
  static const darkBorder = Color(0xFF2D3448);

  // Text colors
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB8BCC8);
  static const darkTextTertiary = Color(0xFF6B7280);

  // ==================== LIGHT THEME ====================

  static const lightBackground = Color(0xFFFAFBFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF5F6F8);
  static const lightBorder = Color(0xFFE5E7EB);

  // Text colors
  static const lightTextPrimary = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF4B5563);
  static const lightTextTertiary = Color(0xFF9CA3AF);

  // ==================== SEMANTIC COLORS ====================

  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF34D399);
  static const successBg = Color(0xFF064E3B);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFF87171);
  static const errorBg = Color(0xFF7F1D1D);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFBBF24);
  static const warningBg = Color(0xFF78350F);

  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFF60A5FA);
  static const infoBg = Color(0xFF1E3A8A);

  // ==================== CHAT COLORS ====================

  static const userMessageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF5B4FE8)],
  );

  static const aiMessageBg = Color(0xFF1E2337);
  static const aiMessageBorder = Color(0xFF2D3448);

  // ==================== SHADOWS ====================

  static const cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const glowShadow = [
    BoxShadow(
      color: Color(0x336C63FF),
      blurRadius: 32,
      offset: Offset(0, 0),
    ),
  ];

  // ==================== RÉTROCOMPAT (écrans existants) ====================

  /// Bordure type « verre » (bulles chat, inputs légers)
  static const glassBorder = Color(0x33FFFFFF);

  /// Alias historiques — même que darkBackground / darkSurface
  static const navy = darkBackground;
  static const surface = darkSurface;
}
