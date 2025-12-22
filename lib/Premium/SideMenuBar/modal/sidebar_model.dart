import 'package:flutter/cupertino.dart';

class MenuItem {
  final IconData? icon;
  final String label;
  final Color? color;
  final bool isColored;

  MenuItem({
    this.icon,
    required this.label,
    this.color,
    this.isColored = false,
  });
}
