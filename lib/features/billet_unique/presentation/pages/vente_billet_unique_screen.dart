import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/printer/ticket_printer_service.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';
import 'package:malitrans_controleur_app/features/billet_unique/data/models/billet_unique_model.dart';
import 'package:malitrans_controleur_app/features/billet_unique/domain/repositories/billet_unique_repository.dart';

class VenteBilletUniqueScreen extends ConsumerStatefulWidget {
  final ControleurModel controleur;

  const VenteBilletUniqueScreen({
    super.key,
    required this.controleur,
  });

  @override
  ConsumerState<VenteBilletUniqueScreen> createState() =>
      _VenteBilletUniqueScreenState();
}

class _VenteBilletUniqueScreenState
    extends ConsumerState<VenteBilletUniqueScreen> {
  final _affectationController = TextEditingController(text: '1');
  final _referenceController = TextEditingController();
  String _modePaiement = 'ESPECES';
  bool _isSubmitting = false;
  String? _errorMessage;
  BilletUniqueModel? _billetEmis;

  static const _modes = ['ESPECES', 'ORANGE_MONEY', 'MOOV_MONEY'];

  @override
  void dispose() {
    _affectationController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _vendre() async {
    final affectationId = int.tryParse(_affectationController.text.trim());
    if (affectationId == null || affectationId <= 0) {
      setState(() {
        _errorMessage = "L'ID d'affectation est obligatoire.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final billet =
      await ref.read(billetUniqueRepositoryProvider).acheterBillet(
        affectationId: affectationId,
        modePaiement: _modePaiement,
        referencePaiement: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _billetEmis = billet;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
                'Billet ponctuel à bord',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Émission d’un billet sans compte passager via /api/billets/acheter.',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _affectationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID Affectation *',
                  prefixIcon: Icon(Icons.directions_bus_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _modePaiement,
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement *',
                ),
                items: _modes
                    .map(
                      (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.replaceAll('_', ' ')),
                  ),
                )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _modePaiement = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Référence paiement (optionnel)',
                  hintText: 'Ex: OM-2026-9988',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.red600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _vendre,
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Émettre le billet'),
              ),
            ],
          ),
        ),
        if (_billetEmis != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.emerald600.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BILLET ${_billetEmis!.statut}',
                  style: const TextStyle(
                    color: AppTheme.emerald600,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _billetEmis!.numeroBillet,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_billetEmis!.montantFormate} • ${_billetEmis!.modePaiement}',
                  style: TextStyle(fontSize: 13, color: mutedText),
                ),
                if (_billetEmis!.ligneNumero != null ||
                    _billetEmis!.busImmatriculation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ligne ${_billetEmis!.ligneNumero ?? '-'} • Bus ${_billetEmis!.busImmatriculation ?? '-'}',
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(ticketPrinterServiceProvider)
                      .printBilletUnique(context, _billetEmis!),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Aperçu / Imprimer le ticket'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}