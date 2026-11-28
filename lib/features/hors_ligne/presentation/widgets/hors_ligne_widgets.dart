import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/network/reseau.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pastille d'état dans la barre de titre : « Hors ligne » et/ou éléments en
/// attente. Invisible quand tout est en ligne et synchronisé. Toucher = synchroniser.
class IndicateurSync extends ConsumerWidget {
  const IndicateurSync({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final enLigne = ref.watch(reseauProvider);
    final etat = ref.watch(horsLigneProvider).value;
    final attente = etat?.enAttente ?? 0;
    final enCours = etat?.synchronisation ?? false;

    final visible = !enLigne || attente > 0;
    final couleur = enLigne ? c.tint : c.warning;
    final texte = !enLigne
        ? (attente > 0 ? 'Hors ligne · $attente' : 'Hors ligne')
        : '$attente à envoyer';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !visible
          ? const SizedBox.shrink()
          : Pressable(
              key: ValueKey(texte),
              scale: 0.92,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(horsLigneProvider.notifier).synchroniser();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    enCours
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: couleur),
                          )
                        : Icon(enLigne ? Icons.cloud_upload_rounded : Icons.cloud_off_rounded, size: 15, color: couleur),
                    const SizedBox(width: 6),
                    Text(
                      texte,
                      style: context.t.labelSmall?.copyWith(color: couleur, fontWeight: FontWeight.w700, letterSpacing: 0),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Configuration du terminal : affiche la clé publique à transmettre à
/// l'administrateur, puis vérifie l'enregistrement sous le code choisi.
class FeuilleEnrolement extends ConsumerStatefulWidget {
  const FeuilleEnrolement({super.key});

  @override
  ConsumerState<FeuilleEnrolement> createState() => _FeuilleEnrolementState();
}

class _FeuilleEnrolementState extends ConsumerState<FeuilleEnrolement> {
  final _code = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(horsLigneProvider.notifier).enroler(_code.text);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _erreur = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final cle = ref.watch(horsLigneProvider).value?.clePublique ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Configurer le mode hors ligne', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(
          "1. Transmettez la clé publique de ce téléphone à l'administrateur, avec le code du terminal "
          '(ex. P01).\n2. Une fois le terminal enregistré, saisissez son code et vérifiez.',
          style: t.bodyMedium?.copyWith(color: c.labelSecondary),
        ),
        const SizedBox(height: 18),
        Surface(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: cle, size: 150, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              SelectableText(
                cle,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(fontFamily: 'monospace', color: c.label),
              ),
              const SizedBox(height: 10),
              MtButton(
                label: 'Copier la clé',
                icone: Icons.copy_rounded,
                style: StyleBouton.teinte,
                hauteur: 44,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cle));
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clé publique copiée.')));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(Icons.point_of_sale_rounded, color: c.labelSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  onSubmitted: (_) => _verifier(),
                  style: t.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Code du terminal (ex. P01)',
                    hintStyle: t.bodyLarge?.copyWith(color: c.labelTertiary),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_erreur != null) ...[const SizedBox(height: 12), MessageErreur(_erreur!)],
        const SizedBox(height: 18),
        MtButton(label: 'Vérifier l’enregistrement', chargement: _enCours, onPressed: _verifier),
      ],
    );
  }
}

/// Éléments refusés définitivement par le serveur (pour le support).
class FeuilleRejets extends ConsumerWidget {
  const FeuilleRejets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final t = context.t;
    final rejets = ref.watch(horsLigneProvider).value?.rejets ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Éléments refusés', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Le serveur a refusé ces éléments (données invalides). Ils ne seront pas renvoyés. '
          'Signalez-les à votre responsable.',
          style: t.bodyMedium?.copyWith(color: c.labelSecondary),
        ),
        const SizedBox(height: 16),
        for (final r in rejets.reversed) ...[
          Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pastille(r.type == 'vente' ? 'VENTE' : 'MONTÉE', couleur: c.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.reference, style: t.titleMedium, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.message, style: t.bodyMedium),
                const SizedBox(height: 4),
                Text(Format.dateHeure(r.date), style: t.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        MtButton(
          label: 'Effacer la liste',
          style: StyleBouton.discret,
          onPressed: () async {
            final ok = await confirmer(
              context,
              titre: 'Effacer les éléments refusés ?',
              message: 'Assurez-vous de les avoir signalés : ils ne seront plus visibles.',
              action: 'Effacer',
              destructif: true,
            );
            if (ok) {
              await ref.read(horsLigneProvider.notifier).oublierRejets();
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}

/// Section « Mode hors ligne » de l'onglet Service.
class SectionHorsLigne extends ConsumerWidget {
  const SectionHorsLigne({super.key});

  void _message(BuildContext context, String texte) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final enLigne = ref.watch(reseauProvider);
    final etat = ref.watch(horsLigneProvider).value;
    if (etat == null) return const SizedBox.shrink();
    final notifier = ref.read(horsLigneProvider.notifier);

    final lignes = <Widget>[
      Ligne(
        icone: enLigne ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
        couleurIcone: enLigne ? c.success : c.warning,
        libelle: enLigne ? 'En ligne' : 'Hors ligne',
        sousTitre: enLigne ? 'Ventes et contrôles envoyés directement.' : 'Ventes et contrôles enregistrés sur le téléphone.',
      ),
      if (!etat.enrole)
        Ligne(
          icone: Icons.point_of_sale_rounded,
          libelle: 'Configurer ce terminal',
          sousTitre: 'Nécessaire pour vendre sans réseau',
          chevron: true,
          onTap: () => afficherFeuille<bool>(context, builder: (_) => const FeuilleEnrolement()),
        )
      else ...[
        Ligne(
          icone: Icons.point_of_sale_rounded,
          libelle: 'Terminal',
          valeur: etat.codeAppareil,
        ),
        Ligne(
          icone: Icons.download_rounded,
          couleurIcone: etat.pret ? c.success : c.warning,
          libelle: 'Données du jour',
          valeur: etat.pret ? Format.heureDe(etat.donnees!.genereLe) : 'À charger',
          onTap: () async {
            try {
              await notifier.chargerDonnees();
              if (context.mounted) _message(context, 'Données du jour chargées.');
            } catch (e) {
              if (context.mounted) _message(context, ApiException.from(e).message);
            }
          },
        ),
      ],
      Ligne(
        icone: Icons.sync_rounded,
        libelle: 'Synchroniser',
        sousTitre: etat.enAttente == 0
            ? (etat.derniereSync == null ? 'Rien en attente' : 'À jour · ${Format.heureDe(etat.derniereSync)}')
            : '${etat.ventesEnAttente} vente(s) · ${etat.validationsEnAttente} montée(s) · '
                '${Format.fcfa(etat.montantEnAttente)}',
        trailing: etat.synchronisation
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : null,
        onTap: etat.enAttente == 0 || etat.synchronisation
            ? null
            : () async {
                await notifier.synchroniser();
                final apres = ref.read(horsLigneProvider).value;
                if (!context.mounted || apres == null) return;
                _message(
                  context,
                  apres.enAttente == 0
                      ? 'Tout est synchronisé.'
                      : (apres.erreurSync?.isNotEmpty ?? false)
                          ? apres.erreurSync!
                          : '${apres.enAttente} élément(s) encore en attente.',
                );
              },
      ),
      if (etat.rejets.isNotEmpty)
        Ligne(
          icone: Icons.report_rounded,
          libelle: 'Éléments refusés',
          destructive: true,
          valeur: '${etat.rejets.length}',
          chevron: true,
          onTap: () => afficherFeuille<void>(context, builder: (_) => const FeuilleRejets()),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitreSection('Mode hors ligne'),
        if (etat.autreProprietaire) ...[
          const MessageErreur(
            'Ce téléphone contient des éléments non synchronisés d’un autre receveur : '
            'il doit se reconnecter pour les envoyer.',
          ),
          const SizedBox(height: 10),
        ],
        Groupe(
          lignes: lignes,
          pied: etat.enrole
              ? 'Sans réseau, les billets sont signés par ce terminal et envoyés automatiquement au retour du réseau.'
              : null,
        ),
      ],
    );
  }
}
