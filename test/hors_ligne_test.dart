import 'package:flutter_test/flutter_test.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/data/models/donnees_embarquees.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/qr_mt1.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/regles_hors_ligne.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/domain/signature_ed25519.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

/// Clé publique serveur de développement (application.properties du backend).
const clePubliqueServeur = 'MCowBQYDK2VwAyEA3279hHPsYAD0uHqlCQjw71ow6jUvIJcP6fvNjjIvcvY=';

/// QR réellement émis par le backend de développement.
const qrServeur = 'MT1|B|MLT-2026-C2B06283|1|1|250|1795826187|SRV.'
    'pazXk7qIzFHS-2vT13fLlAd989059IFJlRIUNEuQnfNChcDqqR45Z0fLTYCfF0GADwG3l4SsI2wbBdMqvjykAw';

Map<String, dynamic> trajetJson(int id, int ligneId, String debut, String fin, {String statut = 'PLANIFIE'}) => {
      'id': id,
      'date': '2026-11-28',
      'heureDebut': debut,
      'heureFin': fin,
      'statut': statut,
      'ligneId': ligneId,
      'ligneNumero': 'L-$ligneId',
      'ligneNom': 'Ligne $ligneId',
      'tarif': 250.0,
    };

void main() {
  group('Signature Ed25519', () {
    test('vérifie un QR signé par le serveur Java', () async {
      final qr = QrMt1.decoder(qrServeur)!;
      expect(await SignatureEd25519.verifier(qr.contenu, qr.signature, clePubliqueServeur), isTrue);
    });

    test('rejette un QR modifié (montant changé)', () async {
      final qr = QrMt1.decoder(qrServeur.replaceFirst('|250|', '|100|'))!;
      expect(await SignatureEd25519.verifier(qr.contenu, qr.signature, clePubliqueServeur), isFalse);
    });

    test('signe puis vérifie avec la clé de l’appareil (format X.509 du serveur)', () async {
      final graine = await SignatureEd25519.nouvelleGraine();
      final cle = await SignatureEd25519.clePubliqueX509(graine);
      expect(cle, startsWith('MCowBQYDK2VwAyEA'));
      const contenu = 'MT1|B|MLT-P01-1|3|1|250|1894702800|P01';
      final sig = await SignatureEd25519.signer(contenu, graine);
      expect(sig, isNot(contains('=')));
      expect(await SignatureEd25519.verifier(contenu, sig, cle), isTrue);
    });
  });

  group('QrMt1', () {
    test('décode un billet', () {
      final qr = QrMt1.decoder(qrServeur)!;
      expect(qr.estBillet, isTrue);
      expect(qr.reference, 'MLT-2026-C2B06283');
      expect((qr.affectationId, qr.ligneId, qr.montant, qr.signataire), (1, 1, 250, 'SRV'));
    });

    test('rejette les QR incomplets', () {
      expect(QrMt1.decoder('MT1|B|X|1|1|250|17|SRV'), isNull); // pas de signature
      expect(QrMt1.decoder('MT1|B|X|a|1|250|17|SRV.sig'), isNull);
      expect(QrMt1.decoder('PASS-2026-XYZ'), isNull);
    });
  });

  group('Contrôle hors ligne', () {
    late List<int> graine;
    late DonneesEmbarquees donnees;
    final courant = TrajetModel.fromJson(trajetJson(5, 1, '10:00:00', '11:00:00'));
    final maintenant = DateTime(2026, 11, 28, 10, 20);
    int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

    setUp(() async {
      graine = await SignatureEd25519.nouvelleGraine();
      donnees = DonneesEmbarquees.fromJson({
        'date': '2026-11-28',
        'appareilCode': 'P01',
        'dernierCompteur': 0,
        'clePubliqueServeur': clePubliqueServeur,
        'delaiTransfertMinutes': 90,
        'toleranceAvantDepartMinutes': 15,
        'trajets': [
          trajetJson(4, 1, '09:00:00', '10:00:00', statut: 'INTERROMPU'),
          trajetJson(5, 1, '10:00:00', '11:00:00'),
          trajetJson(6, 2, '08:00:00', '09:00:00'),
        ],
        'appareils': [
          {'code': 'P02', 'clePublique': await SignatureEd25519.clePubliqueX509(graine)},
        ],
        'abonnementsSuspendus': ['PASS-SUSPENDU'],
      });
    });

    Future<String> billet(int trajetId, int ligneId, DateTime emission, {String signataire = 'P02'}) async {
      final contenu = QrMt1.contenuBillet(
        numeroBillet: 'MLT-P02-7',
        affectationId: trajetId,
        ligneId: ligneId,
        montant: 250,
        emissionEpoch: epoch(emission),
        codeAppareil: signataire,
      );
      return '$contenu.${await SignatureEd25519.signer(contenu, graine)}';
    }

    Future<DecisionHorsLigne> controler(String qr, {Set<String> deja = const {}}) => controlerHorsLigne(
          brut: qr,
          donnees: donnees,
          trajet: courant,
          maintenant: maintenant,
          dejaAcceptes: deja,
        );

    test('billet du trajet courant : accepté, rien à synchroniser', () async {
      final d = await controler(await billet(5, 1, maintenant));
      expect((d.accepte, d.aSynchroniser), (true, false));
    });

    test('transfert valable depuis un trajet antérieur de la même ligne', () async {
      final d = await controler(await billet(4, 1, DateTime(2026, 11, 28, 9, 10)));
      expect((d.accepte, d.aSynchroniser, d.verdict), (true, true, 'TRANSFERT ACCEPTÉ'));
      expect(d.cleUnicite, 'T:MLT-P02-7');
    });

    test('transfert refusé : déjà accepté, délai dépassé, autre ligne', () async {
      final qr = await billet(4, 1, DateTime(2026, 11, 28, 9, 10));
      expect((await controler(qr, deja: {'T:MLT-P02-7'})).accepte, isFalse);
      expect((await controler(await billet(4, 1, DateTime(2026, 11, 28, 8, 30)))).accepte, isFalse);
      expect((await controler(await billet(6, 2, DateTime(2026, 11, 28, 9, 50)))).accepte, isFalse);
    });

    test('signataire inconnu ou signature falsifiée : refus', () async {
      expect((await controler(await billet(5, 1, maintenant, signataire: 'P99'))).accepte, isFalse);
      final falsifie = (await billet(5, 1, maintenant)).replaceFirst('|250|', '|100|');
      expect((await controler(falsifie)).message, contains('falsifié'));
    });

    test('code saisi à la main : refus explicite hors ligne', () async {
      expect((await controler('MLT-2026-ABC')).accepte, isFalse);
    });
  });

  group('Fenêtre de vente', () {
    final t = TrajetModel.fromJson(trajetJson(5, 1, '10:00:00', '11:00:00'));

    test('ouverte 15 min avant le départ jusqu’à la fin', () {
      expect(motifVenteImpossible(t, toleranceMinutes: 15, maintenant: DateTime(2026, 11, 28, 9, 50)), isNull);
      expect(motifVenteImpossible(t, toleranceMinutes: 15, maintenant: DateTime(2026, 11, 28, 9, 40)), isNotNull);
      expect(motifVenteImpossible(t, toleranceMinutes: 15, maintenant: DateTime(2026, 11, 28, 11, 1)), isNotNull);
    });
  });
}
