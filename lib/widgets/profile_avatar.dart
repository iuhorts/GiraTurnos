import 'package:flutter/material.dart';
import '../models/profile.dart';

class ProfileAvatar extends StatelessWidget {
  final Profile profile;
  final double radius;
  final bool showName;
  final bool isSelected;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 20,
    this.showName = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: profile.color,
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 2),
            Text(
              profile.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? profile.color : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
