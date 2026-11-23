import 'package:intl/intl.dart';

class TitreControleModel {
  final int id;
  final String codeTitre;
  final String dateDebut;
  final String dateFin;
  final num montantPaye;
  final String statut;
  final bool valideActuellement;
  final int? passagerId;
  final String? passagerNomComplet;
  final String? modePaiement;
  final String? referencePaiement;

  const TitreControleModel({
    required this.id,
    required this.codeTitre,
    required this.dateDebut,
    required this.dateFin,
    required this.montantPaye,
    required this.statut,
    required this.valideActuellement,
    this.passagerId,
    this.passagerNomComplet,
    this.modePaiement,
    this.referencePaiement,
  });

  String get dateFinFormatee {
    if (dateFin.isEmpty) return '-';
    final parsed = DateTime.tryParse(dateFin);
    if (parsed == null) return dateFin;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  factory TitreControleModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId =
    rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawPassagerId = json['passagerId'] ?? json['passager_id'];
    final parsedPassagerId = rawPassagerId is int
        ? rawPassagerId
        : int.tryParse(rawPassagerId?.toString() ?? '');

    final rawMontant = json['montantPaye'] ?? json['montant_paye'] ?? 0;
    final num montant =
    rawMontant is num ? rawMontant : num.tryParse(rawMontant.toString()) ?? 0;

    final rawValide = json['valideActuellement'] ?? json['valide_actuellement'];
    final bool valide = rawValide is bool
        ? rawValide
        : rawValide?.toString().toLowerCase() == 'true';

    return TitreControleModel(
      id: parsedId,
      codeTitre: (json['codeTitre'] ?? json['code_titre'] ?? '') as String,
      dateDebut: (json['dateDebut'] ?? json['date_debut'] ?? '') as String,
      dateFin: (json['dateFin'] ?? json['date_fin'] ?? '') as String,
      montantPaye: montant,
      statut: (json['statut'] ?? 'INCONNU').toString(),
      valideActuellement: valide,
      passagerId: parsedPassagerId,
      passagerNomComplet:
      (json['passagerNomComplet'] ?? json['passager_nom_complet']) as String?,
      modePaiement:
      (json['modePaiement'] ?? json['mode_paiement']) as String?,
      referencePaiement:
      (json['referencePaiement'] ?? json['reference_paiement']) as String?,
    );
  }
}