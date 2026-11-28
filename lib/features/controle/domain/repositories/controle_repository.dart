import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/features/controle/data/datasources/controle_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/resultat_controle_model.dart';
import 'package:malitrans_controleur_app/features/controle/domain/qr_parser.dart';

final controleRemoteDataSourceProvider = Provider<ControleRemoteDataSource>((ref) {
  return ControleRemoteDataSource(ref.watch(dioProvider));
});

final controleRepositoryProvider = Provider<ControleRepository>((ref) {
  return ControleRepository(ref.watch(controleRemoteDataSourceProvider));
});

class ControleRepository {
  final ControleRemoteDataSource _remote;

  const ControleRepository(this._remote);

  /// Contrôle un QR scanné ou un code saisi, sur le trajet [affectationId].
  /// Ne lève jamais d'erreur métier : un refus du serveur devient un
  /// [ResultatControle] refusé. Seules les erreurs réseau sont levées.
  Future<ResultatControle> controler(String brut, int affectationId) async {
    final titre = lireTitre(brut);
    if (titre == null) {
      throw const ApiException(
        message: "Ce QR code n'est pas un titre MaliTrans (billet MLT-… ou abonnement PASS-…).",
      );
    }
    try {
      return switch (titre.type) {
        TypeTitre.billet => ResultatControle.depuisBillet(
            titre, await _remote.controlerBillet(titre.code, affectationId)),
        TypeTitre.abonnement => ResultatControle.depuisAbonnement(
            titre, await _remote.controlerAbonnement(titre.code, affectationId)),
      };
    } on ApiException catch (e) {
      // 400 (règle métier) / 404 (inconnu) : le titre est refusé à bord.
      if (e.statusCode == 400 || e.statusCode == 404) {
        return ResultatControle.refus(titre, e.message);
      }
      rethrow;
    }
  }
}
