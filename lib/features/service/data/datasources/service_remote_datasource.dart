import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/service/data/models/service_receveur_model.dart';

class ServiceRemoteDataSource {
  final Dio _dio;

  const ServiceRemoteDataSource(this._dio);

  /// Service ouvert du receveur connecté, `null` si aucun (404).
  Future<ServiceReceveurModel?> enCours() async {
    try {
      final response = await _dio.get(ApiConstants.serviceEnCoursEndpoint);
      return ServiceReceveurModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.from(e, parDefaut: 'Impossible de charger votre service.');
    }
  }

  Future<ServiceReceveurModel> ouvrir() => _post(
        ApiConstants.ouvrirServiceEndpoint,
        "Impossible d'ouvrir le service.",
      );

  Future<ServiceReceveurModel> cloturer(int serviceId) => _post(
        ApiConstants.cloturerServiceEndpoint(serviceId),
        'Impossible de clôturer le service.',
      );

  Future<ServiceReceveurModel> _post(String path, String parDefaut) async {
    try {
      final response = await _dio.post(path);
      return ServiceReceveurModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: parDefaut);
    }
  }
}
