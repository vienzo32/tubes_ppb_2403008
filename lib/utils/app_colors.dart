import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color accent = Color(0xFFFFE66D);
  
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
    ],
  );
}

// Extension untuk mengganti .withOpacity (deprecated)
extension ColorUtils on Color {
  Color withValues({double? alpha}) {
    return this.withOpacity(alpha ?? opacity);
  }
  
  double get opacity => this.opacity;
}