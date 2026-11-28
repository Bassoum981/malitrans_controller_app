import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/widgets/trajet_resume.dart';

/// Liste des trajets du jour : le receveur choisit celui de son bus.
/// Utilisé dans le parcours principal et en feuille « Changer de trajet ».
class ChoixTrajetScreen extends ConsumerWidget {
  /// `true` quand l'écran est ouvert par-dessus l'app (bouton fermer, retour après choix).
  final bool enPage;

  const ChoixTrajetScreen({super.key, this.enPage = false});

  Future<void> _choisir(BuildContext context, WidgetRef ref, TrajetModel trajet) async {
    HapticFeedback.selectionClick();
    await ref.read(trajetCourantProvider.notifier).choisir(trajet);
    if (enPage && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trajets = ref.watch(trajetsDuJourProvider);
    final courantId = ref.watch(trajetCourantProvider).value?.id;
    final c = context.c;

    final contenu = <Widget>[
      ...trajets.when(
        loading: () => [
          const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator())),
        ],
        error: (e, _) => [
          EtatVide(
            icone: Icons.wifi_off_rounded,
            titre: 'Trajets indisponibles',
            message: ApiException.from(e).message,
            action: 'Réessayer',
            onAction: () => ref.invalidate(trajetsDuJourProvider),
          ),
        ],
        data: (liste) => liste.isEmpty
            ? [
                const EtatVide(
                  icone: Icons.event_busy_rounded,
                  titre: "Aucun trajet aujourd'hui",
                  message: 'Tirez vers le bas pour actualiser.',
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                  child: Text(
                    'Touchez le trajet de votre bus. Les ventes et les contrôles y seront enregistrés.',
                    style: context.t.bodySmall,
                  ),
                ),
                for (final trajet in liste) ...[
                  Pressable(
                    onTap: () => _choisir(context, ref, trajet),
                    child: Surface(
                      child: TrajetResume(
                        trajet: trajet,
                        trailing: trajet.id == courantId
                            ? Icon(Icons.check_circle_rounded, color: c.tint, size: 26)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
      ),
    ];

    final page = MtPage(
      titre: enPage ? 'Changer de trajet' : 'Votre trajet',
      sousTitre: Format.jourLong(),
      leading: enPage
          ? BoutonBarre(
              icone: Icons.close_rounded,
              tooltip: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      onRefresh: () => ref.refresh(trajetsDuJourProvider.future),
      children: contenu,
    );

    return enPage ? Scaffold(body: page) : page;
  }
}
