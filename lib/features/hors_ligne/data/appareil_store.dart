import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/signature_ed25519.dart';

final appareilStoreProvider = Provider<AppareilStore>((ref) => AppareilStore(const FlutterSecureStorage()));

/// Identité du terminal POS, dans le stockage sécurisé : la clé privée ne
/// quitte jamais l'appareil (docs/API.md §6.3).
/// Ces données survivent à la déconnexion (elles appartiennent à l'appareil).
class AppareilStore {
  final FlutterSecureStorage _storage;

  AppareilStore(this._storage);

  static const _graineKey = 'malitrans_pos_graine';
  static const _codeKey = 'malitrans_pos_code';
  static const _compteurKey = 'malitrans_pos_compteur';

  List<int>? _graine;

  /// Graine Ed25519 de l'appareil, générée une seule fois.
  Future<List<int>> graine() async {
    if (_graine != null) return _graine!;
    final existante = await _storage.read(key: _graineKey);
    if (existante != null && existante.isNotEmpty) {
      return _graine = base64Decode(existante);
    }
    final nouvelle = await SignatureEd25519.nouvelleGraine();
    await _storage.write(key: _graineKey, value: base64Encode(nouvelle));
    return _graine = nouvelle;
  }

  Future<String?> code() => _storage.read(key: _codeKey);

  Future<void> definirCode(String code) => _storage.write(key: _codeKey, value: code);

  Future<int> compteur() async => int.tryParse(await _storage.read(key: _compteurKey) ?? '') ?? 0;

  /// Réserve le prochain numéro de billet hors ligne : strictement croissant
  /// et persisté AVANT l'émission du billet (§7.2).
  Future<int> prochainCompteur({required int minimumServeur}) async {
    final local = await compteur();
    final suivant = (local > minimumServeur ? local : minimumServeur) + 1;
    await _storage.write(key: _compteurKey, value: '$suivant');
    return suivant;
  }
}
