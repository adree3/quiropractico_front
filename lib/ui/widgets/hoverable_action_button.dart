import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';

class HoverableActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isPrimary;
  final String? tooltip;

  const HoverableActionButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.tooltip,
  });

  @override
  State<HoverableActionButton> createState() => _HoverableActionButtonState();
}

class _HoverableActionButtonState extends State<HoverableActionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isPrimary
                    ? (_isHovering
                        ? AppTheme.primaryColor.withOpacity(0.9)
                        : AppTheme.primaryColor)
                    : (_isHovering ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                widget.isPrimary
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: content);
    }
    return content;
  }
}
