import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String colorToHex(Color c) =>
    '#${c.r.round().toRadixString(16).padLeft(2, '0')}'
    '${c.g.round().toRadixString(16).padLeft(2, '0')}'
    '${c.b.round().toRadixString(16).padLeft(2, '0')}'
    .toUpperCase();
