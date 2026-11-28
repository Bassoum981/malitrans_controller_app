/// QR MaliTrans décodé (format MT1, docs/API.md §6.1). La signature n'est
/// pas vérifiée ici : voir [SignatureEd25519.verifier].
///
/// ```text
/// Billet     : MT1|B|{numeroBillet}|{affectationId}|{ligneId}|{montant}|{emissionEpoch}|{signataire}.{sig}
/// Abonnement : MT1|A|{codeTitre}|{passagerId}|{debutEpoch}|{finEpoch}|{expireEpoch}|SRV.{sig}
/// ```
class QrMt1 {
  static const signataireServeur = 'SRV';

  final bool estBillet;
  final String reference;
  final String signataire;
  final String contenu;
  final String signature;

  // Billet
  final int affectationId;
  final int ligneId;
  final int montant;
  final int emissionEpoch;

  // Abonnement
  final int passagerId;
  final int debutEpoch;
  final int finEpoch;
  final int expireEpoch;

  const QrMt1._({
    required this.estBillet,
    required this.reference,
    required this.signataire,
    required this.contenu,
    required this.signature,
    this.affectationId = 0,
    this.ligneId = 0,
    this.montant = 0,
    this.emissionEpoch = 0,
    this.passagerId = 0,
    this.debutEpoch = 0,
    this.finEpoch = 0,
    this.expireEpoch = 0,
  });

  /// `null` si ce n'est pas un QR MT1 complet et bien formé.
  static QrMt1? decoder(String brut) {
    final qr = brut.trim();
    final point = qr.lastIndexOf('.');
    if (point <= 0 || point == qr.length - 1) return null;
    final contenu = qr.substring(0, point);
    final signature = qr.substring(point + 1);
    final c = contenu.split('|');
    if (c.length != 8 || c[0] != 'MT1' || c[2].isEmpty) return null;
    final n = [for (final i in [3, 4, 5, 6]) int.tryParse(c[i])];
    if (n.contains(null)) return null;

    return switch (c[1]) {
      'B' => QrMt1._(
          estBillet: true,
          reference: c[2],
          affectationId: n[0]!,
          ligneId: n[1]!,
          montant: n[2]!,
          emissionEpoch: n[3]!,
          signataire: c[7],
          contenu: contenu,
          signature: signature,
        ),
      'A' => QrMt1._(
          estBillet: false,
          reference: c[2],
          passagerId: n[0]!,
          debutEpoch: n[1]!,
          finEpoch: n[2]!,
          expireEpoch: n[3]!,
          signataire: c[7],
          contenu: contenu,
          signature: signature,
        ),
      _ => null,
    };
  }

  /// Contenu (non signé) d'un billet vendu hors ligne par l'appareil [codeAppareil].
  static String contenuBillet({
    required String numeroBillet,
    required int affectationId,
    required int ligneId,
    required int montant,
    required int emissionEpoch,
    required String codeAppareil,
  }) =>
      ['MT1', 'B', numeroBillet, '$affectationId', '$ligneId', '$montant', '$emissionEpoch', codeAppareil]
          .join('|');
}
