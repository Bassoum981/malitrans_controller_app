import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';

class AuthLoginResult {
  final String token;
  final ControleurModel controleur;

  const AuthLoginResult({
    required this.token,
    required this.controleur,
  });
}

class AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSource(this._dio);

  void login({
    required String email,
    required String motDePasse,
    required void Function(AuthLoginResult result) onSuccess,
    required void Function(ApiException error) onError,
  }) {
    _dio
        .post(
      ApiConstants.loginEndpoint,
      data: {
        'email': email.trim(),
        'motDePasse': motDePasse,
      },
    )
        .then((response) {
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        onError(const ApiException(message: 'Réponse de connexion invalide.'));
        return;
      }

      final rawToken = data['token'] ?? data['accessToken'];
      final token = rawToken?.toString() ?? '';
      if (token.isEmpty) {
        onError(const ApiException(message: 'Token absent de la réponse.'));
        return;
      }

      onSuccess(
        AuthLoginResult(
          token: token,
          controleur: ControleurModel.fromJson(data),
        ),
      );
    }).catchError((Object error) {
      if (error is DioException) {
        final body = error.response?.data;
        final msg = (body is Map<String, dynamic>)
            ? (body['message'] ?? body['error'])?.toString()
            : null;
        onError(
          ApiException(
            message: msg ?? 'Identifiants invalides ou serveur inaccessible.',
            statusCode: error.response?.statusCode,
          ),
        );
      } else {
        onError(ApiException(message: error.toString()));
      }
    });
  }
}