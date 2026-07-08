import 'package:flutter/material.dart';

class Profile {
  final String id;
  String name;
  Color color;
  bool isActive;
  DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    this.color = Colors.blue,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'isActive': isActive ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        isActive: (json['isActive'] as int) == 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Profile copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}
