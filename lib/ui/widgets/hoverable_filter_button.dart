import 'package:flutter/material.dart';

class HoverableFilterButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String label;
  final IconData icon;
  final bool isActive;
  final String? tooltip;

  const HoverableFilterButton({
    super.key,
    required this.onTap,
    this.onClear,
    required this.label,
    required this.icon,
    this.isActive = false,
    this.tooltip,
  });

  @override
  State<HoverableFilterButton> createState() => _HoverableFilterButtonState();
}

class _HoverableFilterButtonState extends State<HoverableFilterButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? Colors.blue.shade50
                    : (_isHovering ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.isActive ? Colors.blue.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? Colors.blue : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isActive && widget.onClear != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: GestureDetector(
                    onTap: widget.onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip, child: content);
    }
    return content;
  }
}
