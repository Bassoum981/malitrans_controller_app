import 'package:flutter_test/flutter_test.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/resultat_controle_model.dart';
import 'package:malitrans_controleur_app/features/controle/domain/qr_parser.dart';

void main() {
  group('lireTitre', () {
    test('QR billet MT1 signé par le serveur', () {
      const qr = 'MT1|B|MLT-2026-C2B06283|1|1|250|1795826187|SRV.pazXk7qIzFHS-2vT13fLlAd9890';
      expect(lireTitre(qr), const TitreScanne(TypeTitre.billet, 'MLT-2026-C2B06283'));
    });

    test('QR billet MT1 vendu hors ligne (signataire appareil)', () {
      const qr = 'MT1|B|MLT-P01-42|56|42|300|1894702800|P01.8Zqn0G_abc-def';
      expect(lireTitre(qr), const TitreScanne(TypeTitre.billet, 'MLT-P01-42'));
    });

    test('QR abonnement MT1', () {
      const qr = 'MT1|A|PASS-2026-BBEF6710|227|1894702800|1897294800|1894875600|SRV.pYFve7YK1MoGy';
      expect(lireTitre(qr), const TitreScanne(TypeTitre.abonnement, 'PASS-2026-BBEF6710'));
    });

    test('code saisi à la main, espaces et minuscules tolérés', () {
      expect(lireTitre('  mlt-2026-abc  '), const TitreScanne(TypeTitre.billet, 'MLT-2026-ABC'));
      expect(lireTitre('pass-2026-xyz'), const TitreScanne(TypeTitre.abonnement, 'PASS-2026-XYZ'));
    });

    test('texte étranger ou QR mal formé → null', () {
      expect(lireTitre(''), isNull);
      expect(lireTitre('https://exemple.com'), isNull);
      expect(lireTitre('MT1|X|CODE|1.sig'), isNull);
      expect(lireTitre('MT1|B'), isNull);
      expect(lireTitre('MT1|B||1|2.sig'), isNull);
    });
  });

  group('ResultatControle', () {
    const billet = TitreScanne(TypeTitre.billet, 'MLT-2026-C2B06283');
    const abonnement = TitreScanne(TypeTitre.abonnement, 'PASS-2026-4DB55910');

    test('billet valable sur le trajet', () {
      final r = ResultatControle.depuisBillet(billet, {
        'transfert': false,
        'message': 'Billet valable sur ce trajet.',
        'billet': {'statut': 'VALIDE', 'ligneNumero': 'L-1', 'montantPaye': 250.0},
      });
      expect(r.accepte, isTrue);
      expect(r.verdict, 'BILLET VALABLE');
      expect(r.message, 'Billet valable sur ce trajet.');
    });

    test('billet transféré après panne', () {
      final r = ResultatControle.depuisBillet(billet, {
        'transfert': true,
        'message': 'Transfert accepté.',
        'billet': {'statut': 'VALIDE'},
      });
      expect(r.accepte, isTrue);
      expect(r.verdict, 'TRANSFERT ACCEPTÉ');
    });

    test('abonnement valide → montée autorisée', () {
      final r = ResultatControle.depuisAbonnement(abonnement, {
        'valideActuellement': true,
        'statut': 'ACTIF',
        'passagerNomComplet': 'Awa Traoré',
        'dateFin': '2026-12-28T00:36:17',
      });
      expect(r.accepte, isTrue);
      expect(r.details, contains(('Passager', 'Awa Traoré')));
      expect(r.details, contains(('Expire le', '28/12/2026 00:36')));
    });

    test('refus métier', () {
      final r = ResultatControle.refus(abonnement, 'Cet abonnement a déjà été présenté sur ce trajet.');
      expect(r.accepte, isFalse);
      expect(r.verdict, 'REFUSÉ');
    });
  });
}
