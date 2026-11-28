import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/hors_ligne_store.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:malitrans_controleur_app/features/service/data/datasources/service_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/service/data/models/service_receveur_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';

final serviceRemoteDataSourceProvider = Provider<ServiceRemoteDataSource>((ref) {
  return ServiceRemoteDataSource(ref.watch(dioProvider));
});

/// Service ouvert du receveur (`null` = aucun service ouvert : il faut l'ouvrir).
final serviceEnCoursProvider =
    AsyncNotifierProvider<ServiceEnCoursController, ServiceReceveurModel?>(
  ServiceEnCoursController.new,
);

/// Dernier service clôturé pendant cette session : rappel du montant à verser.
final dernierServiceClotureProvider =
    NotifierProvider<DernierServiceCloture, ServiceReceveurModel?>(
  DernierServiceCloture.new,
);

class DernierServiceCloture extends Notifier<ServiceReceveurModel?> {
  @override
  ServiceReceveurModel? build() => null;

  void definir(ServiceReceveurModel? service) => state = service;
}

class ServiceEnCoursController extends AsyncNotifier<ServiceReceveurModel?> {
  ServiceRemoteDataSource get _remote => ref.read(serviceRemoteDataSourceProvider);
  HorsLigneStore get _store => ref.read(horsLigneStoreProvider);

  @override
  Future<ServiceReceveurModel?> build() async {
    // Recalculé à chaque connexion / déconnexion.
    final controleur = await ref.watch(sessionProvider.future);
    if (controleur == null) return null;
    return _charger();
  }

  /// Serveur d'abord ; sans réseau, dernier service connu (mis en cache).
  Future<ServiceReceveurModel?> _charger() async {
    try {
      final service = await _remote.enCours();
      await _store.modifier((d) => d.service = service == null ? null : {...service.toJson(), 'jour': Format.aujourdhui()});
      return service;
    } on ApiException catch (e) {
      if (!e.injoignable) rethrow;
      final cache = (await _store.lire()).service;
      if (cache == null) rethrow;
      return ServiceReceveurModel.fromJson(cache);
    }
  }

  /// Recharge les compteurs (ventes, montant encaissé) sans écran de chargement.
  Future<void> rafraichir() async {
    state = AsyncData(await _charger());
  }

  /// Lève une [ApiException] (ex. service précédent pas encore versé).
  Future<void> ouvrir() async {
    final service = await _remote.ouvrir();
    await _store.modifier((d) => d.service = {...service.toJson(), 'jour': Format.aujourdhui()});
    ref.read(dernierServiceClotureProvider.notifier).definir(null);
    state = AsyncData(service);
    // Données du jour pour pouvoir continuer sans réseau.
    ref.read(horsLigneProvider.notifier).chargerDonnees().catchError((_) {});
  }

  Future<void> cloturer() async {
    final courant = state.value;
    if (courant == null) return;
    // Synchroniser AVANT de clôturer (docs/API.md §4.3).
    await ref.read(horsLigneProvider.notifier).exigerSynchronisation();
    final cloture = await _remote.cloturer(courant.id);
    ref.read(dernierServiceClotureProvider.notifier).definir(cloture);
    await _store.modifier((d) => d.service = null);
    await ref.read(trajetCourantProvider.notifier).oublier();
    state = const AsyncData(null);
  }
}
