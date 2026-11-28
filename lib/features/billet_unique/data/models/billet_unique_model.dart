import 'package:malitrans_controleur_app/core/utils/format.dart';

/// Billet vendu à bord : réponse de `POST /api/billets/acheter` (docs/API.md §5.6).
class BilletUniqueModel {
  final int id;
  final String numeroBillet;
  final String dateEmission;
  final String statut;
  final num montantPaye;
  final String modePaiement;

  /// QR signé MT1 à imprimer tel quel sur le ticket.
  final String qrCode;
  final String? referencePaiement;
  final int? passagerId;
  final String? passagerNomComplet;
  final int? affectationId;
  final String? ligneNumero;
  final String? ligneNom;
  final String? dateTrajet;
  final String? heureDebut;
  final String? busImmatriculation;

  /// Vendu sans réseau (QR signé par l'appareil, en attente de synchronisation).
  final bool horsLigne;

  const BilletUniqueModel({
    required this.id,
    required this.numeroBillet,
    required this.dateEmission,
    required this.statut,
    required this.montantPaye,
    required this.modePaiement,
    required this.qrCode,
    this.referencePaiement,
    this.passagerId,
    this.passagerNomComplet,
    this.affectationId,
    this.ligneNumero,
    this.ligneNom,
    this.dateTrajet,
    this.heureDebut,
    this.busImmatriculation,
    this.horsLigne = false,
  });

  String get montantFormate => Format.fcfa(montantPaye);

  String get dateEmissionFormatee => Format.dateHeure(dateEmission);

  factory BilletUniqueModel.fromJson(Map<String, dynamic> json) {
    final numero = (json['numeroBillet'] ?? '').toString();
    return BilletUniqueModel(
      id: parseInt(json['id']) ?? 0,
      numeroBillet: numero,
      dateEmission: (json['dateEmission'] ?? '').toString(),
      statut: (json['statut'] ?? '').toString(),
      montantPaye: parseNum(json['montantPaye']),
      modePaiement: (json['modePaiement'] ?? 'ESPECES').toString(),
      // Repli sur le numéro si le serveur n'a pas fourni de QR signé.
      qrCode: (json['qrCode'] ?? numero).toString(),
      referencePaiement: parseString(json['referencePaiement']),
      passagerId: parseInt(json['passagerId']),
      passagerNomComplet: parseString(json['passagerNomComplet']),
      affectationId: parseInt(json['affectationId']),
      ligneNumero: parseString(json['ligneNumero']),
      ligneNom: parseString(json['ligneNom']),
      dateTrajet: parseString(json['dateTrajet']),
      heureDebut: parseString(json['heureDebut']),
      busImmatriculation: parseString(json['busImmatriculation']),
      horsLigne: json['horsLigne'] == true,
    );
  }
}
