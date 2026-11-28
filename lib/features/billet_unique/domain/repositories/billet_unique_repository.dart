import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/datasources/billet_unique_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';

final billetUniqueRemoteDataSourceProvider = Provider<BilletUniqueRemoteDataSource>((ref) {
  return BilletUniqueRemoteDataSource(ref.watch(dioProvider));
});

final billetUniqueRepositoryProvider = Provider<BilletUniqueRepository>((ref) {
  return BilletUniqueRepository(ref.watch(billetUniqueRemoteDataSourceProvider));
});

class BilletUniqueRepository {
  final BilletUniqueRemoteDataSource _remote;

  const BilletUniqueRepository(this._remote);

  Future<BilletUniqueModel> vendre({required int affectationId, int? passagerId}) {
    return _remote.acheterBillet(affectationId: affectationId, passagerId: passagerId);
  }
}
