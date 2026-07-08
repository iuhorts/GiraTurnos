import 'package:flutter/material.dart';

class ShiftType {
  final String id;
  final String name;
  final String abbreviation;
  final Color color;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isWorkDay;
  final double hourlyRate;

  const ShiftType({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.color,
    this.startTime,
    this.endTime,
    this.isWorkDay = true,
    this.hourlyRate = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'color': color.value,
        'startHour': startTime?.hour,
        'startMinute': startTime?.minute,
        'endHour': endTime?.hour,
        'endMinute': endTime?.minute,
        'isWorkDay': isWorkDay ? 1 : 0,
        'hourlyRate': hourlyRate,
      };

  factory ShiftType.fromJson(Map<String, dynamic> json) => ShiftType(
        id: json['id'] as String,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
        color: Color(json['color'] as int),
        startTime: json['startHour'] != null
            ? TimeOfDay(
                hour: json['startHour'] as int,
                minute: json['startMinute'] as int,
              )
            : null,
        endTime: json['endHour'] != null
            ? TimeOfDay(
                hour: json['endHour'] as int,
                minute: json['endMinute'] as int,
              )
            : null,
        isWorkDay: (json['isWorkDay'] as int) == 1,
        hourlyRate: (json['hourlyRate'] as num).toDouble(),
      );

  static const List<ShiftType> defaults = [
    ShiftType(
      id: 'morning',
      name: 'Mañana',
      abbreviation: 'M',
      color: Color(0xFFFFA726),
      startTime: TimeOfDay(hour: 6, minute: 0),
      endTime: TimeOfDay(hour: 14, minute: 0),
    ),
    ShiftType(
      id: 'afternoon',
      name: 'Tarde',
      abbreviation: 'T',
      color: Color(0xFF42A5F5),
      startTime: TimeOfDay(hour: 14, minute: 0),
      endTime: TimeOfDay(hour: 22, minute: 0),
    ),
    ShiftType(
      id: 'night',
      name: 'Noche',
      abbreviation: 'N',
      color: Color(0xFF7E57C2),
      startTime: TimeOfDay(hour: 22, minute: 0),
      endTime: TimeOfDay(hour: 6, minute: 0),
    ),
    ShiftType(
      id: 'off',
      name: 'Libre',
      abbreviation: 'L',
      color: Color(0xFF66BB6A),
      isWorkDay: false,
    ),
    ShiftType(
      id: 'holiday',
      name: 'Vacaciones',
      abbreviation: 'V',
      color: Color(0xFFEF5350),
      isWorkDay: false,
    ),
    ShiftType(
      id: 'sick',
      name: 'Baja',
      abbreviation: 'B',
      color: Color(0xFFBDBDBD),
      isWorkDay: false,
    ),
  ];

  static ShiftType? findById(String id) {
    try {
      return defaults.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
