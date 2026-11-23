import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

abstract class TicketPrinterService {
  Future<void> printBilletUnique(
      BuildContext context,
      BilletUniqueModel billet,
      );
}

final ticketPrinterServiceProvider = Provider<TicketPrinterService>((ref) {
  return const SimulatedThermalPrinterService();
});

class SimulatedThermalPrinterService implements TicketPrinterService {
  const SimulatedThermalPrinterService();

  @override
  Future<void> printBilletUnique(
      BuildContext context,
      BilletUniqueModel billet,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'APERÇU TICKET THERMIQUE (58 MM)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MALI TRANS - BAMAKO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'BILLET A USAGE UNIQUE',
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.black54),
                    Text('NUMERO : ${billet.numeroBillet}'),
                    Text('MONTANT : ${billet.montantFormate}'),
                    Text('PAIEMENT : ${billet.modePaiement}'),
                    Text('DATE : ${billet.dateEmissionFormatee}'),
                    if (billet.ligneNumero != null &&
                        billet.ligneNumero!.isNotEmpty)
                      Text('LIGNE : ${billet.ligneNumero}'),
                    if (billet.busImmatriculation != null &&
                        billet.busImmatriculation!.isNotEmpty)
                      Text('BUS : ${billet.busImmatriculation}'),
                    const SizedBox(height: 10),
                    Center(
                      child: QrImageView(
                        data: billet.valeurQr,
                        version: QrVersions.auto,
                        size: 120,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '--------------------------------',
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Conservez ce ticket durant le trajet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}