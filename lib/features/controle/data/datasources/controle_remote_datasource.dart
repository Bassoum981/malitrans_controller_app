import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/titre_controle_model.dart';

class ControleRemoteDataSource {
  final Dio _dio;

  const ControleRemoteDataSource(this._dio);

  Future<TitreControleModel> controlerTitre(String codeTitre) async {
    try {
      final response = await _dio.post(
        ApiConstants.controlerTitreEndpoint(codeTitre),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Réponse de contrôle invalide.');
      }
      return TitreControleModel.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map<String, dynamic>)
          ? (body['message'] ?? body['error'])?.toString()
          : null;
      throw ApiException(
        message: msg ?? 'Titre invalide, expiré ou introuvable.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}