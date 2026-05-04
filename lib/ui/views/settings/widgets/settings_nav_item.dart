import 'package:flutter/material.dart';

/// Widget reutilizable para los items del sidebar lateral de Settings.
class SettingsNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SettingsNavItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
