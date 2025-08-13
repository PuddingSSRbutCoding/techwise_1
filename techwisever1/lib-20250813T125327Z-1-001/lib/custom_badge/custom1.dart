import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color iconColor;

  const CustomBadge({
    super.key,
    required this.icon,
    required this.startColor,
    required this.endColor,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: endColor.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: iconColor, size: 30),
    );
  }
}
