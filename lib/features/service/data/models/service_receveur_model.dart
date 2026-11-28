import 'package:malitrans_controleur_app/core/utils/format.dart';

/// Service (journée de travail) d'un receveur : `OUVERT → CLOTURE → VERSE`.
class ServiceReceveurModel {
  final int id;
  final String statut;
  final String? ouvertLe;
  final String? clotureLe;
  final int nombreVentes;

  /// Espèces que le receveur doit détenir (billets annulés exclus).
  final num montantEncaisse;

  const ServiceReceveurModel({
    required this.id,
    required this.statut,
    required this.nombreVentes,
    required this.montantEncaisse,
    this.ouvertLe,
    this.clotureLe,
  });

  bool get estOuvert => statut == 'OUVERT';

  Map<String, dynamic> toJson() => {
        'id': id,
        'statut': statut,
        'ouvertLe': ouvertLe,
        'clotureLe': clotureLe,
        'nombreVentes': nombreVentes,
        'montantEncaisse': montantEncaisse,
      };

  factory ServiceReceveurModel.fromJson(Map<String, dynamic> json) {
    return ServiceReceveurModel(
      id: parseInt(json['id']) ?? 0,
      statut: (json['statut'] ?? '').toString(),
      ouvertLe: parseString(json['ouvertLe']),
      clotureLe: parseString(json['clotureLe']),
      nombreVentes: parseInt(json['nombreVentes']) ?? 0,
      montantEncaisse: parseNum(json['montantEncaisse']),
    );
  }
}
