import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';

/// Hauteur réservée en bas des pages pour la barre d'onglets flottante.
const double hauteurBarreOnglets = 84;

/// Page à grand titre : le titre se replie dans une barre compacte
/// translucide quand le contenu défile dessous ; rebond aux bords ;
/// « tirer pour actualiser » optionnel.
class MtPage extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final bool avecBarreOnglets;

  const MtPage({
    super.key,
    required this.titre,
    required this.children,
    this.sousTitre,
    this.leading,
    this.actions = const [],
    this.onRefresh,
    this.avecBarreOnglets = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final bas = padding.bottom + (avecBarreOnglets ? hauteurBarreOnglets : 0) + 24;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _EnTeteGrandTitre(
            titre: titre,
            sousTitre: sousTitre,
            leading: leading,
            actions: actions,
            haut: padding.top,
            couleurs: context.c,
            textes: context.t,
            contrasteEleve: context.highContrast,
          ),
        ),
        if (onRefresh != null) CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, bas),
          sliver: SliverList.list(children: children),
        ),
      ],
    );
  }
}

class _EnTeteGrandTitre extends SliverPersistentHeaderDelegate {
  final String titre;
  final String? sousTitre;
  final Widget? leading;
  final List<Widget> actions;
  final double haut;
  final MtColors couleurs;
  final TextTheme textes;
  final bool contrasteEleve;

  static const _barre = 52.0;

  _EnTeteGrandTitre({
    required this.titre,
    required this.sousTitre,
    required this.leading,
    required this.actions,
    required this.haut,
    required this.couleurs,
    required this.textes,
    required this.contrasteEleve,
  });

  double get _zoneTitre => 52 + (sousTitre != null ? 24 : 0);

  @override
  double get minExtent => haut + _barre;

  @override
  double get maxExtent => haut + _barre + _zoneTitre;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / _zoneTitre).clamp(0.0, 1.0);
    final opaciteCompacte = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    final opaciteGrande = (1 - t * 1.6).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Matériau : n'apparaît que lorsque le contenu passe dessous
        // (effet de bord de défilement plutôt qu'un filet permanent).
        if (t > 0)
          ClipRect(
            child: contrasteEleve
                ? ColoredBox(color: couleurs.background.withValues(alpha: t))
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24 * t, sigmaY: 24 * t),
                    child: ColoredBox(color: couleurs.glass.withValues(alpha: couleurs.glass.a * t)),
                  ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(height: 0.5, color: couleurs.separator.withValues(alpha: opaciteCompacte)),
        ),
        // Barre compacte
        Positioned(
          top: haut,
          left: 8,
          right: 8,
          height: _barre,
          child: Row(
            children: [
              SizedBox(width: 48, child: leading),
              Expanded(
                child: Opacity(
                  opacity: opaciteCompacte,
                  child: Text(titre, textAlign: TextAlign.center, style: textes.titleMedium),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ),
            ],
          ),
        ),
        // Grand titre
        Positioned(
          left: 20,
          right: 20,
          bottom: 10,
          child: Opacity(
            opacity: opaciteGrande,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis, style: textes.headlineMedium),
                if (sousTitre != null)
                  Text(sousTitre!, maxLines: 1, overflow: TextOverflow.ellipsis, style: textes.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _EnTeteGrandTitre old) =>
      old.titre != titre ||
      old.sousTitre != sousTitre ||
      old.haut != haut ||
      old.couleurs != couleurs ||
      old.actions != actions ||
      old.leading != leading;
}

/// Bouton d'icône de barre (teinté, retour d'appui).
class BoutonBarre extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onPressed;
  final String tooltip;

  const BoutonBarre({super.key, required this.icone, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        scale: 0.85,
        child: SizedBox(width: 44, height: 44, child: Icon(icone, color: context.c.tint, size: 26)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feuilles (bottom sheets) : montent depuis le bas, se ferment en glissant.
// ---------------------------------------------------------------------------

Future<T?> afficherFeuille<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => _CadreFeuille(child: builder(ctx)),
  );
}

class _CadreFeuille extends StatelessWidget {
  final Widget child;

  const _CadreFeuille({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(color: c.labelTertiary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation d'une action importante, en feuille depuis le bas.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String action,
  String? message,
  Widget? contenu,
  bool destructif = false,
}) async {
  final ok = await afficherFeuille<bool>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titre, style: ctx.t.titleLarge),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message, style: ctx.t.bodyMedium?.copyWith(color: ctx.c.labelSecondary)),
        ],
        if (contenu != null) ...[const SizedBox(height: 20), contenu],
        const SizedBox(height: 24),
        MtButton(
          label: action,
          style: destructif ? StyleBouton.destructif : StyleBouton.principal,
          onPressed: () => Navigator.pop(ctx, true),
        ),
        const SizedBox(height: 10),
        MtButton(label: 'Annuler', style: StyleBouton.discret, onPressed: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  return ok == true;
}
