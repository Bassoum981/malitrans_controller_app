import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

class TrajetRemoteDataSource {
  final Dio _dio;

  const TrajetRemoteDataSource(this._dio);

  /// Trajets du jour. `aVenir: true` (défaut API) exclut les trajets terminés.
  Future<List<TrajetModel>> trajetsDuJour({required String date, bool aVenir = true}) async {
    try {
      final response = await _dio.get(
        ApiConstants.trajetsEndpoint,
        queryParameters: {'date': date, 'aVenir': aVenir},
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(TrajetModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: 'Impossible de charger les trajets.');
    }
  }

  /// Panne : le trajet passe `INTERROMPU` (docs/API.md §5.5).
  Future<void> interrompre(int trajetId, String description) async {
    try {
      await _dio.post(
        ApiConstants.interrompreTrajetEndpoint(trajetId),
        data: {'description': description.trim()},
      );
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: "Impossible d'interrompre le trajet.");
    }
  }
}
