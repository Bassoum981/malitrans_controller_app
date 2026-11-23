class ControleurModel {
  final int id;
  final String nomComplet;
  final String email;
  final String role;
  final String statut;

  const ControleurModel({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.role,
    required this.statut,
  });

  factory ControleurModel.fromJson(Map<String, dynamic> json) {
    final source = (json['utilisateur'] is Map<String, dynamic>)
        ? json['utilisateur'] as Map<String, dynamic>
        : json;

    final rawId = source['id'] ?? json['id'];
    final parsedId =
    rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final combined =
    '${source['prenom'] ?? ''} ${source['nom'] ?? ''}'.trim();
    final nom = (source['nomComplet'] ??
        json['nomComplet'] ??
        (combined.isNotEmpty ? combined : source['email'] ?? ''))
    as String;

    return ControleurModel(
      id: parsedId,
      nomComplet: nom,
      email: (source['email'] ?? json['email'] ?? '') as String,
      role: (source['role'] ?? json['role'] ?? '') as String,
      statut: (source['statut'] ?? json['statut'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomComplet': nomComplet,
    'email': email,
    'role': role,
    'statut': statut,
  };
}