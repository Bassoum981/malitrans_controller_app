import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// La requête n'a pas pu atteindre le serveur (pas de réseau, connexion
  /// impossible) : elle n'a pas été traitée, on peut basculer hors ligne.
  final bool injoignable;

  const ApiException({
    required this.message,
    this.statusCode,
    this.injoignable = false,
  });

  bool get estIntrouvable => statusCode == 404;

  /// Convertit n'importe quelle erreur en message affichable.
  /// Les messages du backend sont en français et destinés à l'utilisateur
  /// (docs/API.md §2.3) : ils sont affichés tels quels.
  factory ApiException.from(Object error, {String? parDefaut}) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return ApiException(message: parDefaut ?? error.toString());
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Serveur injoignable. Vérifiez la connexion réseau.',
          injoignable: true,
        );
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // La requête a pu être traitée : ne pas la rejouer hors ligne.
        return const ApiException(
          message: 'Le serveur ne répond pas. Vérifiez le résultat avant de recommencer.',
        );
      default:
        break;
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    String? message;
    if (body is Map<String, dynamic>) {
      final erreursChamps = body['validationErrors'];
      if (erreursChamps is Map && erreursChamps.isNotEmpty) {
        message = erreursChamps.values.join('\n');
      } else {
        message = (body['message'] ?? body['error'])?.toString();
      }
    }

    if (status == 403 && (message == null || message.isEmpty)) {
      message = 'Session expirée ou compte suspendu. Reconnectez-vous.';
    }

    return ApiException(
      message: message ?? parDefaut ?? 'Erreur inattendue, réessayez.',
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}
