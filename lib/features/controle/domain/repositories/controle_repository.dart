import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/features/controle/data/datasources/controle_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/titre_controle_model.dart';

final controleRemoteDataSourceProvider = Provider<ControleRemoteDataSource>((ref) {
  return ControleRemoteDataSource(ref.watch(dioProvider));
});

final controleRepositoryProvider = Provider<ControleRepository>((ref) {
  return ControleRepository(ref.watch(controleRemoteDataSourceProvider));
});

class ControleRepository {
  final ControleRemoteDataSource _remote;

  const ControleRepository(this._remote);

  Future<TitreControleModel> verifierCodeTitre(String codeTitre) {
    return _remote.controlerTitre(codeTitre);
  }
}