import 'package:intl/intl.dart';

class BilletUniqueModel {
  final int id;
  final String numeroBillet;
  final String dateEmission;
  final String statut;
  final num montantPaye;
  final String modePaiement;
  final String? referencePaiement;
  final int? passagerId;
  final String? passagerNomComplet;
  final int? affectationId;
  final String? ligneNumero;
  final String? ligneNom;
  final String? dateTrajet;
  final String? heureDebut;
  final String? busImmatriculation;
  final String? siegeNumero;

  const BilletUniqueModel({
    required this.id,
    required this.numeroBillet,
    required this.dateEmission,
    required this.statut,
    required this.montantPaye,
    required this.modePaiement,
    this.referencePaiement,
    this.passagerId,
    this.passagerNomComplet,
    this.affectationId,
    this.ligneNumero,
    this.ligneNom,
    this.dateTrajet,
    this.heureDebut,
    this.busImmatriculation,
    this.siegeNumero,
  });

  String get valeurQr => numeroBillet;

  String get montantFormate {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return '${fmt.format(montantPaye.round()).replaceAll(',', ' ')} FCFA';
  }

  String get dateEmissionFormatee {
    if (dateEmission.isEmpty) return '-';
    final parsed = DateTime.tryParse(dateEmission);
    if (parsed == null) return dateEmission;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  factory BilletUniqueModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId =
    rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawMontant = json['montantPaye'] ?? json['montant'] ?? 0;
    final num montant =
    rawMontant is num ? rawMontant : num.tryParse(rawMontant.toString()) ?? 0;

    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return BilletUniqueModel(
      id: parsedId,
      numeroBillet: (json['numeroBillet'] ??
          json['codeBillet'] ??
          'BILLET-${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      dateEmission: (json['dateEmission'] ?? DateTime.now().toIso8601String())
          .toString(),
      statut: (json['statut'] ?? 'EMIS').toString(),
      montantPaye: montant,
      modePaiement: (json['modePaiement'] ?? 'ESPECES').toString(),
      referencePaiement: json['referencePaiement']?.toString(),
      passagerId: parseNullableInt(json['passagerId']),
      passagerNomComplet: json['passagerNomComplet']?.toString(),
      affectationId: parseNullableInt(json['affectationId']),
      ligneNumero: json['ligneNumero']?.toString(),
      ligneNom: json['ligneNom']?.toString(),
      dateTrajet: json['dateTrajet']?.toString(),
      heureDebut: json['heureDebut']?.toString(),
      busImmatriculation: json['busImmatriculation']?.toString(),
      siegeNumero: json['siegeNumero']?.toString(),
    );
  }
}