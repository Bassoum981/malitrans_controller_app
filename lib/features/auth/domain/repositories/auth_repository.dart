import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/core/storage/controleur_storage.dart';
import 'package:malitrans_controleur_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remote: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(controleurStorageProvider),
  );
});

class AuthRepository {
  final AuthRemoteDataSource _remote;
  final ControleurStorage _storage;

  const AuthRepository({
    required AuthRemoteDataSource remote,
    required ControleurStorage storage,
  })  : _remote = remote,
        _storage = storage;

  Future<ControleurModel> login({
    required String email,
    required String motDePasse,
  }) async {
    final result = await _remote.login(email: email, motDePasse: motDePasse);
    if (result.controleur.role != ApiConstants.roleControleur) {
      throw const ApiException(
        message: 'Cette application est réservée aux contrôleurs (receveurs).',
      );
    }
    await _storage.saveToken(result.token);
    await _storage.saveControleur(result.controleur.toJson());
    return result.controleur;
  }

  Future<ControleurModel?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    final cached = await _storage.getControleur();
    if (cached == null) return null;
    final controleur = ControleurModel.fromJson(cached);
    return controleur.role == ApiConstants.roleControleur ? controleur : null;
  }

  Future<void> logout() => _storage.clearAll();
}
