import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/controle/domain/qr_parser.dart';

/// Verdict d'un contrôle à bord, prêt à afficher.
class ResultatControle {
  final TitreScanne titre;
  final bool accepte;

  /// Gros libellé : « ACCÈS AUTORISÉ », « TRANSFERT ACCEPTÉ », « REFUSÉ ».
  final String verdict;

  /// Message du serveur (motif du refus ou précision).
  final String message;

  /// Lignes de détail (libellé → valeur).
  final List<(String, String)> details;

  /// Vérifié localement, sans réseau.
  final bool horsLigne;

  const ResultatControle({
    required this.titre,
    required this.accepte,
    required this.verdict,
    required this.message,
    this.details = const [],
    this.horsLigne = false,
  });

  factory ResultatControle.refus(TitreScanne titre, String message) => ResultatControle(
        titre: titre,
        accepte: false,
        verdict: 'REFUSÉ',
        message: message,
      );

  /// Réponse de `POST /api/billets/controler/{numero}` :
  /// `{ transfert, message, billet: {...} }`.
  factory ResultatControle.depuisBillet(TitreScanne titre, Map<String, dynamic> json) {
    final billet = json['billet'] is Map<String, dynamic>
        ? json['billet'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final transfert = json['transfert'] == true;
    final valide = (billet['statut'] ?? 'VALIDE') == 'VALIDE';
    return ResultatControle(
      titre: titre,
      accepte: valide,
      verdict: !valide
          ? 'REFUSÉ'
          : transfert
              ? 'TRANSFERT ACCEPTÉ'
              : 'BILLET VALABLE',
      message: (json['message'] ?? '').toString(),
      details: [
        ('Billet', titre.code),
        if (billet['ligneNumero'] != null)
          ('Ligne', '${billet['ligneNumero']} ${billet['ligneNom'] ?? ''}'.trim()),
        if (billet['heureDebut'] != null)
          ('Trajet', '${Format.date(billet['dateTrajet']?.toString())} à ${Format.heure(billet['heureDebut']?.toString())}'),
        if (billet['montantPaye'] != null) ('Montant', Format.fcfa(parseNum(billet['montantPaye']))),
        ('Émis le', Format.dateHeure(billet['dateEmission']?.toString())),
      ],
    );
  }

  /// Réponse de `POST /api/titres-transport/controler/{code}` : l'abonnement.
  factory ResultatControle.depuisAbonnement(TitreScanne titre, Map<String, dynamic> json) {
    final valide = json['valideActuellement'] == true;
    return ResultatControle(
      titre: titre,
      accepte: valide,
      verdict: valide ? 'ABONNÉ · ACCÈS AUTORISÉ' : 'REFUSÉ',
      message: valide ? 'Montée enregistrée.' : 'Abonnement non valide actuellement.',
      details: [
        ('Abonnement', titre.code),
        ('Passager', (json['passagerNomComplet'] ?? 'Non renseigné').toString()),
        ('Statut', (json['statut'] ?? '-').toString()),
        ('Expire le', Format.dateHeure(json['dateFin']?.toString())),
      ],
    );
  }
}
