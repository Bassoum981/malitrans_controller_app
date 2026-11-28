class ApiConstants {
  ApiConstants._();

  /// URL de l'API, surchargée au lancement par
  /// `--dart-define=MALITRANS_API_URL=http://10.0.2.2:8080/api`.
  static const String baseUrl = String.fromEnvironment(
    'MALITRANS_API_URL',
    defaultValue: 'https://hunk-candied-lapping.ngrok-free.dev/api',
  );

  static const String roleControleur = 'ROLE_CONTROLEUR';

  // --- Authentification ---
  static const String loginEndpoint = '/auth/connexion';

  // --- Service receveur ---
  static const String serviceEnCoursEndpoint = '/services-receveur/en-cours';
  static const String ouvrirServiceEndpoint = '/services-receveur/ouvrir';
  static String cloturerServiceEndpoint(int serviceId) =>
      '/services-receveur/$serviceId/cloturer';

  // --- Trajets ---
  static const String trajetsEndpoint = '/trajets';
  static String interrompreTrajetEndpoint(int trajetId) =>
      '/trajets/$trajetId/interrompre';

  // --- Billets et abonnements ---
  static const String acheterBilletEndpoint = '/billets/acheter';

  static String controlerBilletEndpoint(String numeroBillet) =>
      '/billets/controler/${Uri.encodeComponent(numeroBillet.trim())}';

  static String controlerTitreEndpoint(String codeTitre) =>
      '/titres-transport/controler/${Uri.encodeComponent(codeTitre.trim())}';
}
