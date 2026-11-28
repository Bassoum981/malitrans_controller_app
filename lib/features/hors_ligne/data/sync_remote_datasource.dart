import 'package:dio/dio.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/hors_ligne_store.dart';

/// Résultat d'un élément synchronisé (`CREE`, `DEJA_SYNCHRONISE`, `IGNORE`, `REJETE`).
class ResultatSync {
  final String reference;
  final String resultat;
  final String message;

  const ResultatSync(this.reference, this.resultat, this.message);

  bool get traite => resultat == 'CREE' || resultat == 'DEJA_SYNCHRONISE' || resultat == 'IGNORE';

  bool get rejete => resultat == 'REJETE';
}

class SyncRemoteDataSource {
  final Dio _dio;

  const SyncRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> donneesEmbarquees(String appareilCode) async {
    try {
      final r = await _dio.get('/sync/donnees-embarquees', queryParameters: {'appareilCode': appareilCode});
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: 'Impossible de charger les données du jour.');
    }
  }

  Future<List<ResultatSync>> ventes(String appareilCode, List<VenteEnAttente> lot) => _post(
        '/sync/ventes',
        {
          'appareilCode': appareilCode,
          'ventes': [for (final v in lot) {'qr': v.qr, 'passagerId': v.passagerId}],
        },
      );

  Future<List<ResultatSync>> validations(String appareilCode, List<ValidationEnAttente> lot) => _post(
        '/sync/validations',
        {
          'appareilCode': appareilCode,
          'validations': [for (final v in lot) v.toJson()],
        },
      );

  /// Les résultats sont renvoyés dans l'ordre du lot.
  Future<List<ResultatSync>> _post(String path, Map<String, dynamic> corps) async {
    try {
      final r = await _dio.post(path, data: corps);
      final resultats = (r.data as Map<String, dynamic>)['resultats'] as List? ?? const [];
      return [
        for (final e in resultats.whereType<Map<String, dynamic>>())
          ResultatSync(
            (e['reference'] ?? '').toString(),
            (e['resultat'] ?? '').toString(),
            (e['message'] ?? '').toString(),
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.from(e, parDefaut: 'Synchronisation impossible.');
    }
  }
}
