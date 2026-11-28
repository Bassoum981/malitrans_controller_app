/// Type de titre présenté à bord.
enum TypeTitre { billet, abonnement }

/// Résultat de la lecture d'un QR (ou d'un code saisi à la main).
class TitreScanne {
  final TypeTitre type;

  /// `numeroBillet` (MLT-…) ou `codeTitre` (PASS-…), utilisé par l'API.
  final String code;

  const TitreScanne(this.type, this.code);

  @override
  bool operator ==(Object other) =>
      other is TitreScanne && other.type == type && other.code == code;

  @override
  int get hashCode => Object.hash(type, code);

  @override
  String toString() => 'TitreScanne($type, $code)';
}

/// Lit un QR MaliTrans (docs/API.md §6.1) :
///  - `MT1|B|{numeroBillet}|….{signature}` → billet
///  - `MT1|A|{codeTitre}|….{signature}`    → abonnement
/// Accepte aussi un code nu saisi à la main (`MLT-…`, `PASS-…`).
/// Renvoie `null` si le texte n'est pas un titre MaliTrans.
///
/// La signature n'est pas vérifiée ici : en ligne, c'est le serveur qui fait foi.
TitreScanne? lireTitre(String brut) {
  final texte = brut.trim();
  if (texte.isEmpty) return null;

  if (texte.startsWith('MT1|')) {
    final point = texte.lastIndexOf('.');
    final contenu = point > 0 ? texte.substring(0, point) : texte;
    final champs = contenu.split('|');
    if (champs.length < 3 || champs[2].isEmpty) return null;
    return switch (champs[1]) {
      'B' => TitreScanne(TypeTitre.billet, champs[2]),
      'A' => TitreScanne(TypeTitre.abonnement, champs[2]),
      _ => null,
    };
  }

  final code = texte.toUpperCase();
  if (code.startsWith('MLT-')) return TitreScanne(TypeTitre.billet, code);
  if (code.startsWith('PASS-')) return TitreScanne(TypeTitre.abonnement, code);
  return null;
}
