import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Joignabilité du serveur, déduite des requêtes réelles (pas du Wi-Fi /
/// réseau mobile : un réseau présent ne garantit pas que l'API répond).
final reseauProvider = NotifierProvider<ReseauController, bool>(ReseauController.new);

/// `true` = le serveur a répondu à la dernière requête.
class ReseauController extends Notifier<bool> {
  @override
  bool build() => true;

  void serveurJoignable() {
    if (!state) state = true;
  }

  void serveurInjoignable() {
    if (state) state = false;
  }
}
