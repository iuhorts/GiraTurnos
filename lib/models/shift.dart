import 'shift_type.dart';

class Shift {
  final String id;
  final String profileId;
  final DateTime date;
  final String typeId;
  final String? note;
  final DateTime? startTime;
  final DateTime? endTime;
  final double extraHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift({
    required this.id,
    required this.profileId,
    required this.date,
    required this.typeId,
    this.note,
    this.startTime,
    this.endTime,
    this.extraHours = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ShiftType? get shiftType => ShiftType.findById(typeId);

  double get hoursWorked {
    if (startTime == null || endTime == null || !(shiftType?.isWorkDay ?? false)) {
      return 0;
    }
    final diff = endTime!.difference(startTime!);
    return diff.inMinutes / 60.0 + extraHours;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'date': date.toIso8601String().substring(0, 10),
        'typeId': typeId,
        'note': note,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'extraHours': extraHours,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        date: DateTime.parse(json['date'] as String),
        typeId: json['typeId'] as String,
        note: json['note'] as String?,
        startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        extraHours: (json['extraHours'] as num?)?.toDouble() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  Shift copyWith({
    String? id,
    String? profileId,
    DateTime? date,
    String? typeId,
    String? note,
    DateTime? startTime,
    DateTime? endTime,
    double? extraHours,
    DateTime? createdAt,
  }) =>
      Shift(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        date: date ?? this.date,
        typeId: typeId ?? this.typeId,
        note: note ?? this.note,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        extraHours: extraHours ?? this.extraHours,
        createdAt: createdAt ?? this.createdAt,
      );
}
