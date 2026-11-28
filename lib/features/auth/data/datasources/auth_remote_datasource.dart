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

  Future<AuthLoginResult> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'email': email.trim(), 'motDePasse': motDePasse},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Réponse de connexion invalide.');
      }
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty) {
        throw const ApiException(message: 'Token absent de la réponse.');
      }
      return AuthLoginResult(token: token, controleur: ControleurModel.fromJson(data));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const ApiException(message: 'Email ou mot de passe incorrect.', statusCode: 401);
      }
      if (status == 403) {
        throw const ApiException(message: 'Compte suspendu ou inactif.', statusCode: 403);
      }
      throw ApiException.from(e, parDefaut: 'Connexion impossible.');
    }
  }
}
