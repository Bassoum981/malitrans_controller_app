import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/widgets/hors_ligne_widgets.dart';
import 'package:malitrans_controleur_app/features/service/data/models/service_receveur_model.dart';
import 'package:malitrans_controleur_app/features/service/presentation/controllers/service_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/pages/choix_trajet_screen.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/widgets/trajet_resume.dart';

/// Bilan du service en cours, trajet, panne, clôture et compte.
class MonServiceScreen extends ConsumerWidget {
  final ServiceReceveurModel service;
  final TrajetModel trajet;

  const MonServiceScreen({super.key, required this.service, required this.trajet});

  Future<void> _actualiser(WidgetRef ref) async {
    await Future.wait([
      ref.read(serviceEnCoursProvider.notifier).rafraichir(),
      ref.read(trajetCourantProvider.notifier).rafraichir(),
    ]);
  }

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _signalerPanne(BuildContext context, WidgetRef ref) async {
    final description = await afficherFeuille<String>(context, builder: (_) => const _FeuillePanne());
    if (description == null || !context.mounted) return;
    try {
      await ref.read(trajetCourantProvider.notifier).signalerPanne(description);
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        _message(context, 'Trajet interrompu. Les billets seront acceptés sur le trajet suivant de la ligne.');
      }
    } catch (e) {
      if (context.mounted) _message(context, ApiException.from(e).message);
    }
  }

  Future<void> _cloturer(BuildContext context, WidgetRef ref) async {
    final ok = await confirmer(
      context,
      titre: 'Clôturer le service ?',
      message: 'Vous ne pourrez plus vendre de billets sur ce service.',
      action: 'Clôturer le service',
      destructif: true,
      contenu: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('À remettre au caissier', style: context.t.bodySmall),
            const SizedBox(height: 4),
            Text(Format.fcfa(service.montantEncaisse), style: context.t.displaySmall),
            const SizedBox(height: 6),
            Text('${service.nombreVentes} billet(s) vendu(s)', style: context.t.bodySmall),
          ],
        ),
      ),
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(serviceEnCoursProvider.notifier).cloturer();
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (context.mounted) _message(context, ApiException.from(e).message);
    }
  }

  Future<void> _deconnecter(BuildContext context, WidgetRef ref) async {
    // Les éléments hors ligne sont attribués au receveur connecté : on ne
    // laisse pas partir le compte avant de les avoir envoyés.
    await ref.read(horsLigneProvider.notifier).synchroniser();
    final restant = ref.read(horsLigneProvider).value?.enAttente ?? 0;
    if (restant > 0) {
      if (context.mounted) {
        _message(context, '$restant élément(s) hors ligne à synchroniser avant de vous déconnecter.');
      }
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmer(
      context,
      titre: 'Se déconnecter ?',
      message: 'Votre service reste ouvert : vous le retrouverez à la prochaine connexion.',
      action: 'Se déconnecter',
    );
    if (ok) await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final t = context.t;
    final controleur = ref.watch(sessionProvider).value;
    final horsLigne = ref.watch(horsLigneProvider).value;
    final montantEnAttente = horsLigne?.montantEnAttente ?? 0;

    return MtPage(
      titre: 'Service',
      sousTitre: 'Ouvert à ${Format.heureDe(service.ouvertLe)}',
      avecBarreOnglets: true,
      actions: const [IndicateurSync(), SizedBox(width: 8)],
      onRefresh: () => _actualiser(ref),
      children: [
        const SizedBox(height: 8),
        Surface(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Espèces encaissées', style: t.bodySmall)),
                  Pastille('OUVERT', couleur: c.success),
                ],
              ),
              const SizedBox(height: 6),
              Text(Format.fcfa(service.montantEncaisse), style: t.displaySmall),
              const SizedBox(height: 8),
              Text('${service.nombreVentes} billet(s) vendu(s)', style: t.bodyMedium?.copyWith(color: c.labelSecondary)),
              if (montantEnAttente > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${Format.fcfa(montantEnAttente)} vendus hors ligne, en attente de synchronisation',
                  style: t.bodySmall?.copyWith(color: c.warning, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
        const TitreSection('Mon trajet'),
        Surface(child: TrajetResume(trajet: trajet)),
        const SizedBox(height: 12),
        Groupe(
          lignes: [
            Ligne(
              icone: Icons.swap_horiz_rounded,
              libelle: 'Changer de trajet',
              chevron: true,
              onTap: () => Navigator.of(context).push(
                RouteDepuisLeBas(builder: (_) => const ChoixTrajetScreen(enPage: true)),
              ),
            ),
            if (!trajet.estTermine)
              Ligne(
                icone: Icons.car_crash_rounded,
                libelle: 'Signaler une panne',
                destructive: true,
                chevron: true,
                onTap: () => _signalerPanne(context, ref),
              ),
          ],
        ),
        const SectionHorsLigne(),
        const TitreSection('Fin de service'),
        Groupe(
          lignes: [
            Ligne(
              icone: Icons.stop_circle_rounded,
              libelle: 'Clôturer mon service',
              destructive: true,
              onTap: () => _cloturer(context, ref),
            ),
          ],
          pied: 'Clôturez votre service puis remettez vos espèces au caissier.',
        ),
        const TitreSection('Compte'),
        Groupe(
          lignes: [
            if (controleur != null)
              Ligne(
                icone: Icons.person_rounded,
                couleurIcone: c.labelSecondary,
                libelle: controleur.nomComplet,
                sousTitre: controleur.email,
              ),
            Ligne(
              icone: Icons.logout_rounded,
              libelle: 'Se déconnecter',
              onTap: () => _deconnecter(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeuillePanne extends StatefulWidget {
  const _FeuillePanne();

  @override
  State<_FeuillePanne> createState() => _FeuillePanneState();
}

class _FeuillePanneState extends State<_FeuillePanne> {
  final _controller = TextEditingController();

  static const _suggestions = ['Panne moteur', 'Pneu crevé', 'Accident', 'Problème de freins'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Signaler une panne', style: context.t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Le trajet sera interrompu et le bus déclaré en panne. '
          'Les passagers pourront monter dans le bus suivant de la ligne avec leur billet.',
          style: context.t.bodyMedium?.copyWith(color: c.labelSecondary),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _suggestions)
              Pressable(
                onTap: () => setState(() => _controller.text = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                  child: Text(s, style: context.t.bodyMedium),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: _controller,
            maxLength: 255,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: context.t.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Décrivez la panne',
              hintStyle: context.t.bodyLarge?.copyWith(color: c.labelTertiary),
              border: InputBorder.none,
              isCollapsed: true,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 20),
        MtButton(
          label: 'Interrompre le trajet',
          style: StyleBouton.destructif,
          onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _controller.text.trim()),
        ),
      ],
    );
  }
}
