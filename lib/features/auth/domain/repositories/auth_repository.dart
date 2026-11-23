import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void login({
    required String email,
    required String motDePasse,
    required void Function(ControleurModel controleur) onSuccess,
    required void Function(ApiException error) onError,
  }) {
    _remote.login(
      email: email,
      motDePasse: motDePasse,
      onSuccess: (result) {
        _storage.saveToken(
          result.token,
          onDone: () {
            _storage.saveControleur(
              result.controleur.toJson(),
              onDone: () => onSuccess(result.controleur),
            );
          },
        );
      },
      onError: onError,
    );
  }

  void restoreSession({
    required void Function(ControleurModel? controleur) onResult,
  }) {
    _storage.getToken(
      onResult: (token) {
        if (token == null || token.isEmpty) {
          onResult(null);
          return;
        }
        _storage.getControleur(
          onResult: (cached) {
            if (cached == null) {
              onResult(null);
              return;
            }
            onResult(ControleurModel.fromJson(cached));
          },
        );
      },
    );
  }

  void logout({void Function()? onDone}) {
    _storage.clearAll(onDone: onDone);
  }
}