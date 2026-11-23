import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final controleurStorageProvider = Provider<ControleurStorage>((ref) {
  return ControleurStorage(const FlutterSecureStorage());
});

class ControleurStorage {
  final FlutterSecureStorage _storage;

  ControleurStorage(this._storage);

  static const _tokenKey = 'malitrans_controleur_jwt';
  static const _userKey = 'malitrans_controleur_user';

  void saveToken(String token, {void Function()? onDone}) {
    _storage.write(key: _tokenKey, value: token).then((_) {
      if (onDone != null) onDone();
    });
  }

  void getToken({required void Function(String? token) onResult}) {
    _storage.read(key: _tokenKey).then(onResult);
  }

  void saveControleur(Map<String, dynamic> userJson, {void Function()? onDone}) {
    _storage.write(key: _userKey, value: jsonEncode(userJson)).then((_) {
      if (onDone != null) onDone();
    });
  }

  void getControleur({
    required void Function(Map<String, dynamic>? controleurJson) onResult,
  }) {
    _storage.read(key: _userKey).then((raw) {
      if (raw == null || raw.isEmpty) {
        onResult(null);
        return;
      }
      final decoded = jsonDecode(raw);
      onResult(decoded is Map<String, dynamic> ? decoded : null);
    });
  }

  void clearAll({void Function()? onDone}) {
    _storage.delete(key: _tokenKey).then((_) {
      _storage.delete(key: _userKey).then((_) {
        if (onDone != null) onDone();
      });
    });
  }
}