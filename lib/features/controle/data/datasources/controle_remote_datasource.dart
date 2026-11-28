import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';

class ControleRemoteDataSource {
  final Dio _dio;

  const ControleRemoteDataSource(this._dio);

  /// Contrôle non consommant d'un billet sur le trajet du receveur.
  Future<Map<String, dynamic>> controlerBillet(String numeroBillet, int affectationId) =>
      _post(ApiConstants.controlerBilletEndpoint(numeroBillet), affectationId);

  /// Contrôle d'un abonnement : enregistre la montée (anti-partage par trajet).
  Future<Map<String, dynamic>> controlerAbonnement(String codeTitre, int affectationId) =>
      _post(ApiConstants.controlerTitreEndpoint(codeTitre), affectationId);

  Future<Map<String, dynamic>> _post(String path, int affectationId) async {
    try {
      final response = await _dio.post(
        path,
        queryParameters: {'affectationId': affectationId},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Réponse de contrôle invalide.');
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: 'Titre invalide ou introuvable.');
    }
  }
}
