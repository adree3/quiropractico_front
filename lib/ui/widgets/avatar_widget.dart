import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String nombreCompleto;
  final double radius;
  final double fontSize;
  final int? id;

  const AvatarWidget({
    Key? key,
    required this.nombreCompleto,
    this.radius = 20,
    this.fontSize = 16,
    this.id,
  }) : super(key: key);

  Color _getColorFromHash(String name, int? id) {
    int seed;
    if (id != null) {
      seed = id;
    } else {
      seed = name.hashCode;
    }
    final double hue = (seed.abs() * 137.508) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.80).toColor();
  }

  Color _getTextColorFromBg(Color bg) {
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    if (nombreCompleto.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: fontSize, color: Colors.grey),
      );
    }

    final color = _getColorFromHash(nombreCompleto, id);
    final textColor = _getTextColorFromBg(color);
    final inicial = nombreCompleto.trim().isNotEmpty
      ? nombreCompleto.trim()[0].toUpperCase()
      : "?";

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        inicial,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
