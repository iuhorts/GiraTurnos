import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/shift.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/drive_sync_service.dart';
import '../services/export_service.dart';

class AppProvider extends ChangeNotifier {
  final DriveSyncService syncService = DriveSyncService();

  List<Profile> _profiles = [];
  List<Shift> _shifts = [];
  List<Note> _notes = [];
  String? _activeProfileId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Profile> get profiles => _profiles;
  List<Shift> get shifts => _shifts;
  List<Note> get notes => _notes;
  String? get activeProfileId => _activeProfileId;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  Profile? get activeProfile {
    if (_activeProfileId == null && _profiles.isNotEmpty) {
      return _profiles.first;
    }
    try {
      return _profiles.firstWhere((p) => p.id == _activeProfileId);
    } catch (_) {
      return _profiles.isNotEmpty ? _profiles.first : null;
    }
  }

  List<Profile> get activeProfiles => _profiles.where((p) => p.isActive).toList();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _profiles = await DatabaseService.getProfiles();
    _shifts = await DatabaseService.getShifts();
    _notes = await DatabaseService.getAllNotes();

    if (_activeProfileId == null && _profiles.isNotEmpty) {
      _activeProfileId = _profiles.first.id;
    }

    if (_profiles.isEmpty) {
      await _createDefaultProfiles();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createDefaultProfiles() async {
    final uuid = const Uuid();
    final yo = Profile(id: uuid.v4(), name: 'Yo', color: Colors.blue);
    final pareja = Profile(id: uuid.v4(), name: 'Pareja', color: Colors.pink);
    await DatabaseService.saveProfile(yo);
    await DatabaseService.saveProfile(pareja);
    _profiles = [yo, pareja];
    _activeProfileId = yo.id;
  }

  void setActiveProfile(String id) {
    _activeProfileId = id;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // --- Profile operations ---
  Future<void> addProfile(String name, Color color) async {
    final profile = Profile(id: const Uuid().v4(), name: name, color: color);
    await DatabaseService.saveProfile(profile);
    _profiles.add(profile);
    _activeProfileId = profile.id;
    notifyListeners();
    _triggerSync();
  }

  Future<void> updateProfile(Profile profile) async {
    await DatabaseService.saveProfile(profile);
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) _profiles[idx] = profile;
    notifyListeners();
    _triggerSync();
  }

  Future<void> deleteProfile(String id) async {
    await DatabaseService.deleteProfile(id);
    _profiles.removeWhere((p) => p.id == id);
    _shifts.removeWhere((s) => s.profileId == id);
    _notes.removeWhere((n) => n.profileId == id);
    if (_activeProfileId == id) {
      _activeProfileId = _profiles.isNotEmpty ? _profiles.first.id : null;
    }
    notifyListeners();
    _triggerSync();
  }

  // --- Shift operations ---
  Future<void> setShift(String profileId, DateTime date, String typeId,
      {String? note, DateTime? startTime, DateTime? endTime}) async {
    final existing = await DatabaseService.getShift(profileId, date);
    final shift = Shift(
      id: existing?.id ?? const Uuid().v4(),
      profileId: profileId,
      date: date,
      typeId: typeId,
      note: note ?? existing?.note,
      startTime: startTime ?? existing?.startTime,
      endTime: endTime ?? existing?.endTime,
      createdAt: existing?.createdAt,
    );
    await DatabaseService.saveShift(shift);

    final idx = _shifts.indexWhere(
        (s) => s.profileId == profileId && s.date == date);
    if (idx >= 0) {
      _shifts[idx] = shift;
    } else {
      _shifts.add(shift);
    }
    notifyListeners();
    _triggerSync();
  }

  Future<void> clearShift(String profileId, DateTime date) async {
    await DatabaseService.deleteShiftByDate(profileId, date);
    _shifts.removeWhere(
        (s) => s.profileId == profileId && s.date == date);
    notifyListeners();
    _triggerSync();
  }

  Shift? getShiftForDate(String profileId, DateTime date) {
    try {
      return _shifts.firstWhere(
          (s) => s.profileId == profileId && s.date == date);
    } catch (_) {
      return null;
    }
  }

  // --- Note operations ---
  Future<void> addNote(String profileId, DateTime date, String content) async {
    final note = Note(
        id: const Uuid().v4(),
        profileId: profileId,
        date: date,
        content: content);
    await DatabaseService.saveNote(note);
    _notes.add(note);
    notifyListeners();
    _triggerSync();
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    _triggerSync();
  }

  List<Note> getNotesForDate(String profileId, DateTime date) {
    return _notes
        .where((n) => n.profileId == profileId && n.date == date)
        .toList();
  }

  // --- Stats ---
  Map<String, int> getStatsForPeriod(
      String profileId, DateTime start, DateTime end) {
    final result = <String, int>{};
    for (final s in _shifts) {
      if (s.profileId == profileId &&
          s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1)))) {
        result[s.typeId] = (result[s.typeId] ?? 0) + 1;
      }
    }
    return result;
  }

  double getTotalHours(String profileId, DateTime start, DateTime end) {
    double total = 0;
    for (final s in _shifts) {
      if (s.profileId == profileId &&
          s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1)))) {
        total += s.hoursWorked;
      }
    }
    return total;
  }

  // --- Sync ---
  Future<void> signInAndSync() async {
    final success = await syncService.signIn();
    if (success) {
      await syncService.pullFromDrive();
      await loadData();
    }
  }

  void _triggerSync() {
    if (syncService.isSignedIn) {
      syncService.pushToDrive();
    }
  }

  Future<void> manualSync() async {
    if (syncService.isSignedIn) {
      await syncService.pushToDrive();
      await syncService.pullFromDrive();
      await loadData();
    }
  }

  // --- Export/Import ---
  Future<void> exportToJsonFile() => ExportService.shareJson();
  Future<void> exportToCsvFile() => ExportService.shareCsv();
  Future<void> exportToPdf() => ExportService.sharePdf();
  Future<void> importFromJson(String content) async {
    await ExportService.importJson(content);
    await loadData();
    _triggerSync();
  }
}
