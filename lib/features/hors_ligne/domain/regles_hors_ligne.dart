import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/models/donnees_embarquees.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/qr_mt1.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/signature_ed25519.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

/// Décision prise à bord sans réseau (docs/API.md §7.3).
class DecisionHorsLigne {
  final bool accepte;

  /// La montée doit être envoyée au serveur (`/api/sync/validations`).
  final bool aSynchroniser;
  final String verdict;
  final String message;
  final QrMt1? qr;

  /// Clé locale anti-double (abonnement par trajet, transfert par billet).
  final String? cleUnicite;
  final List<(String, String)> details;

  const DecisionHorsLigne._({
    required this.accepte,
    required this.aSynchroniser,
    required this.verdict,
    required this.message,
    this.qr,
    this.cleUnicite,
    this.details = const [],
  });

  factory DecisionHorsLigne.refus(String message, {QrMt1? qr}) => DecisionHorsLigne._(
        accepte: false,
        aSynchroniser: false,
        verdict: 'REFUSÉ',
        message: message,
        qr: qr,
        details: qr == null ? const [] : [(qr.estBillet ? 'Billet' : 'Abonnement', qr.reference)],
      );
}

DateTime _depuisEpoch(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);

/// Contrôle hors ligne d'un QR scanné sur le trajet [trajet].
/// [dejaAcceptes] : clés des montées déjà acceptées par cet appareil.
Future<DecisionHorsLigne> controlerHorsLigne({
  required String brut,
  required DonneesEmbarquees donnees,
  required TrajetModel trajet,
  required DateTime maintenant,
  required Set<String> dejaAcceptes,
}) async {
  final qr = QrMt1.decoder(brut);
  if (qr == null) {
    return DecisionHorsLigne.refus(
      'Hors ligne, seul un QR code MaliTrans peut être vérifié : scannez le QR plutôt que de saisir le code.',
    );
  }

  final cle = donnees.cleDe(qr.signataire);
  if (cle == null || cle.isEmpty) {
    return DecisionHorsLigne.refus('Émetteur inconnu ou appareil révoqué (${qr.signataire}).', qr: qr);
  }
  if (!await SignatureEd25519.verifier(qr.contenu, qr.signature, cle)) {
    return DecisionHorsLigne.refus('QR code falsifié : signature invalide.', qr: qr);
  }

  return qr.estBillet
      ? _billet(qr, donnees, trajet, maintenant, dejaAcceptes)
      : _abonnement(qr, donnees, trajet, maintenant, dejaAcceptes);
}

DecisionHorsLigne _abonnement(
  QrMt1 qr,
  DonneesEmbarquees donnees,
  TrajetModel trajet,
  DateTime maintenant,
  Set<String> dejaAcceptes,
) {
  final s = maintenant.millisecondsSinceEpoch ~/ 1000;
  final fin = _depuisEpoch(qr.finEpoch);
  if (donnees.abonnementsSuspendus.contains(qr.reference)) {
    return DecisionHorsLigne.refus('Abonnement suspendu.', qr: qr);
  }
  if (s < qr.debutEpoch) {
    return DecisionHorsLigne.refus(
      "Abonnement pas encore commencé (début le ${Format.dateHeure(_depuisEpoch(qr.debutEpoch).toIso8601String())}).",
      qr: qr,
    );
  }
  if (s > qr.finEpoch) {
    return DecisionHorsLigne.refus('Abonnement expiré le ${Format.dateHeure(fin.toIso8601String())}.', qr: qr);
  }
  if (s > qr.expireEpoch) {
    return DecisionHorsLigne.refus(
      'QR code périmé : le passager doit ouvrir son app avec du réseau pour le rafraîchir.',
      qr: qr,
    );
  }
  final cle = 'A:${qr.reference}:${trajet.id}';
  if (dejaAcceptes.contains(cle)) {
    return DecisionHorsLigne.refus('Cet abonnement a déjà été présenté sur ce trajet.', qr: qr);
  }
  return DecisionHorsLigne._(
    accepte: true,
    aSynchroniser: true,
    verdict: 'ABONNÉ · ACCÈS AUTORISÉ',
    message: 'Montée enregistrée hors ligne.',
    qr: qr,
    cleUnicite: cle,
    details: [
      ('Abonnement', qr.reference),
      ('Passager', 'N° ${qr.passagerId}'),
      ('Expire le', Format.dateHeure(fin.toIso8601String())),
    ],
  );
}

DecisionHorsLigne _billet(
  QrMt1 qr,
  DonneesEmbarquees donnees,
  TrajetModel trajet,
  DateTime maintenant,
  Set<String> dejaAcceptes,
) {
  final emission = _depuisEpoch(qr.emissionEpoch);
  final details = [
    ('Billet', qr.reference),
    ('Montant', Format.fcfa(qr.montant)),
    ('Émis le', Format.dateHeure(emission.toIso8601String())),
  ];

  // Billet du trajet courant : simple vérification, rien à synchroniser.
  if (qr.affectationId == trajet.id) {
    return DecisionHorsLigne._(
      accepte: true,
      aSynchroniser: false,
      verdict: 'BILLET VALABLE',
      message: 'Billet valable sur ce trajet (vérifié hors ligne).',
      qr: qr,
      details: details,
    );
  }

  // Sinon : transfert après panne (§7.3).
  final origine = donnees.trajet(qr.affectationId);
  if (origine == null) {
    return DecisionHorsLigne.refus("Billet d'un autre jour ou d'un trajet inconnu.", qr: qr);
  }
  if (origine.ligneId != trajet.ligneId || qr.ligneId != trajet.ligneId) {
    return DecisionHorsLigne.refus('Billet de la ligne ${origine.ligneNumero} : non valable sur cette ligne.', qr: qr);
  }
  if (origine.date != trajet.date) {
    return DecisionHorsLigne.refus("Billet d'un autre jour.", qr: qr);
  }
  final debutOrigine = origine.debut;
  final debutCourant = trajet.debut;
  if (debutOrigine == null || debutCourant == null || !debutOrigine.isBefore(debutCourant)) {
    return DecisionHorsLigne.refus(
      'Billet du trajet de ${Format.heure(origine.heureDebut)} : seul un billet d’un trajet antérieur peut être transféré.',
      qr: qr,
    );
  }
  final minutes = maintenant.difference(emission).inMinutes;
  if (minutes > donnees.delaiTransfertMinutes) {
    return DecisionHorsLigne.refus(
      'Billet émis il y a $minutes min : transfert possible pendant ${donnees.delaiTransfertMinutes} min seulement.',
      qr: qr,
    );
  }
  final cle = 'T:${qr.reference}';
  if (dejaAcceptes.contains(cle)) {
    return DecisionHorsLigne.refus('Ce billet a déjà été accepté en transfert.', qr: qr);
  }
  return DecisionHorsLigne._(
    accepte: true,
    aSynchroniser: true,
    verdict: 'TRANSFERT ACCEPTÉ',
    message: 'Billet du trajet de ${Format.heure(origine.heureDebut)} accepté après panne (hors ligne).',
    qr: qr,
    cleUnicite: cle,
    details: details,
  );
}

/// Motif pour lequel une vente est impossible sur ce trajet, ou `null` (§7.2).
String? motifVenteImpossible(TrajetModel trajet, {required int toleranceMinutes, required DateTime maintenant}) {
  if (trajet.statut == 'INTERROMPU') return 'Ce trajet a été interrompu : vente impossible.';
  if (trajet.statut == 'TERMINE') return 'Ce trajet est terminé : vente impossible.';
  final debut = trajet.debut;
  final fin = trajet.fin;
  if (debut == null || fin == null) return null;
  if (maintenant.isBefore(debut.subtract(Duration(minutes: toleranceMinutes)))) {
    return "Ce trajet n'a pas encore commencé (départ à ${Format.heure(trajet.heureDebut)}).";
  }
  if (maintenant.isAfter(fin)) {
    return 'Ce trajet est terminé depuis ${Format.heure(trajet.heureFin)} : vente impossible.';
  }
  return null;
}
