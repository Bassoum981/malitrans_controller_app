import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';

class BilletUniqueRemoteDataSource {
  final Dio _dio;

  const BilletUniqueRemoteDataSource(this._dio);

  Future<BilletUniqueModel> acheterBillet({
    required int affectationId,
    required String modePaiement,
    int? passagerId,
    int? siegeId,
    String? referencePaiement,
  }) async {
    try {
      final payload = <String, dynamic>{
        'affectationId': affectationId,
        'modePaiement': modePaiement,
        if (passagerId != null && passagerId > 0) 'passagerId': passagerId,
        if (siegeId != null && siegeId > 0) 'siegeId': siegeId,
        if (referencePaiement != null && referencePaiement.trim().isNotEmpty)
          'referencePaiement': referencePaiement.trim(),
      };

      final response = await _dio.post(
        ApiConstants.acheterBilletEndpoint,
        data: payload,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Réponse de vente invalide.');
      }
      return BilletUniqueModel.fromJson(data);
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map<String, dynamic>)
          ? (body['message'] ?? body['error'])?.toString()
          : null;
      throw ApiException(
        message: msg ?? "Impossible d'émettre le billet.",
        statusCode: e.response?.statusCode,
      );
    }
  }
}