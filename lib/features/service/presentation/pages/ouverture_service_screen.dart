import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/widgets/hors_ligne_widgets.dart';
import 'package:malitrans_controleur_app/features/service/presentation/controllers/service_controller.dart';

/// Aucun service ouvert : le receveur doit en ouvrir un avant de vendre.
class OuvertureServiceScreen extends ConsumerStatefulWidget {
  final ControleurModel controleur;

  const OuvertureServiceScreen({super.key, required this.controleur});

  @override
  ConsumerState<OuvertureServiceScreen> createState() => _OuvertureServiceScreenState();
}

class _OuvertureServiceScreenState extends ConsumerState<OuvertureServiceScreen> {
  bool _enCours = false;
  String? _erreur;

  String get _prenom => widget.controleur.nomComplet.split(' ').first;

  Future<void> _ouvrir() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceEnCoursProvider.notifier).ouvrir();
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _erreur = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _deconnecter() async {
    final ok = await confirmer(
      context,
      titre: 'Se déconnecter ?',
      message: 'Vous devrez saisir à nouveau vos identifiants.',
      action: 'Se déconnecter',
    );
    if (ok) await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final cloture = ref.watch(dernierServiceClotureProvider);

    return MtPage(
      titre: 'Bonjour $_prenom',
      sousTitre: Format.jourLong(),
      actions: [BoutonBarre(icone: Icons.logout_rounded, tooltip: 'Se déconnecter', onPressed: _deconnecter)],
      children: [
        const SizedBox(height: 8),
        Surface(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: c.tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.play_arrow_rounded, size: 34, color: c.tint),
              ),
              const SizedBox(height: 18),
              Text('Commencer la journée', style: t.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Ouvrez votre service pour vendre des billets et contrôler à bord. '
                'Les espèces encaissées y seront rattachées.',
                style: t.bodyMedium?.copyWith(color: c.labelSecondary),
              ),
              if (_erreur != null) ...[const SizedBox(height: 16), MessageErreur(_erreur!)],
              const SizedBox(height: 22),
              MtButton.grand(
                label: 'Ouvrir mon service',
                icone: Icons.play_arrow_rounded,
                chargement: _enCours,
                onPressed: _ouvrir,
              ),
            ],
          ),
        ),
        const SectionHorsLigne(),
        if (cloture != null) ...[
          const TitreSection('Dernier service'),
          SpringIn(
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: c.success, size: 22),
                      const SizedBox(width: 8),
                      Text('Service clôturé', style: t.titleMedium?.copyWith(color: c.success)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('À remettre au caissier', style: t.bodySmall),
                  const SizedBox(height: 4),
                  Text(Format.fcfa(cloture.montantEncaisse), style: t.displaySmall),
                  const SizedBox(height: 16),
                  Text(
                    '${cloture.nombreVentes} billet(s) · de ${Format.heureDe(cloture.ouvertLe)} '
                    'à ${Format.heureDe(cloture.clotureLe)}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(
              'Un nouveau service pourra être ouvert une fois le versement enregistré par le caissier.',
              style: t.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
