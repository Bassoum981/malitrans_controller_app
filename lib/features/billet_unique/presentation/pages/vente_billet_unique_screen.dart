import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/printer/ticket_printer_service.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/core/utils/format.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/widgets/hors_ligne_widgets.dart';
import 'package:malitrans_controleur_app/features/service/presentation/controllers/service_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/widgets/trajet_resume.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Vente d'un billet à bord, en espèces, au tarif de la ligne du trajet courant.
class VenteBilletUniqueScreen extends ConsumerStatefulWidget {
  final TrajetModel trajet;

  const VenteBilletUniqueScreen({super.key, required this.trajet});

  @override
  ConsumerState<VenteBilletUniqueScreen> createState() => _VenteBilletUniqueScreenState();
}

class _VenteBilletUniqueScreenState extends ConsumerState<VenteBilletUniqueScreen> {
  bool _enCours = false;
  String? _erreur;
  int? _passagerId;
  BilletUniqueModel? _dernierBillet;

  Future<void> _vendre() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      // En ligne d'abord ; sans réseau, billet signé par le terminal (§7.2).
      final billet = await ref.read(horsLigneProvider.notifier).vendre(widget.trajet, passagerId: _passagerId);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _dernierBillet = billet;
        _passagerId = null;
      });
      // Compteurs : espèces du service, billets vendus du trajet.
      if (!billet.horsLigne) {
        ref.read(serviceEnCoursProvider.notifier).rafraichir().catchError((_) {});
        ref.read(trajetCourantProvider.notifier).rafraichir().catchError((_) {});
      }
      await _imprimer(billet);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _erreur = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _imprimer(BilletUniqueModel billet) =>
      ref.read(ticketPrinterServiceProvider).printBilletUnique(context, billet);

  Future<void> _choisirPassager() async {
    final id = await afficherFeuille<int>(context, builder: (_) => _FeuillePassager(initial: _passagerId));
    if (id != null && mounted) setState(() => _passagerId = id == 0 ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final trajet = widget.trajet;
    final service = ref.watch(serviceEnCoursProvider).value;

    return MtPage(
      titre: 'Vente',
      sousTitre: '${trajet.ligneNumero} · ${trajet.horaire}',
      avecBarreOnglets: true,
      actions: const [IndicateurSync(), SizedBox(width: 8)],
      children: [
        const SizedBox(height: 8),
        Surface(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BadgeLigne(trajet.ligneNumero),
                  const SizedBox(width: 10),
                  Expanded(child: Text(trajet.ligneNom, style: t.bodyMedium?.copyWith(color: c.labelSecondary))),
                ],
              ),
              const SizedBox(height: 22),
              Text('Billet à usage unique', style: t.bodySmall),
              const SizedBox(height: 4),
              Text(Format.fcfa(trajet.tarif), style: t.displaySmall),
              const SizedBox(height: 4),
              Text('Espèces · valable pour ce trajet', style: t.bodySmall),
              if (_erreur != null) ...[const SizedBox(height: 16), MessageErreur(_erreur!)],
              const SizedBox(height: 22),
              MtButton.grand(
                label: trajet.estTermine
                    ? 'Trajet ${trajet.libelleStatut.toLowerCase()}'
                    : 'Encaisser ${Format.fcfa(trajet.tarif)}',
                icone: Icons.payments_rounded,
                chargement: _enCours,
                onPressed: trajet.estTermine ? null : _vendre,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Groupe(
          lignes: [
            Ligne(
              icone: Icons.person_rounded,
              libelle: 'Compte passager',
              valeur: _passagerId == null ? 'Aucun' : 'N° $_passagerId',
              chevron: true,
              onTap: _choisirPassager,
            ),
          ],
          pied: 'Facultatif : rattache le billet au compte d’un passager.',
        ),
        if (service != null) ...[
          const TitreSection('Mon service'),
          Row(
            children: [
              Expanded(child: _Stat(valeur: '${service.nombreVentes}', libelle: 'billets vendus')),
              const SizedBox(width: 12),
              Expanded(child: _Stat(valeur: Format.fcfa(service.montantEncaisse), libelle: 'encaissés')),
            ],
          ),
        ],
        if (_dernierBillet != null) ...[
          const TitreSection('Dernier billet'),
          SpringIn(
            key: ValueKey(_dernierBillet!.numeroBillet),
            child: _CarteDernierBillet(billet: _dernierBillet!, onReimprimer: () => _imprimer(_dernierBillet!)),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String valeur;
  final String libelle;

  const _Stat({required this.valeur, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valeur,
              style: context.t.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 2),
          Text(libelle, style: context.t.bodySmall),
        ],
      ),
    );
  }
}

class _CarteDernierBillet extends StatelessWidget {
  final BilletUniqueModel billet;
  final VoidCallback onReimprimer;

  const _CarteDernierBillet({required this.billet, required this.onReimprimer});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                color: Colors.white,
                child: QrImageView(data: billet.qrCode, size: 84, backgroundColor: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: c.success, size: 18),
                        const SizedBox(width: 6),
                        Text('Émis', style: t.bodySmall?.copyWith(color: c.success, fontWeight: FontWeight.w600)),
                        if (billet.horsLigne) ...[
                          const SizedBox(width: 8),
                          Pastille('HORS LIGNE', couleur: c.warning),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(billet.numeroBillet, style: t.titleMedium),
                    Text('${billet.montantFormate} · ${Format.heureDe(billet.dateEmission)}', style: t.bodySmall),
                    if (billet.passagerId != null)
                      Text(billet.passagerNomComplet ?? 'Passager N° ${billet.passagerId}', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MtButton(
            label: 'Réimprimer le ticket',
            icone: Icons.print_rounded,
            style: StyleBouton.teinte,
            hauteur: 48,
            onPressed: onReimprimer,
          ),
        ],
      ),
    );
  }
}

/// Saisie de l'identifiant passager. Renvoie l'id, ou 0 pour « aucun ».
class _FeuillePassager extends StatefulWidget {
  final int? initial;

  const _FeuillePassager({this.initial});

  @override
  State<_FeuillePassager> createState() => _FeuillePassagerState();
}

class _FeuillePassagerState extends State<_FeuillePassager> {
  late final _controller = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _valider() {
    final id = int.tryParse(_controller.text.trim());
    Navigator.pop(context, id != null && id > 0 ? id : 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Compte passager', style: context.t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Saisissez l’identifiant du passager pour rattacher le billet à son compte.',
          style: context.t.bodyMedium?.copyWith(color: c.labelSecondary),
        ),
        const SizedBox(height: 18),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: c.labelSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _valider(),
                  style: context.t.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Identifiant (ex. 42)',
                    hintStyle: context.t.bodyLarge?.copyWith(color: c.labelTertiary),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        MtButton(label: 'Valider', onPressed: _valider),
        if (widget.initial != null) ...[
          const SizedBox(height: 10),
          MtButton(
            label: 'Retirer le passager',
            style: StyleBouton.discret,
            onPressed: () => Navigator.pop(context, 0),
          ),
        ],
      ],
    );
  }
}
