import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';
import 'package:malitrans_controleur_app/features/auth/domain/repositories/auth_repository.dart';

/// Contrôleur connecté (`null` = déconnecté). Restauré depuis le stockage au démarrage.
final sessionProvider =
    AsyncNotifierProvider<SessionController, ControleurModel?>(SessionController.new);

/// Message à afficher sur l'écran de connexion (ex. session expirée).
final messageConnexionProvider =
    NotifierProvider<MessageConnexion, String?>(MessageConnexion.new);

class MessageConnexion extends Notifier<String?> {
  @override
  String? build() => null;

  void afficher(String? message) => state = message;
}

class SessionController extends AsyncNotifier<ControleurModel?> {
  @override
  Future<ControleurModel?> build() => ref.read(authRepositoryProvider).restoreSession();

  /// Lève une [ApiException] si la connexion échoue : l'écran l'affiche.
  Future<void> login(String email, String motDePasse) async {
    final controleur = await ref
        .read(authRepositoryProvider)
        .login(email: email, motDePasse: motDePasse);
    ref.read(messageConnexionProvider.notifier).afficher(null);
    state = AsyncData(controleur);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Appelé par le client HTTP sur un 403 : token expiré ou compte suspendu.
  Future<void> expirer() async {
    if (state.value == null) return;
    ref
        .read(messageConnexionProvider.notifier)
        .afficher('Session expirée ou compte suspendu. Reconnectez-vous.');
    await logout();
  }
}
