import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/shift.dart';
import '../models/note.dart';
import '../models/export_data.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'turnosfamilia.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color INTEGER NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE shifts (
            id TEXT PRIMARY KEY,
            profileId TEXT NOT NULL,
            date TEXT NOT NULL,
            typeId TEXT NOT NULL,
            note TEXT,
            startTime TEXT,
            endTime TEXT,
            extraHours REAL NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES profiles(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            profileId TEXT NOT NULL,
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES profiles(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_shifts_date ON shifts(date)
        ''');
        await db.execute('''
          CREATE INDEX idx_shifts_profile ON shifts(profileId)
        ''');
        await db.execute('''
          CREATE INDEX idx_notes_date ON notes(date)
        ''');
      },
    );
  }

  // --- Profiles ---
  static Future<List<Profile>> getProfiles() async {
    final db = await DatabaseService.db;
    final rows = await db.query('profiles', orderBy: 'createdAt ASC');
    return rows.map((r) => Profile.fromJson(r)).toList();
  }

  static Future<void> saveProfile(Profile profile) async {
    final db = await DatabaseService.db;
    await db.insert('profiles', profile.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteProfile(String id) async {
    final db = await DatabaseService.db;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('shifts', where: 'profileId = ?', whereArgs: [id]);
    await db.delete('notes', where: 'profileId = ?', whereArgs: [id]);
  }

  // --- Shifts ---
  static Future<List<Shift>> getShifts({
    String? profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DatabaseService.db;
    final where = <String>[];
    final args = <dynamic>[];
    if (profileId != null) {
      where.add('profileId = ?');
      args.add(profileId);
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String().substring(0, 10));
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate.toIso8601String().substring(0, 10));
    }
    final rows = await db.query(
      'shifts',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date ASC, createdAt ASC',
    );
    return rows.map((r) => Shift.fromJson(r)).toList();
  }

  static Future<Shift?> getShift(String profileId, DateTime date) async {
    final db = await DatabaseService.db;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'shifts',
      where: 'profileId = ? AND date = ?',
      whereArgs: [profileId, dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Shift.fromJson(rows.first);
  }

  static Future<void> saveShift(Shift shift) async {
    final db = await DatabaseService.db;
    final existing = await getShift(shift.profileId, shift.date);
    final s = shift.copyWith(
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.insert('shifts', s.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteShift(String id) async {
    final db = await DatabaseService.db;
    await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteShiftByDate(String profileId, DateTime date) async {
    final db = await DatabaseService.db;
    final dateStr = date.toIso8601String().substring(0, 10);
    await db.delete('shifts',
        where: 'profileId = ? AND date = ?', whereArgs: [profileId, dateStr]);
  }

  // --- Notes ---
  static Future<List<Note>> getNotes(String profileId, DateTime date) async {
    final db = await DatabaseService.db;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'notes',
      where: 'profileId = ? AND date = ?',
      whereArgs: [profileId, dateStr],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => Note.fromJson(r)).toList();
  }

  static Future<List<Note>> getAllNotes({String? profileId}) async {
    final db = await DatabaseService.db;
    final where = <String>[];
    final args = <dynamic>[];
    if (profileId != null) {
      where.add('profileId = ?');
      args.add(profileId);
    }
    final rows = await db.query(
      'notes',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, createdAt DESC',
    );
    return rows.map((r) => Note.fromJson(r)).toList();
  }

  static Future<void> saveNote(Note note) async {
    final db = await DatabaseService.db;
    await db.insert('notes', note.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteNote(String id) async {
    final db = await DatabaseService.db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---
  static Future<String?> getSetting(String key) async {
    final db = await DatabaseService.db;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await DatabaseService.db;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Sync helpers ---
  static Future<ExportData> getAllData() async {
    final profiles = await getProfiles();
    final shifts = await getShifts();
    final notes = await getAllNotes();
    return ExportData(profiles: profiles, shifts: shifts, notes: notes);
  }

  static Future<void> importData(ExportData data) async {
    final db = await DatabaseService.db;
    await db.transaction((txn) async {
      for (final profile in data.profiles) {
        await txn.insert('profiles', profile.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final shift in data.shifts) {
        final s = shift.toJson();
        s['createdAt'] = shift.createdAt.toIso8601String();
        s['updatedAt'] = DateTime.now().toIso8601String();
        await txn.insert('shifts', s,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final note in data.notes) {
        final n = note.toJson();
        n['createdAt'] = note.createdAt.toIso8601String();
        n['updatedAt'] = DateTime.now().toIso8601String();
        await txn.insert('notes', n,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<String> exportToJson() async {
    final data = await getAllData();
    return jsonEncode(data.toJson());
  }

  static Future<void> importFromJson(String jsonStr) async {
    final data = ExportData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    await importData(data);
  }
}
