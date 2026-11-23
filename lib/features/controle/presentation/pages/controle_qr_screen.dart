import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/features/controle/data/models/titre_controle_model.dart';
import 'package:malitrans_controleur_app/features/controle/domain/repositories/controle_repository.dart';

class ControleQrScreen extends ConsumerStatefulWidget {
  final VoidCallback? onVendreBilletTap;

  const ControleQrScreen({
    super.key,
    this.onVendreBilletTap,
  });

  @override
  ConsumerState<ControleQrScreen> createState() => _ControleQrScreenState();
}

class _ControleQrScreenState extends ConsumerState<ControleQrScreen> {
  final _codeController = TextEditingController();
  bool _isChecking = false;
  TitreControleModel? _resultat;
  String? _erreur;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _formatFcfa(num montant) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return '${fmt.format(montant.round()).replaceAll(',', ' ')} FCFA';
  }

  Future<void> _verifier() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _erreur = 'Saisissez ou scannez le code du titre.';
        _resultat = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _erreur = null;
      _resultat = null;
    });

    try {
      final titre =
      await ref.read(controleRepositoryProvider).verifierCodeTitre(code);
      if (!mounted) return;
      setState(() {
        _resultat = titre;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.navy800 : AppTheme.slate200;
    final cardBg = isDark ? AppTheme.navy900 : Colors.white;
    final mutedText = isDark ? AppTheme.slate400 : AppTheme.slate500;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Contrôle de titre à bord',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrez le code du passager (ex: PASS-2026-XXXXXXXX) pour vérifier sa validité.',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _verifier(),
                decoration: InputDecoration(
                  hintText: 'PASS-2026-...',
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  suffixIcon: _codeController.text.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _codeController.clear();
                      setState(() {
                        _resultat = null;
                        _erreur = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                  )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isChecking ? null : _verifier,
                child: _isChecking
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Vérifier le titre'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_erreur != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.red600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border:
              Border.all(color: AppTheme.red600.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: AppTheme.red600),
                    SizedBox(width: 8),
                    Text(
                      'TITRE NON VALIDE',
                      style: TextStyle(
                        color: AppTheme.red600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _erreur!,
                  style: const TextStyle(fontSize: 13),
                ),
                if (widget.onVendreBilletTap != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: widget.onVendreBilletTap,
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Vendre un billet à usage unique'),
                  ),
                ],
              ],
            ),
          ),
        if (_resultat != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _resultat!.valideActuellement
                    ? AppTheme.emerald600.withValues(alpha: 0.6)
                    : AppTheme.red600.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _resultat!.valideActuellement
                          ? 'ACCÈS AUTORISÉ'
                          : 'TITRE INACTIF',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _resultat!.valideActuellement
                            ? AppTheme.emerald600
                            : AppTheme.red600,
                      ),
                    ),
                    Text(
                      _resultat!.statut,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _resultat!.codeTitre,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Passager : ${_resultat!.passagerNomComplet ?? "Non renseigné"}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Expiration : ${_resultat!.dateFinFormatee}',
                  style: TextStyle(fontSize: 13, color: mutedText),
                ),
                const SizedBox(height: 6),
                Text(
                  'Montant payé : ${_formatFcfa(_resultat!.montantPaye)}',
                  style: TextStyle(fontSize: 13, color: mutedText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}