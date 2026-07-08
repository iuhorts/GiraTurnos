import 'profile.dart';
import 'shift.dart';
import 'note.dart';

class ExportData {
  final List<Profile> profiles;
  final List<Shift> shifts;
  final List<Note> notes;
  final DateTime exportedAt;

  ExportData({
    required this.profiles,
    required this.shifts,
    required this.notes,
    DateTime? exportedAt,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'version': 1,
        'exportedAt': exportedAt.toIso8601String(),
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'shifts': shifts.map((s) => s.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  factory ExportData.fromJson(Map<String, dynamic> json) {
    final profiles = (json['profiles'] as List<dynamic>?)
            ?.map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final profileIds = profiles.map((p) => p.id).toSet();

    return ExportData(
      profiles: profiles,
      shifts: (json['shifts'] as List<dynamic>?)
              ?.map((e) => Shift.fromJson(e as Map<String, dynamic>))
              .where((s) => profileIds.contains(s.profileId))
              .toList() ??
          [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
              .where((n) => profileIds.contains(n.profileId))
              .toList() ??
          [],
    );
  }
}
