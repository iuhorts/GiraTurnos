import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'database_service.dart';

class DriveSyncService extends ChangeNotifier {
  static const _syncFileName = 'turnosfamilia_backup.json';
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;
  auth.AuthClient? _authClient;
  bool _isSyncing = false;
  bool _isSignedIn = false;
  String? _lastError;

  GoogleSignInAccount? get account => _account;
  bool get isSyncing => _isSyncing;
  bool get isSignedIn => _isSignedIn;
  String? get lastError => _lastError;

  Future<bool> signIn() async {
    try {
      _account = await GoogleSignIn(scopes: _scopes).signIn();
      if (_account == null) return false;

      final headers = await _account!.authHeaders;
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      if (token == null) return false;

      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', token, DateTime.now().add(const Duration(hours: 1))),
        null,
        _scopes,
      );

      final client = http.Client();
      _authClient = auth.authenticatedClient(client, credentials);
      _driveApi = drive.DriveApi(_authClient!);
      _isSignedIn = true;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error al iniciar sesión: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _authClient?.close();
    await GoogleSignIn().signOut();
    _account = null;
    _driveApi = null;
    _authClient = null;
    _isSignedIn = false;
    notifyListeners();
  }

  Future<void> pushToDrive() async {
    if (_driveApi == null || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final jsonStr = await DatabaseService.exportToJson();
      final bytes = utf8.encode(jsonStr);

      final existing = await _findSyncFile();
      final file = drive.File()
        ..name = _syncFileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/json';

      if (existing != null) {
        await _driveApi!.files.update(
          file,
          existing.id!,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
        );
      } else {
        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
        );
      }
      _lastError = null;
      await DatabaseService.setSetting('lastSyncAt', DateTime.now().toIso8601String());
    } catch (e) {
      _lastError = 'Error al subir: $e';
    }

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> pullFromDrive() async {
    if (_driveApi == null || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final existing = await _findSyncFile();
      if (existing == null) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      final media = await _driveApi!.files.get(
        existing.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final jsonStr = await utf8.decodeStream(media.stream);
      await DatabaseService.importFromJson(jsonStr);
      _lastError = null;
      await DatabaseService.setSetting('lastSyncAt', DateTime.now().toIso8601String());
    } catch (e) {
      _lastError = 'Error al bajar: $e';
    }

    _isSyncing = false;
    notifyListeners();
  }

  Future<drive.File?> _findSyncFile() async {
    if (_driveApi == null) return null;
    try {
      final response = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_syncFileName'",
        pageSize: 1,
      );
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first;
      }
    } catch (_) {}
    return null;
  }

  Future<void> autoSync() async {
    if (!_isSignedIn || _driveApi == null) return;
    try {
      await pullFromDrive();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authClient?.close();
    super.dispose();
  }
}
