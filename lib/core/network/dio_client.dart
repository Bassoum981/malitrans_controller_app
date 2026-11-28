import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/constants/api_constants.dart';
import 'package:malitrans_controleur_app/core/network/reseau.dart';
import 'package:malitrans_controleur_app/core/storage/controleur_storage.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(controleurStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      // Court : dans le bus, mieux vaut basculer vite hors ligne qu'attendre.
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        ref.read(reseauProvider.notifier).serveurJoignable();
        handler.next(response);
      },
      onError: (error, handler) {
        final reseau = ref.read(reseauProvider.notifier);
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          reseau.serveurInjoignable();
        } else if (error.response != null) {
          reseau.serveurJoignable();
        }
        // 403 hors connexion = token expiré/invalide ou compte suspendu
        // (docs/API.md §2.2) : on renvoie vers l'écran de connexion.
        final estConnexion = error.requestOptions.path == ApiConstants.loginEndpoint;
        if (error.response?.statusCode == 403 && !estConnexion) {
          ref.read(sessionProvider.notifier).expirer();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
