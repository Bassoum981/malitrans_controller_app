import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/motion.dart';

/// Matériau translucide : flou du contenu qui passe dessous.
/// Contraste élevé : surface pleine.
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color? teinte;

  const Glass({super.key, required this.child, this.borderRadius = BorderRadius.zero, this.teinte});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (context.highContrast) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(color: c.background, child: child),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(color: teinte ?? c.glass, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boutons
// ---------------------------------------------------------------------------

enum StyleBouton { principal, teinte, destructif, discret }

class MtButton extends StatelessWidget {
  final String label;
  final IconData? icone;
  final VoidCallback? onPressed;
  final StyleBouton style;
  final bool chargement;
  final double hauteur;

  const MtButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icone,
    this.style = StyleBouton.principal,
    this.chargement = false,
    this.hauteur = 54,
  });

  const MtButton.grand({
    super.key,
    required this.label,
    required this.onPressed,
    this.icone,
    this.style = StyleBouton.principal,
    this.chargement = false,
  }) : hauteur = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (fond, texte) = switch (style) {
      StyleBouton.principal => (c.primaryFill, c.onPrimaryFill),
      StyleBouton.teinte => (c.tint.withValues(alpha: 0.12), c.tint),
      StyleBouton.destructif => (c.danger, Colors.white),
      StyleBouton.discret => (c.surfaceSecondary, c.label),
    };

    return Pressable(
      onTap: chargement ? null : onPressed,
      child: Container(
        height: hauteur,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(16)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: chargement
              ? SizedBox(
                  key: const ValueKey('chargement'),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: texte),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icone != null) ...[
                      Icon(icone, color: texte, size: hauteur > 58 ? 24 : 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: context.t.labelLarge?.copyWith(
                          color: texte,
                          fontSize: hauteur > 58 ? 18 : 17,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bouton rond translucide (barres d'outils sur fond photo / caméra).
class BoutonRond extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? couleur;

  const BoutonRond({super.key, required this.icone, required this.onPressed, this.tooltip, this.couleur});

  @override
  Widget build(BuildContext context) {
    final bouton = Pressable(
      onTap: onPressed,
      scale: 0.9,
      child: Glass(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icone, size: 22, color: couleur ?? context.c.label),
        ),
      ),
    );
    return tooltip == null ? bouton : Tooltip(message: tooltip!, child: bouton);
  }
}

// ---------------------------------------------------------------------------
// Surfaces et listes groupées
// ---------------------------------------------------------------------------

/// Surface arrondie sans bordure : la hiérarchie vient du fond, pas des traits.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleur;

  const Surface({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: couleur ?? context.c.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

/// Titre de section au-dessus d'un groupe.
class TitreSection extends StatelessWidget {
  final String texte;

  const TitreSection(this.texte, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(texte.toUpperCase(), style: context.t.labelSmall),
    );
  }
}

/// Groupe de lignes (façon Réglages) séparées par des filets en retrait.
class Groupe extends StatelessWidget {
  final List<Widget> lignes;
  final String? pied;

  const Groupe({super.key, required this.lignes, this.pied});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enfants = <Widget>[];
    for (var i = 0; i < lignes.length; i++) {
      if (i > 0) {
        enfants.add(Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Container(height: 0.6, color: c.separator),
        ));
      }
      enfants.add(lignes[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(color: c.surface, child: Column(children: enfants)),
        ),
        if (pied != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(pied!, style: context.t.bodySmall),
          ),
      ],
    );
  }
}

/// Ligne de groupe : pastille d'icône, libellé, valeur et/ou chevron.
/// Mise en surbrillance immédiate au toucher.
class Ligne extends StatefulWidget {
  final IconData? icone;
  final Color? couleurIcone;
  final String libelle;
  final String? sousTitre;
  final String? valeur;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final bool destructive;

  const Ligne({
    super.key,
    required this.libelle,
    this.icone,
    this.couleurIcone,
    this.sousTitre,
    this.valeur,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.destructive = false,
  });

  @override
  State<Ligne> createState() => _LigneState();
}

class _LigneState extends State<Ligne> {
  bool _appuye = false;

  void _set(bool v) {
    if (widget.onTap != null && _appuye != v) setState(() => _appuye = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final couleurTexte = widget.destructive ? c.danger : c.label;
    final couleurIcone = widget.couleurIcone ?? (widget.destructive ? c.danger : c.tint);

    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _appuye ? 0 : 220),
          color: _appuye ? c.surfaceSecondary : c.surface,
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (widget.icone != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: couleurIcone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icone, size: 18, color: couleurIcone),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.libelle, style: context.t.bodyLarge?.copyWith(color: couleurTexte)),
                    if (widget.sousTitre != null)
                      Text(widget.sousTitre!, style: context.t.bodySmall),
                  ],
                ),
              ),
              if (widget.valeur != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    widget.valeur!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.bodyLarge?.copyWith(
                      color: c.labelSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
              if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
              if (widget.chevron) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: c.labelTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Statuts et messages
// ---------------------------------------------------------------------------

class Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;

  const Pastille(this.texte, {super.key, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texte,
        style: context.t.labelSmall?.copyWith(color: couleur, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}

/// Message d'erreur en ligne (apparaît avec un ressort).
class MessageErreur extends StatelessWidget {
  final String message;

  const MessageErreur(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SpringIn(
      key: ValueKey(message),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_rounded, color: c.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.t.bodyMedium?.copyWith(color: c.danger, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide / erreur pleine page, avec action.
class EtatVide extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? message;
  final String? action;
  final VoidCallback? onAction;

  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(icone, size: 48, color: c.labelTertiary),
          const SizedBox(height: 16),
          Text(titre, textAlign: TextAlign.center, style: context.t.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: context.t.bodySmall),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: 20),
            MtButton(label: action!, onPressed: onAction, style: StyleBouton.teinte, hauteur: 46),
          ],
        ],
      ),
    );
  }
}
