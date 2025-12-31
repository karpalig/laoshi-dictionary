import 'package:flutter/material.dart';

class ColorHelper {
  static Color getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return const Color(0xFF00CCFF);
      case 'blue':
        return Colors.blue;
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'pink':
        return Colors.pink;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      default:
        return const Color(0xFF00CCFF);
    }
  }

  static const List<String> availableColors = [
    'cyan',
    'blue',
    'purple',
    'pink',
    'green',
    'orange',
  ];
}
