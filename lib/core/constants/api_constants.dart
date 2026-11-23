class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'MALITRANS_API_URL',
    defaultValue: 'https://slush-lark-manual.ngrok-free.dev/api',
  );

  static const String loginEndpoint = '/auth/connexion';

  static String controlerTitreEndpoint(String codeTitre) =>
      '/titres-transport/controler/${Uri.encodeComponent(codeTitre.trim())}';

  static const String acheterBilletEndpoint = '/billets/acheter';

  static String controlerBilletEndpoint(String numeroBillet) =>
      '/billets/controler/${Uri.encodeComponent(numeroBillet.trim())}';
}