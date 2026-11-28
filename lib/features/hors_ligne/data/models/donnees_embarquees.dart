import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

/// Paquet chargé au début du service pour vendre et contrôler sans réseau
/// (`GET /api/sync/donnees-embarquees`, docs/API.md §5.9).
class DonneesEmbarquees {
  final String genereLe;
  final String date;
  final String appareilCode;
  final int dernierCompteur;
  final String clePubliqueServeur;
  final int toleranceAvantDepartMinutes;
  final int delaiTransfertMinutes;
  final List<TrajetModel> trajets;

  /// code appareil → clé publique X.509 Base64 (appareils actifs uniquement).
  final Map<String, String> clesAppareils;
  final Set<String> abonnementsSuspendus;

  final Map<String, dynamic> _brut;

  DonneesEmbarquees._(this._brut)
      : genereLe = (_brut['genereLe'] ?? '').toString(),
        date = (_brut['date'] ?? '').toString(),
        appareilCode = (_brut['appareilCode'] ?? '').toString(),
        dernierCompteur = parseInt(_brut['dernierCompteur']) ?? 0,
        clePubliqueServeur = (_brut['clePubliqueServeur'] ?? '').toString(),
        toleranceAvantDepartMinutes = parseInt(_brut['toleranceAvantDepartMinutes']) ?? 15,
        delaiTransfertMinutes = parseInt(_brut['delaiTransfertMinutes']) ?? 90,
        trajets = [
          for (final t in (_brut['trajets'] as List? ?? const []))
            if (t is Map<String, dynamic>) TrajetModel.fromJson(t),
        ],
        clesAppareils = {
          for (final a in (_brut['appareils'] as List? ?? const []))
            if (a is Map) (a['code'] ?? '').toString(): (a['clePublique'] ?? '').toString(),
        },
        abonnementsSuspendus = {
          for (final c in (_brut['abonnementsSuspendus'] as List? ?? const [])) c.toString(),
        };

  factory DonneesEmbarquees.fromJson(Map<String, dynamic> json) => DonneesEmbarquees._(json);

  Map<String, dynamic> toJson() => _brut;

  bool get estDuJour => date == Format.aujourdhui();

  TrajetModel? trajet(int id) {
    for (final t in trajets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Clé publique du signataire d'un QR (`SRV` = serveur), `null` si inconnu ou révoqué.
  String? cleDe(String signataire) =>
      signataire == 'SRV' ? clePubliqueServeur : clesAppareils[signataire];
}
