import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

abstract class TicketPrinterService {
  Future<void> printBilletUnique(BuildContext context, BilletUniqueModel billet);
}

final ticketPrinterServiceProvider = Provider<TicketPrinterService>((ref) {
  return const SimulatedThermalPrinterService();
});

/// Imprimante simulée : aperçu du ticket thermique 58 mm dans une feuille.
class SimulatedThermalPrinterService implements TicketPrinterService {
  const SimulatedThermalPrinterService();

  @override
  Future<void> printBilletUnique(BuildContext context, BilletUniqueModel billet) {
    return afficherFeuille<void>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.print_rounded, color: ctx.c.tint),
              const SizedBox(width: 10),
              Expanded(child: Text('Aperçu du ticket', style: ctx.t.titleLarge)),
              Pastille('58 mm', couleur: ctx.c.labelSecondary),
            ],
          ),
          const SizedBox(height: 18),
          Center(child: TicketPapier(billet: billet)),
          const SizedBox(height: 20),
          MtButton(label: 'Terminé', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }
}

/// Rendu « papier thermique » : toujours noir sur blanc, police à chasse fixe.
class TicketPapier extends StatelessWidget {
  final BilletUniqueModel billet;

  const TicketPapier({super.key, required this.billet});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 12, height: 1.45);
    Widget ligne(String a, String b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 76, child: Text(a, style: style)),
            Expanded(child: Text(b, style: style.copyWith(fontWeight: FontWeight.w700))),
          ],
        );

    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: DefaultTextStyle(
        style: style,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MALI TRANS · BAMAKO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
            ),
            const Text('BILLET À USAGE UNIQUE', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text('- - - - - - - - - - - - - - - -', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ligne('N°', billet.numeroBillet),
            if (billet.ligneNumero != null) ligne('LIGNE', '${billet.ligneNumero} ${billet.ligneNom ?? ''}'.trim()),
            if (billet.heureDebut != null) ligne('DÉPART', Format.heure(billet.heureDebut)),
            if (billet.busImmatriculation != null) ligne('BUS', billet.busImmatriculation!),
            ligne('ÉMIS LE', billet.dateEmissionFormatee),
            ligne('PAIEMENT', billet.modePaiement),
            if (billet.horsLigne) ligne('ÉMIS', 'HORS LIGNE'),
            const SizedBox(height: 8),
            Text(
              billet.montantFormate,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Center(
              child: QrImageView(
                // QR signé MT1, imprimé tel quel (docs/API.md §5.6).
                data: billet.qrCode,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Valable pour ce trajet uniquement.\nConservez ce ticket durant le trajet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}
