import 'package:malitrans_controleur_app/core/utils/format.dart';

/// Trajet (affectation) vu par les apps : `GET /api/trajets` (docs/API.md §5.5).
class TrajetModel {
  final int id;
  final String date;
  final String heureDebut;
  final String heureFin;

  /// `PLANIFIE`, `EN_COURS`, `TERMINE` ou `INTERROMPU`.
  final String statut;
  final int ligneId;
  final String ligneNumero;
  final String ligneNom;
  final num tarif;
  final String? numeroBus;
  final String? immatriculation;
  final int capaciteTotale;
  final int billetsVendus;
  final int monteesControlees;
  final int placesRestantes;
  final bool surcharge;

  const TrajetModel({
    required this.id,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.statut,
    required this.ligneId,
    required this.ligneNumero,
    required this.ligneNom,
    required this.tarif,
    required this.capaciteTotale,
    required this.billetsVendus,
    required this.monteesControlees,
    required this.placesRestantes,
    required this.surcharge,
    this.numeroBus,
    this.immatriculation,
  });

  bool get estTermine => statut == 'TERMINE' || statut == 'INTERROMPU';

  int get montees => billetsVendus + monteesControlees;

  String get horaire => '${Format.heure(heureDebut)} → ${Format.heure(heureFin)}';

  String get bus => [numeroBus, immatriculation]
      .where((s) => s != null && s.isNotEmpty)
      .join(' · ');

  String get libelleStatut => switch (statut) {
        'PLANIFIE' => 'Planifié',
        'EN_COURS' => 'En cours',
        'TERMINE' => 'Terminé',
        'INTERROMPU' => 'Interrompu',
        _ => statut,
      };

  /// Début / fin du trajet en heure locale (Bamako = UTC, comme le serveur).
  DateTime? get debut => _dateHeure(heureDebut);

  DateTime? get fin => _dateHeure(heureFin);

  DateTime? _dateHeure(String hms) => DateTime.tryParse('${date}T${hms.length == 5 ? '$hms:00' : hms}');

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'heureDebut': heureDebut,
        'heureFin': heureFin,
        'statut': statut,
        'ligneId': ligneId,
        'ligneNumero': ligneNumero,
        'ligneNom': ligneNom,
        'tarif': tarif,
        'numeroBus': numeroBus,
        'immatriculation': immatriculation,
        'capaciteTotale': capaciteTotale,
        'billetsVendus': billetsVendus,
        'monteesControlees': monteesControlees,
        'placesRestantes': placesRestantes,
        'surcharge': surcharge,
      };

  factory TrajetModel.fromJson(Map<String, dynamic> json) {
    return TrajetModel(
      id: parseInt(json['id']) ?? 0,
      date: (json['date'] ?? '').toString(),
      heureDebut: (json['heureDebut'] ?? '').toString(),
      heureFin: (json['heureFin'] ?? '').toString(),
      statut: (json['statut'] ?? '').toString(),
      ligneId: parseInt(json['ligneId']) ?? 0,
      ligneNumero: (json['ligneNumero'] ?? '').toString(),
      ligneNom: (json['ligneNom'] ?? '').toString(),
      tarif: parseNum(json['tarif']),
      numeroBus: parseString(json['numeroBus']),
      immatriculation: parseString(json['immatriculation']),
      capaciteTotale: parseInt(json['capaciteTotale']) ?? 0,
      billetsVendus: parseInt(json['billetsVendus']) ?? 0,
      monteesControlees: parseInt(json['monteesControlees']) ?? 0,
      placesRestantes: parseInt(json['placesRestantes']) ?? 0,
      surcharge: json['surcharge'] == true,
    );
  }
}
