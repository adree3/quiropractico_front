import 'package:flutter/material.dart';

class DropdownOption<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color color;

  const DropdownOption({
    required this.value,
    required this.label,
    required this.icon,
    this.color = Colors.black87,
  });
}

class DashboardDropdown<T> extends StatelessWidget {
  final T selectedValue;
  final List<DropdownOption<T>> options;
  final Function(T) onSelected;

  final String? customLabel;
  final IconData? customIcon;

  const DashboardDropdown({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.customLabel,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => options.first,
    );

    final displayLabel = customLabel ?? selectedOption.label;
    final displayIcon = customIcon ?? selectedOption.icon;
    final displayColor =
        customIcon != null ? Colors.grey : selectedOption.color;

    return PopupMenuButton<DropdownOption<T>>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (option) => onSelected(option.value),
      itemBuilder:
          (ctx) =>
              options
                  .map(
                    (opt) => PopupMenuItem<DropdownOption<T>>(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(opt.icon, size: 18, color: opt.color),
                          const SizedBox(width: 10),
                          Text(opt.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(displayIcon, size: 16, color: displayColor),
            const SizedBox(width: 10),
            Text(
              displayLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
