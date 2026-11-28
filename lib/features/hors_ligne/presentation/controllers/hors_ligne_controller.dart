import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/dio_client.dart';
import 'package:malitrans_controleur_app/core/network/reseau.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';
import 'package:malitrans_controleur_app/features/billet_unique/domain/repositories/billet_unique_repository.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/resultat_controle_model.dart';
import 'package:malitrans_controleur_app/features/controle/domain/qr_parser.dart';
import 'package:malitrans_controleur_app/features/controle/domain/repositories/controle_repository.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/appareil_store.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/hors_ligne_store.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/models/donnees_embarquees.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/sync_remote_datasource.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/qr_mt1.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/regles_hors_ligne.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/signature_ed25519.dart';
import 'package:malitrans_controleur_app/features/service/presentation/controllers/service_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';

final syncRemoteDataSourceProvider = Provider<SyncRemoteDataSource>((ref) {
  return SyncRemoteDataSource(ref.watch(dioProvider));
});

final horsLigneProvider =
    AsyncNotifierProvider<HorsLigneController, EtatHorsLigne>(HorsLigneController.new);

/// État du mode hors ligne, affiché dans l'app.
class EtatHorsLigne {
  final String clePublique;
  final String? codeAppareil;
  final DonneesEmbarquees? donnees;
  final int ventesEnAttente;
  final int validationsEnAttente;
  final num montantEnAttente;
  final List<Rejet> rejets;
  final bool synchronisation;
  final String? derniereSync;
  final String? erreurSync;

  /// Des éléments en attente appartiennent à un autre receveur.
  final bool autreProprietaire;

  const EtatHorsLigne({
    required this.clePublique,
    this.codeAppareil,
    this.donnees,
    this.ventesEnAttente = 0,
    this.validationsEnAttente = 0,
    this.montantEnAttente = 0,
    this.rejets = const [],
    this.synchronisation = false,
    this.derniereSync,
    this.erreurSync,
    this.autreProprietaire = false,
  });

  bool get enrole => codeAppareil != null;

  int get enAttente => ventesEnAttente + validationsEnAttente;

  /// Prêt à vendre et contrôler sans réseau.
  bool get pret => enrole && donnees != null && donnees!.estDuJour;
}

class HorsLigneController extends AsyncNotifier<EtatHorsLigne> {
  static const _intervalle = Duration(seconds: 20);
  static final _horodatage = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  AppareilStore get _appareil => ref.read(appareilStoreProvider);
  HorsLigneStore get _store => ref.read(horsLigneStoreProvider);
  SyncRemoteDataSource get _remote => ref.read(syncRemoteDataSourceProvider);
  bool _syncEnCours = false;

  @override
  Future<EtatHorsLigne> build() async {
    final minuterie = Timer.periodic(_intervalle, (_) => _tic());
    ref.onDispose(minuterie.cancel);
    final etat = await _etat();
    // Debug uniquement : facilite l'enrôlement depuis Swagger / curl.
    if (kDebugMode) debugPrint('MALITRANS_CLE_PUBLIQUE_POS=${etat.clePublique}');
    return etat;
  }

  Future<EtatHorsLigne> _etat({bool? synchronisation, String? erreurSync}) async {
    final d = await _store.lire();
    final cle = await SignatureEd25519.clePubliqueX509(await _appareil.graine());
    final utilisateur = ref.read(sessionProvider).value;
    return EtatHorsLigne(
      clePublique: cle,
      codeAppareil: await _appareil.code(),
      donnees: d.donneesEmbarquees == null ? null : DonneesEmbarquees.fromJson(d.donneesEmbarquees!),
      ventesEnAttente: d.ventes.length,
      validationsEnAttente: d.validations.length,
      montantEnAttente: d.ventes.fold<num>(0, (s, v) => s + v.montant),
      rejets: List.unmodifiable(d.rejets),
      synchronisation: synchronisation ?? _syncEnCours,
      derniereSync: d.derniereSync,
      erreurSync: erreurSync ?? state.value?.erreurSync,
      autreProprietaire:
          d.enAttente > 0 && d.proprietaireId != null && utilisateur != null && d.proprietaireId != utilisateur.id,
    );
  }

  Future<void> _publier({bool? synchronisation, String? erreurSync}) async {
    state = AsyncData(await _etat(synchronisation: synchronisation, erreurSync: erreurSync));
  }

  bool get _enLigne => ref.read(reseauProvider);

  // ---------------------------------------------------------------------------
  // Enrôlement et données embarquées
  // ---------------------------------------------------------------------------

  /// Vérifie que l'admin a bien enregistré cet appareil sous [code] avec sa
  /// clé publique, puis charge les données du jour.
  Future<void> enroler(String code) async {
    final codeNormalise = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{2,8}$').hasMatch(codeNormalise)) {
      throw const ApiException(message: 'Code : 2 à 8 lettres majuscules ou chiffres (ex. P01).');
    }
    final DonneesEmbarquees donnees;
    try {
      donnees = DonneesEmbarquees.fromJson(await _remote.donneesEmbarquees(codeNormalise));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw ApiException(
          message: "L'appareil $codeNormalise n'est pas encore enregistré. "
              "Transmettez la clé publique à l'administrateur.",
        );
      }
      rethrow;
    }
    final cle = await SignatureEd25519.clePubliqueX509(await _appareil.graine());
    if (donnees.clesAppareils[codeNormalise]?.trim() != cle) {
      throw ApiException(
        message: 'Le code $codeNormalise est enregistré avec une autre clé publique : '
            "vérifiez le code ou faites corriger l'enregistrement.",
      );
    }
    await _appareil.definirCode(codeNormalise);
    await _store.modifier((d) => d.donneesEmbarquees = donnees.toJson());
    await _publier();
  }

  /// Recharge les données du jour (au début du service et quand le réseau le permet).
  Future<void> chargerDonnees() async {
    final code = await _appareil.code();
    if (code == null) return;
    final json = await _remote.donneesEmbarquees(code);
    await _store.modifier((d) => d.donneesEmbarquees = json);
    await _publier();
  }

  Future<DonneesEmbarquees?> _donnees() async {
    final d = await _store.lire();
    return d.donneesEmbarquees == null ? null : DonneesEmbarquees.fromJson(d.donneesEmbarquees!);
  }

  /// Trajets du jour embarqués (repli quand le serveur est injoignable).
  Future<List<TrajetModel>> trajetsEmbarques() async {
    final donnees = await _donnees();
    if (donnees == null || !donnees.estDuJour) return const [];
    return donnees.trajets;
  }

  // ---------------------------------------------------------------------------
  // Vente : en ligne d'abord, hors ligne si le serveur est injoignable (§7.2)
  // ---------------------------------------------------------------------------

  Future<BilletUniqueModel> vendre(TrajetModel trajet, {int? passagerId}) async {
    if (_enLigne) {
      try {
        return await ref.read(billetUniqueRepositoryProvider).vendre(affectationId: trajet.id, passagerId: passagerId);
      } on ApiException catch (e) {
        if (!e.injoignable) rethrow;
      }
    }
    return _vendreHorsLigne(trajet, passagerId);
  }

  Future<BilletUniqueModel> _vendreHorsLigne(TrajetModel trajet, int? passagerId) async {
    final code = await _appareil.code();
    final donnees = await _donnees();
    if (code == null) {
      throw const ApiException(
        message: 'Pas de réseau, et ce téléphone n’est pas configuré pour vendre hors ligne (Service › Mode hors ligne).',
      );
    }
    if (donnees == null || !donnees.estDuJour) {
      throw const ApiException(
        message: 'Pas de réseau, et les données du jour ne sont pas chargées : vente hors ligne impossible.',
      );
    }
    await _verifierProprietaire();

    final maintenant = DateTime.now();
    final reference = donnees.trajet(trajet.id) ?? trajet;
    final motif = motifVenteImpossible(
      reference,
      toleranceMinutes: donnees.toleranceAvantDepartMinutes,
      maintenant: maintenant,
    );
    if (motif != null) throw ApiException(message: motif);

    final compteur = await _appareil.prochainCompteur(minimumServeur: donnees.dernierCompteur);
    final numero = 'MLT-$code-$compteur';
    final montant = reference.tarif.round();
    final contenu = QrMt1.contenuBillet(
      numeroBillet: numero,
      affectationId: trajet.id,
      ligneId: reference.ligneId,
      montant: montant,
      emissionEpoch: maintenant.millisecondsSinceEpoch ~/ 1000,
      codeAppareil: code,
    );
    final qr = '$contenu.${await SignatureEd25519.signer(contenu, await _appareil.graine())}';

    // Persisté avant de remettre le ticket : l'argent est encaissé.
    final utilisateur = ref.read(sessionProvider).value;
    await _store.modifier((d) {
      d.proprietaireId ??= utilisateur?.id;
      d.ventes.add(VenteEnAttente(qr: qr, numeroBillet: numero, montant: montant, passagerId: passagerId));
    });
    await _publier();
    unawaited(synchroniser());

    return BilletUniqueModel(
      id: 0,
      numeroBillet: numero,
      dateEmission: _horodatage.format(maintenant),
      statut: 'VALIDE',
      montantPaye: montant,
      modePaiement: 'ESPECES',
      qrCode: qr,
      passagerId: passagerId,
      affectationId: trajet.id,
      ligneNumero: reference.ligneNumero,
      ligneNom: reference.ligneNom,
      dateTrajet: reference.date,
      heureDebut: reference.heureDebut,
      busImmatriculation: reference.immatriculation,
      horsLigne: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Contrôle : en ligne d'abord, hors ligne si le serveur est injoignable (§7.3)
  // ---------------------------------------------------------------------------

  Future<ResultatControle> controler(String brut, TrajetModel trajet) async {
    if (_enLigne) {
      try {
        return await ref.read(controleRepositoryProvider).controler(brut, trajet.id);
      } on ApiException catch (e) {
        if (!e.injoignable) rethrow;
      }
    }
    return _controlerHorsLigne(brut, trajet);
  }

  Future<ResultatControle> _controlerHorsLigne(String brut, TrajetModel trajet) async {
    final donnees = await _donnees();
    if (donnees == null || !donnees.estDuJour) {
      throw const ApiException(
        message: 'Pas de réseau, et les données du jour ne sont pas chargées : contrôle hors ligne impossible.',
      );
    }
    final locales = await _store.lire();
    final aujourdhui = Format.aujourdhui();
    final decision = await controlerHorsLigne(
      brut: brut,
      donnees: donnees,
      trajet: trajet,
      maintenant: DateTime.now(),
      dejaAcceptes: locales.acceptesDate == aujourdhui ? locales.acceptes : const {},
    );

    if (decision.accepte && decision.aSynchroniser) {
      await _verifierProprietaire();
      final utilisateur = ref.read(sessionProvider).value;
      await _store.modifier((d) {
        if (d.acceptesDate != aujourdhui) {
          d.acceptes = {};
          d.acceptesDate = aujourdhui;
        }
        if (decision.cleUnicite != null) d.acceptes.add(decision.cleUnicite!);
        d.proprietaireId ??= utilisateur?.id;
        d.validations.add(ValidationEnAttente(
          idLocal: _idLocal(),
          affectationId: trajet.id,
          dateValidation: _horodatage.format(DateTime.now()),
          qr: brut.trim(),
        ));
      });
      await _publier();
      unawaited(synchroniser());
    }

    final qr = decision.qr;
    final titre = qr == null
        ? (lireTitre(brut) ?? TitreScanne(TypeTitre.billet, brut.trim()))
        : TitreScanne(qr.estBillet ? TypeTitre.billet : TypeTitre.abonnement, qr.reference);
    return ResultatControle(
      titre: titre,
      accepte: decision.accepte,
      verdict: decision.verdict,
      message: decision.message,
      details: decision.details,
      horsLigne: true,
    );
  }

  static String _idLocal() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _verifierProprietaire() async {
    final d = await _store.lire();
    final utilisateur = ref.read(sessionProvider).value;
    if (d.enAttente > 0 && d.proprietaireId != null && utilisateur != null && d.proprietaireId != utilisateur.id) {
      throw const ApiException(
        message: 'Ce téléphone contient des ventes non synchronisées d’un autre receveur. '
            'Il doit se reconnecter et synchroniser avant que vous puissiez vendre hors ligne.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Synchronisation (§5.9) : ventes d'abord, validations ensuite. Idempotente.
  // ---------------------------------------------------------------------------

  /// Envoie la file d'attente. Ne lève pas d'erreur : l'état porte `erreurSync`.
  Future<void> synchroniser() async {
    if (_syncEnCours) return;
    final code = await _appareil.code();
    final locales = await _store.lire();
    final utilisateur = ref.read(sessionProvider).value;
    if (code == null || locales.enAttente == 0 || utilisateur == null) return;
    if (locales.proprietaireId != null && locales.proprietaireId != utilisateur.id) {
      await _publier();
      return;
    }

    _syncEnCours = true;
    await _publier(synchronisation: true);
    String? erreur;
    try {
      while ((await _store.lire()).ventes.isNotEmpty) {
        final lot = (await _store.lire()).ventes.take(500).toList();
        final resultats = await _remote.ventes(code, lot);
        await _appliquer(lot, resultats, (d) => d.ventes, 'vente', (v) => v.qr, (v) => v.numeroBillet);
      }
      while ((await _store.lire()).validations.isNotEmpty) {
        final lot = (await _store.lire()).validations.take(1000).toList();
        final resultats = await _remote.validations(code, lot);
        await _appliquer(lot, resultats, (d) => d.validations, 'validation', (v) => v.qr, (v) => v.idLocal);
      }
      await _store.modifier((d) {
        d.derniereSync = _horodatage.format(DateTime.now());
        if (d.enAttente == 0) d.proprietaireId = null;
      });
      // Compteurs à jour côté serveur (espèces du service, montées du trajet).
      unawaited(ref.read(serviceEnCoursProvider.notifier).rafraichir().catchError((_) {}));
      unawaited(ref.read(trajetCourantProvider.notifier).rafraichir().catchError((_) {}));
    } on ApiException catch (e) {
      erreur = e.message;
    } catch (e) {
      erreur = ApiException.from(e).message;
    } finally {
      _syncEnCours = false;
      await _publier(synchronisation: false, erreurSync: erreur ?? '');
    }
  }

  /// Retire de la file ce que le serveur a traité ; les rejets sont mis de côté.
  Future<void> _appliquer<T>(
    List<T> lot,
    List<ResultatSync> resultats,
    List<T> Function(DonneesLocales) file,
    String type,
    String Function(T) qrDe,
    String Function(T) referenceDe,
  ) async {
    if (resultats.length != lot.length) {
      throw const ApiException(message: 'Réponse de synchronisation incomplète, nouvel essai plus tard.');
    }
    await _store.modifier((d) {
      final aRetirer = <T>{};
      for (var i = 0; i < lot.length; i++) {
        final r = resultats[i];
        if (r.traite) {
          aRetirer.add(lot[i]);
        } else if (r.rejete) {
          aRetirer.add(lot[i]);
          d.rejets.add(Rejet(
            type: type,
            reference: referenceDe(lot[i]),
            message: r.message,
            date: _horodatage.format(DateTime.now()),
            qr: qrDe(lot[i]),
          ));
        }
      }
      file(d).removeWhere(aRetirer.contains);
    });
  }

  /// Avant la clôture : tout doit être synchronisé (sinon `VENTE_SANS_SERVICE`).
  Future<void> exigerSynchronisation() async {
    await synchroniser();
    final restant = (await _store.lire()).enAttente;
    if (restant > 0) {
      throw ApiException(
        message: '$restant élément(s) hors ligne ne sont pas encore synchronisés. '
            'Retrouvez du réseau puis synchronisez avant de clôturer.',
      );
    }
  }

  /// Toutes les 20 s : synchronise la file, ou sonde le serveur après une coupure.
  Future<void> _tic() async {
    if (ref.read(sessionProvider).value == null) return;
    final locales = await _store.lire();
    if (locales.enAttente > 0) {
      await synchroniser();
    } else if (!_enLigne) {
      try {
        await ref.read(serviceEnCoursProvider.notifier).rafraichir();
        if (_enLigne) await chargerDonnees();
      } catch (_) {}
    }
  }

  Future<void> oublierRejets() async {
    await _store.modifier((d) => d.rejets.clear());
    await _publier();
  }
}
