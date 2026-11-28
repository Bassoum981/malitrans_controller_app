import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malitrans_controleur_app/core/error/api_exception.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';
import 'package:malitrans_controleur_app/features/auth/presentation/controllers/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _masque = true;
  bool _chargement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // Message laissé par une expiration de session (403).
    _erreur = ref.read(messageConnexionProvider);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _valider() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Saisissez votre adresse email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return "Cette adresse email n'est pas valide.";
    }
    if (_passwordController.text.isEmpty) return 'Saisissez votre mot de passe.';
    return null;
  }

  Future<void> _connecter() async {
    final invalide = _valider();
    if (invalide != null) {
      HapticFeedback.heavyImpact();
      setState(() => _erreur = invalide);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(_emailController.text, _passwordController.text);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _erreur = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: c.primaryFill, borderRadius: BorderRadius.circular(20)),
                      child: Icon(Icons.directions_bus_rounded, size: 40, color: c.onPrimaryFill),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('MaliTrans Contrôle', textAlign: TextAlign.center, style: t.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour ouvrir votre service,\nvendre et contrôler à bord.',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: c.labelSecondary),
                  ),
                  const SizedBox(height: 36),
                  // Champs groupés dans une seule surface, séparés par un filet.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: c.surface,
                      child: Column(
                        children: [
                          _Champ(
                            controller: _emailController,
                            icone: Icons.mail_outline_rounded,
                            hint: 'Adresse email',
                            clavier: TextInputType.emailAddress,
                            action: TextInputAction.next,
                            autofill: const [AutofillHints.email],
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 52),
                            child: Container(height: 0.6, color: c.separator),
                          ),
                          _Champ(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            icone: Icons.lock_outline_rounded,
                            hint: 'Mot de passe',
                            masque: _masque,
                            action: TextInputAction.go,
                            autofill: const [AutofillHints.password],
                            onSubmitted: (_) => _connecter(),
                            suffixe: Pressable(
                              onTap: () => setState(() => _masque = !_masque),
                              scale: 0.85,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _masque ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: c.labelSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: _erreur == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(padding: const EdgeInsets.only(top: 16), child: MessageErreur(_erreur!)),
                  ),
                  const SizedBox(height: 24),
                  MtButton(label: 'Se connecter', chargement: _chargement, onPressed: _connecter),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Champ extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icone;
  final String hint;
  final bool masque;
  final TextInputType? clavier;
  final TextInputAction action;
  final Iterable<String> autofill;
  final ValueChanged<String> onSubmitted;
  final Widget? suffixe;

  const _Champ({
    required this.controller,
    required this.icone,
    required this.hint,
    required this.action,
    required this.autofill,
    required this.onSubmitted,
    this.focusNode,
    this.masque = false,
    this.clavier,
    this.suffixe,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icone, size: 22, color: c.labelSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: masque,
              keyboardType: clavier,
              textInputAction: action,
              autofillHints: autofill,
              autocorrect: false,
              enableSuggestions: !masque,
              onSubmitted: onSubmitted,
              style: context.t.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.t.bodyLarge?.copyWith(color: c.labelTertiary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          suffixe ?? const SizedBox(width: 16),
        ],
      ),
    );
  }
}
