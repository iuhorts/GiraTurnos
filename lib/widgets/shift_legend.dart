import 'package:flutter/material.dart';
import '../models/shift_type.dart';

class ShiftLegend extends StatelessWidget {
  final bool horizontal;
  final List<ShiftType>? types;
  final String? activeTypeId;
  final ValueChanged<String>? onTap;

  const ShiftLegend({
    super.key,
    this.horizontal = false,
    this.types,
    this.activeTypeId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = types ?? ShiftType.defaults;

    if (horizontal) {
      return SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: items.map((t) => _buildItem(t)).toList(),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((t) => _buildItem(t)).toList(),
    );
  }

  Widget _buildItem(ShiftType type) {
    final isActive = type.id == activeTypeId;
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(type.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? type.color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? type.color : type.color.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: type.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              type.abbreviation,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
