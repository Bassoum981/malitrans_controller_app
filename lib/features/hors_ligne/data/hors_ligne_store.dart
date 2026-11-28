import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final horsLigneStoreProvider = Provider<HorsLigneStore>((ref) => HorsLigneStore());

/// Vente hors ligne en attente de `POST /api/sync/ventes`.
class VenteEnAttente {
  final String qr;
  final int? passagerId;
  final String numeroBillet;
  final num montant;

  const VenteEnAttente({required this.qr, required this.numeroBillet, required this.montant, this.passagerId});

  Map<String, dynamic> toJson() => {'qr': qr, 'passagerId': passagerId, 'numeroBillet': numeroBillet, 'montant': montant};

  factory VenteEnAttente.fromJson(Map<String, dynamic> j) => VenteEnAttente(
        qr: j['qr'] as String,
        passagerId: j['passagerId'] as int?,
        numeroBillet: (j['numeroBillet'] ?? '') as String,
        montant: (j['montant'] ?? 0) as num,
      );
}

/// Montée acceptée hors ligne en attente de `POST /api/sync/validations`.
class ValidationEnAttente {
  final String idLocal;
  final int affectationId;
  final String dateValidation;
  final String qr;

  const ValidationEnAttente({
    required this.idLocal,
    required this.affectationId,
    required this.dateValidation,
    required this.qr,
  });

  Map<String, dynamic> toJson() =>
      {'idLocal': idLocal, 'affectationId': affectationId, 'dateValidation': dateValidation, 'qr': qr};

  factory ValidationEnAttente.fromJson(Map<String, dynamic> j) => ValidationEnAttente(
        idLocal: j['idLocal'] as String,
        affectationId: j['affectationId'] as int,
        dateValidation: j['dateValidation'] as String,
        qr: j['qr'] as String,
      );
}

/// Élément refusé définitivement par le serveur : conservé pour le support,
/// jamais renvoyé en boucle (docs/API.md §5.9).
class Rejet {
  final String type; // 'vente' | 'validation'
  final String reference;
  final String message;
  final String date;
  final String qr;

  const Rejet({required this.type, required this.reference, required this.message, required this.date, required this.qr});

  Map<String, dynamic> toJson() => {'type': type, 'reference': reference, 'message': message, 'date': date, 'qr': qr};

  factory Rejet.fromJson(Map<String, dynamic> j) => Rejet(
        type: (j['type'] ?? '') as String,
        reference: (j['reference'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        date: (j['date'] ?? '') as String,
        qr: (j['qr'] ?? '') as String,
      );
}

/// Contenu persistant du mode hors ligne.
class DonneesLocales {
  /// Receveur à qui appartiennent les éléments en attente.
  int? proprietaireId;
  List<VenteEnAttente> ventes;
  List<ValidationEnAttente> validations;
  List<Rejet> rejets;

  /// Montées déjà acceptées hors ligne par cet appareil, pour le jour [acceptesDate].
  Set<String> acceptes;
  String acceptesDate;
  Map<String, dynamic>? donneesEmbarquees;
  Map<String, dynamic>? service;
  Map<String, dynamic>? trajetCourant;
  String? derniereSync;

  DonneesLocales({
    this.proprietaireId,
    List<VenteEnAttente>? ventes,
    List<ValidationEnAttente>? validations,
    List<Rejet>? rejets,
    Set<String>? acceptes,
    this.acceptesDate = '',
    this.donneesEmbarquees,
    this.service,
    this.trajetCourant,
    this.derniereSync,
  })  : ventes = ventes ?? [],
        validations = validations ?? [],
        rejets = rejets ?? [],
        acceptes = acceptes ?? {};

  int get enAttente => ventes.length + validations.length;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'proprietaireId': proprietaireId,
        'ventes': [for (final v in ventes) v.toJson()],
        'validations': [for (final v in validations) v.toJson()],
        'rejets': [for (final r in rejets) r.toJson()],
        'acceptes': acceptes.toList(),
        'acceptesDate': acceptesDate,
        'donneesEmbarquees': donneesEmbarquees,
        'service': service,
        'trajetCourant': trajetCourant,
        'derniereSync': derniereSync,
      };

  factory DonneesLocales.fromJson(Map<String, dynamic> j) {
    List<T> liste<T>(String cle, T Function(Map<String, dynamic>) f) => [
          for (final e in (j[cle] as List? ?? const []))
            if (e is Map<String, dynamic>) f(e),
        ];
    Map<String, dynamic>? map(String cle) => j[cle] is Map<String, dynamic> ? j[cle] as Map<String, dynamic> : null;
    return DonneesLocales(
      proprietaireId: j['proprietaireId'] as int?,
      ventes: liste('ventes', VenteEnAttente.fromJson),
      validations: liste('validations', ValidationEnAttente.fromJson),
      rejets: liste('rejets', Rejet.fromJson),
      acceptes: {for (final a in (j['acceptes'] as List? ?? const [])) a.toString()},
      acceptesDate: (j['acceptesDate'] ?? '') as String,
      donneesEmbarquees: map('donneesEmbarquees'),
      service: map('service'),
      trajetCourant: map('trajetCourant'),
      derniereSync: j['derniereSync'] as String?,
    );
  }
}

/// Fichier JSON dans le dossier privé de l'app. Écriture atomique (fichier
/// temporaire puis renommage) : une coupure ne corrompt pas la file.
class HorsLigneStore {
  DonneesLocales? _cache;
  Future<void> _ecriture = Future.value();

  Future<File> _fichier() async {
    final dossier = await getApplicationDocumentsDirectory();
    return File('${dossier.path}/malitrans_hors_ligne.json');
  }

  Future<DonneesLocales> lire() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _fichier();
      if (await f.exists()) {
        final json = jsonDecode(await f.readAsString());
        if (json is Map<String, dynamic>) return _cache = DonneesLocales.fromJson(json);
      }
    } catch (_) {
      // Fichier illisible : on repart d'un état vide plutôt que de bloquer l'app.
    }
    return _cache = DonneesLocales();
  }

  /// Applique [modification] puis écrit le fichier (écritures sérialisées).
  Future<DonneesLocales> modifier(void Function(DonneesLocales d) modification) {
    final resultat = _ecriture.then((_) async {
      final d = await lire();
      modification(d);
      final f = await _fichier();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(d.toJson()), flush: true);
      await tmp.rename(f.path);
      return d;
    });
    _ecriture = resultat.then((_) {}, onError: (_) {});
    return resultat;
  }
}
