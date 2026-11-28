import 'package:flutter/material.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';

Color couleurStatutTrajet(BuildContext context, String statut) => switch (statut) {
      'EN_COURS' => context.c.success,
      'INTERROMPU' => context.c.danger,
      'TERMINE' => context.c.labelSecondary,
      _ => context.c.tint,
    };

/// Badge du numéro de ligne.
class BadgeLigne extends StatelessWidget {
  final String numero;

  const BadgeLigne(this.numero, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.primaryFill, borderRadius: BorderRadius.circular(10)),
      child: Text(
        numero,
        style: context.t.titleMedium?.copyWith(color: c.onPrimaryFill, fontWeight: FontWeight.w800, letterSpacing: 0),
      ),
    );
  }
}

/// Résumé d'un trajet : ligne, horaire, tarif, bus, affluence.
class TrajetResume extends StatelessWidget {
  final TrajetModel trajet;
  final Widget? trailing;

  const TrajetResume({super.key, required this.trajet, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final remplissage = trajet.capaciteTotale == 0
        ? 0.0
        : (trajet.montees / trajet.capaciteTotale).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BadgeLigne(trajet.ligneNumero),
            const SizedBox(width: 12),
            Expanded(
              child: Text(trajet.ligneNom, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium),
            ),
            const SizedBox(width: 8),
            trailing ?? Pastille(trajet.libelleStatut, couleur: couleurStatutTrajet(context, trajet.statut)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                trajet.horaire,
                style: t.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            Text(Format.fcfa(trajet.tarif), style: t.titleMedium?.copyWith(color: c.labelSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(trajet.bus.isEmpty ? 'Bus non renseigné' : 'Bus ${trajet.bus}', style: t.bodySmall),
        const SizedBox(height: 14),
        // Affluence : indicateur seulement, ne bloque jamais la vente.
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: remplissage,
            minHeight: 5,
            backgroundColor: c.surfaceSecondary,
            color: trajet.surcharge ? c.danger : c.tint,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${trajet.montees} à bord sur ${trajet.capaciteTotale} places'
          '${trajet.surcharge ? ' · surcharge' : ''}',
          style: t.bodySmall?.copyWith(color: trajet.surcharge ? c.danger : null),
        ),
      ],
    );
  }
}
