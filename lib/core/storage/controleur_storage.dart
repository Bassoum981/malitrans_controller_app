import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final controleurStorageProvider = Provider<ControleurStorage>((ref) {
  return ControleurStorage(const FlutterSecureStorage());
});

/// Stockage local sécurisé : token JWT, profil du contrôleur, trajet choisi.
class ControleurStorage {
  final FlutterSecureStorage _storage;

  ControleurStorage(this._storage);

  static const _tokenKey = 'malitrans_controleur_jwt';
  static const _userKey = 'malitrans_controleur_user';
  static const _trajetKey = 'malitrans_controleur_trajet';

  /// Cache mémoire : le token est lu à chaque requête HTTP.
  String? _tokenCache;
  bool _tokenCharge = false;

  Future<void> saveToken(String token) async {
    _tokenCache = token;
    _tokenCharge = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (!_tokenCharge) {
      _tokenCache = await _storage.read(key: _tokenKey);
      _tokenCharge = true;
    }
    return _tokenCache;
  }

  Future<void> saveControleur(Map<String, dynamic> json) =>
      _storage.write(key: _userKey, value: jsonEncode(json));

  Future<Map<String, dynamic>?> getControleur() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// Trajet (affectation) choisi par le receveur, mémorisé avec sa date
  /// pour ne pas le reproposer le lendemain.
  Future<void> saveTrajetCourant({required int id, required String date}) =>
      _storage.write(key: _trajetKey, value: jsonEncode({'id': id, 'date': date}));

  Future<({int id, String date})?> getTrajetCourant() async {
    final raw = await _storage.read(key: _trajetKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['id'] is! int) return null;
    return (id: decoded['id'] as int, date: decoded['date']?.toString() ?? '');
  }

  Future<void> clearTrajetCourant() => _storage.delete(key: _trajetKey);

  Future<void> clearAll() async {
    _tokenCache = null;
    _tokenCharge = true;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _trajetKey);
  }
}
