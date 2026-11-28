import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/core/storage/controleur_storage.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/hors_ligne_store.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/data/datasources/trajet_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

final trajetRemoteDataSourceProvider = Provider<TrajetRemoteDataSource>((ref) {
  return TrajetRemoteDataSource(ref.watch(dioProvider));
});

/// Trajets du jour non terminés, proposés au choix du receveur.
/// Sans réseau : trajets des données embarquées.
final trajetsDuJourProvider = FutureProvider.autoDispose<List<TrajetModel>>((ref) async {
  try {
    return await ref.watch(trajetRemoteDataSourceProvider).trajetsDuJour(date: Format.aujourdhui());
  } on ApiException catch (e) {
    if (!e.injoignable) rethrow;
    final embarques = await ref.read(horsLigneProvider.notifier).trajetsEmbarques();
    if (embarques.isEmpty) rethrow;
    return embarques.where((t) => !t.estTermine).toList();
  }
});

/// Trajet du bus sur lequel se trouve le receveur : toutes les ventes et tous
/// les contrôles s'y rattachent. Mémorisé pour la journée.
final trajetCourantProvider =
    AsyncNotifierProvider<TrajetCourantController, TrajetModel?>(
  TrajetCourantController.new,
);

class TrajetCourantController extends AsyncNotifier<TrajetModel?> {
  TrajetRemoteDataSource get _remote => ref.read(trajetRemoteDataSourceProvider);
  ControleurStorage get _storage => ref.read(controleurStorageProvider);
  HorsLigneStore get _store => ref.read(horsLigneStoreProvider);

  @override
  Future<TrajetModel?> build() async {
    final controleur = await ref.watch(sessionProvider.future);
    if (controleur == null) return null;
    final memorise = await _storage.getTrajetCourant();
    if (memorise == null || memorise.date != Format.aujourdhui()) return null;
    return _recharger(memorise.id);
  }

  Future<TrajetModel?> _recharger(int id) async {
    try {
      // aVenir=false : le trajet reste visible même terminé ou interrompu.
      final trajets = await _remote.trajetsDuJour(date: Format.aujourdhui(), aVenir: false);
      for (final t in trajets) {
        if (t.id == id) {
          await _store.modifier((d) => d.trajetCourant = t.toJson());
          return t;
        }
      }
      return null;
    } on ApiException catch (e) {
      if (!e.injoignable) rethrow;
      // Sans réseau : dernière version connue du trajet.
      final cache = (await _store.lire()).trajetCourant;
      if (cache != null && cache['id'] == id) return TrajetModel.fromJson(cache);
      for (final t in await ref.read(horsLigneProvider.notifier).trajetsEmbarques()) {
        if (t.id == id) return t;
      }
      rethrow;
    }
  }

  Future<void> choisir(TrajetModel trajet) async {
    await _storage.saveTrajetCourant(id: trajet.id, date: trajet.date);
    await _store.modifier((d) => d.trajetCourant = trajet.toJson());
    state = AsyncData(trajet);
  }

  Future<void> oublier() async {
    await _storage.clearTrajetCourant();
    await _store.modifier((d) => d.trajetCourant = null);
    state = const AsyncData(null);
  }

  /// Met à jour les compteurs (billets vendus, montées, statut).
  Future<void> rafraichir() async {
    final courant = state.value;
    if (courant == null) return;
    final frais = await _recharger(courant.id);
    if (frais != null) state = AsyncData(frais);
  }

  Future<void> signalerPanne(String description) async {
    final courant = state.value;
    if (courant == null) return;
    await _remote.interrompre(courant.id, description);
    await rafraichir();
  }
}
