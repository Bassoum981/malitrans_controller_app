import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/features/auth/data/models/controleur_model.dart';
import 'package:malitrans_controleur_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/pages/login_screen.dart';
import 'package:malitrans_controleur_app/features/billet_unique/presentation/pages/vente_billet_unique_screen.dart';
import 'package:malitrans_controleur_app/features/controle/presentation/pages/controle_qr_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaliTransControleurApp(),
    ),
  );
}

class MaliTransControleurApp extends StatelessWidget {
  const MaliTransControleurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaliTrans Contrôleur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ControleurGatePage(),
    );
  }
}

class ControleurGatePage extends ConsumerStatefulWidget {
  const ControleurGatePage({super.key});

  @override
  ConsumerState<ControleurGatePage> createState() => _ControleurGatePageState();
}

class _ControleurGatePageState extends ConsumerState<ControleurGatePage> {
  ControleurModel? _controleur;
  bool _isChecking = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  void _restore() {
    ref.read(authRepositoryProvider).restoreSession(
      onResult: (restored) {
        if (!mounted) return;
        setState(() {
          _controleur = restored;
          _isChecking = false;
        });
      },
    );
  }

  void _logout() {
    ref.read(authRepositoryProvider).logout(
      onDone: () {
        if (!mounted) return;
        setState(() {
          _controleur = null;
          _currentIndex = 0;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controleur == null) {
      return LoginScreen(
        onSuccess: (user) {
          setState(() {
            _controleur = user;
            _currentIndex = 0;
          });
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppTheme.slate400 : AppTheme.slate500;

    final pages = [
      ControleQrScreen(
        onVendreBilletTap: () => setState(() => _currentIndex = 1),
      ),
      VenteBilletUniqueScreen(controleur: _controleur!),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'MALI',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
            ),
            Text(
              'TRANS',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                letterSpacing: 1.1,
                color: mutedText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CONTRÔLE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.accentBlue : AppTheme.slate900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Contrôler',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Billet unique',
          ),
        ],
      ),
    );
  }
}