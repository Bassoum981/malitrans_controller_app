import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/core/ui/page.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/pages/login_screen.dart';
import 'package:malitrans_controleur_app/features/billet_unique/presentation/pages/vente_billet_unique_screen.dart';
import 'package:malitrans_controleur_app/features/controle/presentation/pages/controle_qr_screen.dart';
import 'package:malitrans_controleur_app/features/service/data/models/service_receveur_model.dart';
import 'package:malitrans_controleur_app/features/service/presentation/controllers/service_controller.dart';
import 'package:malitrans_controleur_app/features/service/presentation/pages/mon_service_screen.dart';
import 'package:malitrans_controleur_app/features/service/presentation/pages/ouverture_service_screen.dart';
import 'package:malitrans_controleur_app/features/trajet/data/models/trajet_model.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/controllers/trajet_controller.dart';
import 'package:malitrans_controleur_app/features/trajet/presentation/pages/choix_trajet_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(
    ProviderScope(
      // Pas de nouvelle tentative automatique (Riverpod 3) : une erreur
      // s'affiche avec « Réessayer », et un 403 ne boucle pas.
      retry: (_, _) => null,
      child: const MaliTransControleurApp(),
    ),
  );
}

class MaliTransControleurApp extends StatelessWidget {
  const MaliTransControleurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaliTrans Contrôle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Dégradé doux entre clair et sombre plutôt qu'un saut de luminosité.
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: const ControleurGatePage(),
    );
  }
}

/// Parcours du receveur (docs/API.md §4.3) :
/// connexion → service ouvert → trajet choisi → contrôle / vente / service.
class ControleurGatePage extends ConsumerWidget {
  const ControleurGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    final Widget ecran = session.when(
      loading: () => const Scaffold(key: ValueKey('chargement'), body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(key: ValueKey('login')),
      data: (controleur) => controleur == null
          ? const LoginScreen(key: ValueKey('login'))
          : _EspaceControleur(key: const ValueKey('espace'), controleur: controleur),
    );

    return _Transition(child: ecran);
  }
}

class _EspaceControleur extends ConsumerWidget {
  final ControleurModel controleur;

  const _EspaceControleur({super.key, required this.controleur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(serviceEnCoursProvider);
    final trajet = ref.watch(trajetCourantProvider);

    final Widget corps = switch ((service, trajet)) {
      (AsyncError(:final error), _) => _Erreur(
          key: const ValueKey('erreur-service'),
          message: ApiException.from(error).message,
          onRelance: () => ref.invalidate(serviceEnCoursProvider),
        ),
      (AsyncData(value: null), _) =>
        OuvertureServiceScreen(key: const ValueKey('ouverture'), controleur: controleur),
      (_, AsyncError(:final error)) => _Erreur(
          key: const ValueKey('erreur-trajet'),
          message: ApiException.from(error).message,
          onRelance: () => ref.invalidate(trajetCourantProvider),
        ),
      (AsyncData(value: final ServiceReceveurModel s), AsyncData(value: final TrajetModel t)) =>
        _OngletsReceveur(key: const ValueKey('onglets'), service: s, trajet: t),
      (AsyncData(), AsyncData(value: null)) => const ChoixTrajetScreen(key: ValueKey('choix')),
      _ => const Center(key: ValueKey('attente'), child: CircularProgressIndicator()),
    };

    return Scaffold(body: _Transition(child: corps));
  }
}

/// Fondu enchaîné entre les étapes du parcours.
class _Transition extends StatelessWidget {
  final Widget child;

  const _Transition({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _Erreur extends StatelessWidget {
  final String message;
  final VoidCallback onRelance;

  const _Erreur({super.key, required this.message, required this.onRelance});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EtatVide(
        icone: Icons.wifi_off_rounded,
        titre: 'Connexion impossible',
        message: message,
        action: 'Réessayer',
        onAction: onRelance,
      ),
    );
  }
}

class _OngletsReceveur extends StatefulWidget {
  final ServiceReceveurModel service;
  final TrajetModel trajet;

  const _OngletsReceveur({super.key, required this.service, required this.trajet});

  @override
  State<_OngletsReceveur> createState() => _OngletsReceveurState();
}

class _OngletsReceveurState extends State<_OngletsReceveur> {
  int _index = 0;

  void _aller(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // IndexedStack : chaque onglet garde son état (dernier scan, dernier billet).
        IndexedStack(
          index: _index,
          children: [
            ControleQrScreen(trajet: widget.trajet, onVendreBilletTap: () => _aller(1)),
            VenteBilletUniqueScreen(trajet: widget.trajet),
            MonServiceScreen(service: widget.service, trajet: widget.trajet),
          ],
        ),
        // Barre d'onglets translucide : le contenu défile dessous.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BarreOnglets(
            index: _index,
            onChange: _aller,
            items: const [
              (Icons.qr_code_scanner_rounded, 'Contrôle'),
              (Icons.confirmation_number_rounded, 'Vente'),
              (Icons.account_balance_wallet_rounded, 'Service'),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarreOnglets extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final List<(IconData, String)> items;

  const _BarreOnglets({required this.index, required this.onChange, required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bas = MediaQuery.paddingOf(context).bottom;

    return Glass(
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.separator, width: 0.5))),
        padding: EdgeInsets.only(top: 6, bottom: bas > 0 ? bas : 8),
        height: hauteurBarreOnglets - 20 + (bas > 0 ? bas : 8),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Pressable(
                  onTap: () => onChange(i),
                  scale: 0.9,
                  child: _ItemOnglet(icone: items[i].$1, label: items[i].$2, actif: i == index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemOnglet extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool actif;

  const _ItemOnglet({required this.icone, required this.label, required this.actif});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final couleur = actif ? c.tint : c.labelSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icone, color: couleur, size: 26),
        const SizedBox(height: 3),
        Text(
          label,
          style: context.t.labelSmall?.copyWith(
            color: couleur,
            fontSize: 11,
            letterSpacing: 0.1,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
