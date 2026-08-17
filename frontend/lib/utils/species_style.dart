import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeciesStyle {
  static const Map<String, Color> _colors = {
    'dog': Color(0xFFE8756B),
    'cat': Color(0xFF8FA98C),
    'bird': Color(0xFF6BAED6),
    'fish': Color(0xFF5FB7B0),
    'reptile': Color(0xFFC9A227),
    'other': Color(0xFFB08FA9),
  };

  static Color colorFor(String species) =>
      _colors[species] ?? AppColors.primary;
}
