import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Signatures Ed25519 des QR MT1 (docs/API.md §6.3).
///
/// Le serveur échange les clés publiques au format X.509 (SubjectPublicKeyInfo)
/// encodé en Base64 : un préfixe fixe de 12 octets suivi des 32 octets de la clé.
class SignatureEd25519 {
  SignatureEd25519._();

  static final _algo = Ed25519();

  static const _prefixeX509 = [0x30, 0x2A, 0x30, 0x05, 0x06, 0x03, 0x2B, 0x65, 0x70, 0x03, 0x21, 0x00];

  /// Nouvelle paire de clés : renvoie la graine privée (32 octets).
  static Future<List<int>> nouvelleGraine() async {
    final paire = await _algo.newKeyPair();
    return paire.extractPrivateKeyBytes();
  }

  static Future<SimpleKeyPair> paireDepuisGraine(List<int> graine) => _algo.newKeyPairFromSeed(graine);

  /// Clé publique au format attendu par `POST /api/admin/appareils`.
  static Future<String> clePubliqueX509(List<int> graine) async {
    final paire = await paireDepuisGraine(graine);
    final brute = (await paire.extractPublicKey()).bytes;
    return base64Encode(Uint8List.fromList([..._prefixeX509, ...brute]));
  }

  /// Signe [contenu] : Base64 URL-safe sans padding.
  static Future<String> signer(String contenu, List<int> graine) async {
    final paire = await paireDepuisGraine(graine);
    final signature = await _algo.sign(utf8.encode(contenu), keyPair: paire);
    return base64Url.encode(signature.bytes).replaceAll('=', '');
  }

  /// Vérifie une signature (Base64 URL-safe, padding facultatif) avec une clé X.509 Base64.
  static Future<bool> verifier(String contenu, String signatureB64, String clePubliqueX509Base64) async {
    try {
      final x509 = base64Decode(clePubliqueX509Base64.trim());
      if (x509.length < 32) return false;
      final cle = SimplePublicKey(x509.sublist(x509.length - 32), type: KeyPairType.ed25519);
      final sig = signatureB64.padRight(signatureB64.length + (4 - signatureB64.length % 4) % 4, '=');
      return await _algo.verify(
        utf8.encode(contenu),
        signature: Signature(base64Url.decode(sig), publicKey: cle),
      );
    } catch (_) {
      return false;
    }
  }
}
