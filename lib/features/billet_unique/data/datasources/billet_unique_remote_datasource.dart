import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';

class BilletUniqueRemoteDataSource {
  final Dio _dio;

  const BilletUniqueRemoteDataSource(this._dio);

  /// Vente à bord, en espèces, au tarif de la ligne. [passagerId] (facultatif)
  /// rattache le billet au compte d'un passager.
  Future<BilletUniqueModel> acheterBillet({
    required int affectationId,
    int? passagerId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.acheterBilletEndpoint,
        data: {
          'affectationId': affectationId,
          if (passagerId != null && passagerId > 0) 'passagerId': passagerId,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Réponse de vente invalide.');
      }
      return BilletUniqueModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: "Impossible d'émettre le billet.");
    }
  }
}
