import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/resultat_controle_model.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/controllers/hors_ligne_controller.dart';
import 'package:malitrans_controleur_app/features/hors_ligne/presentation/widgets/hors_ligne_widgets.dart';
import 'package:malitrans_controleur_app/features/controle/presentation/pages/scanner_page.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/widgets/trajet_resume.dart';

/// Contrôle à bord : scan du QR (billet ou abonnement) sur le trajet courant.
class ControleQrScreen extends ConsumerStatefulWidget {
  final TrajetModel trajet;
  final VoidCallback? onVendreBilletTap;

  const ControleQrScreen({super.key, required this.trajet, this.onVendreBilletTap});

  @override
  ConsumerState<ControleQrScreen> createState() => _ControleQrScreenState();
}

class _ControleQrScreenState extends ConsumerState<ControleQrScreen> {
  final _codeController = TextEditingController();
  bool _enCours = false;
  ResultatControle? _resultat;
  String? _erreur;
  int _numeroControle = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanner() async {
    final valeur = await Navigator.of(context).push<String>(
      RouteDepuisLeBas(builder: (_) => const ScannerPage()),
    );
    if (valeur != null && mounted) await _controler(valeur);
  }

  Future<void> _controler(String brut) async {
    if (brut.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      // En ligne d'abord ; sans réseau, vérification locale (§7.3).
      final resultat = await ref.read(horsLigneProvider.notifier).controler(brut, widget.trajet);
      if (!mounted) return;
      // Verdict affiché et vibration sur la même frame.
      resultat.accepte ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
      setState(() {
        _resultat = resultat;
        _numeroControle++;
      });
      _codeController.clear();
      if (resultat.accepte && !resultat.horsLigne) {
        ref.read(trajetCourantProvider.notifier).rafraichir().catchError((_) {});
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _erreur = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final trajet = widget.trajet;

    return MtPage(
      titre: 'Contrôle',
      sousTitre: '${trajet.ligneNumero} · ${trajet.horaire}',
      avecBarreOnglets: true,
      actions: const [IndicateurSync(), SizedBox(width: 8)],
      children: [
        const SizedBox(height: 8),
        // Action principale : grande, en haut, atteignable au pouce.
        Pressable(
          onTap: _enCours ? null : _scanner,
          haptic: true,
          child: Container(
            height: 168,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: c.primaryFill, borderRadius: BorderRadius.circular(26)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Scanner', style: t.headlineMedium?.copyWith(color: c.onPrimaryFill)),
                      const SizedBox(height: 4),
                      Text(
                        'Billet ou abonnement',
                        style: t.bodyMedium?.copyWith(color: c.onPrimaryFill.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                _enCours
                    ? SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(strokeWidth: 3, color: c.onPrimaryFill),
                      )
                    : Icon(Icons.qr_code_scanner_rounded, size: 72, color: c.onPrimaryFill),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SaisieCode(
          controller: _codeController,
          enCours: _enCours,
          onValider: () => _controler(_codeController.text),
        ),
        if (_erreur != null) ...[const SizedBox(height: 16), MessageErreur(_erreur!)],
        if (_resultat != null) ...[
          const SizedBox(height: 16),
          SpringIn(
            key: ValueKey(_numeroControle),
            child: _CarteVerdict(
              resultat: _resultat!,
              onScannerSuivant: _scanner,
              onVendreBillet: widget.onVendreBilletTap,
            ),
          ),
        ],
        const TitreSection('Mon trajet'),
        Surface(child: TrajetResume(trajet: trajet)),
      ],
    );
  }
}

/// Champ de saisie manuelle, style « recherche ».
class _SaisieCode extends StatelessWidget {
  final TextEditingController controller;
  final bool enCours;
  final VoidCallback onValider;

  const _SaisieCode({required this.controller, required this.enCours, required this.onValider});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.keyboard_alt_outlined, color: c.labelSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              onSubmitted: enCours ? null : (_) => onValider(),
              style: context.t.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Saisir un code MLT-… ou PASS-…',
                hintStyle: context.t.bodyLarge?.copyWith(color: c.labelTertiary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, valeur, _) => AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: valeur.text.trim().isEmpty ? 0 : 1,
              child: Pressable(
                onTap: valeur.text.trim().isEmpty || enCours ? null : onValider,
                scale: 0.88,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: c.primaryFill, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.arrow_forward_rounded, color: c.onPrimaryFill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Verdict : lisible d'un coup d'œil (couleur, icône, mot).
class _CarteVerdict extends StatelessWidget {
  final ResultatControle resultat;
  final VoidCallback onScannerSuivant;
  final VoidCallback? onVendreBillet;

  const _CarteVerdict({required this.resultat, required this.onScannerSuivant, this.onVendreBillet});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    final couleur = resultat.accepte ? c.success : c.danger;

    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: couleur,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              children: [
                Icon(
                  resultat.accepte ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(resultat.verdict, style: t.headlineSmall?.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (resultat.horsLigne) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pastille('VÉRIFIÉ HORS LIGNE', couleur: c.warning),
                  ),
                  const SizedBox(height: 10),
                ],
                if (resultat.message.isNotEmpty)
                  Text(resultat.message, style: t.titleMedium),
                if (resultat.details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final (libelle, valeur) in resultat.details)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(libelle, style: t.bodyMedium?.copyWith(color: c.labelSecondary)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              valeur,
                              textAlign: TextAlign.end,
                              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                MtButton(label: 'Scanner le suivant', icone: Icons.qr_code_scanner_rounded, onPressed: onScannerSuivant),
                if (!resultat.accepte && onVendreBillet != null) ...[
                  const SizedBox(height: 10),
                  MtButton(
                    label: 'Vendre un billet',
                    icone: Icons.confirmation_number_outlined,
                    style: StyleBouton.teinte,
                    onPressed: onVendreBillet,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
