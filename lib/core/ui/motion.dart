import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';

/// Ressorts exprimés comme chez Apple : amortissement + temps de réponse.
/// `dampingRatio` 1.0 = aucun rebond ; `response` en secondes (≠ durée).
class MtSpring {
  MtSpring._();

  static SpringDescription of({double dampingRatio = 1.0, double response = 0.35}) {
    final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
    return SpringDescription.withDampingRatio(mass: 1, stiffness: stiffness, ratio: dampingRatio);
  }

  /// Défaut de l'interface : critique, sans rebond.
  static final standard = of();

  /// Retour d'un appui : vif.
  static final snappy = of(response: 0.25);
}

/// Retour d'appui immédiat : l'élément se contracte dès que le doigt se pose
/// (pas au relâchement), puis revient par un ressort qui part de sa valeur
/// courante — interruptible à tout moment.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = false,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);

  bool get _actif => widget.onTap != null;

  void _enfoncer() {
    if (!_actif) return;
    _c.animateTo(1, duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _relacher() {
    // Part de la valeur et de la vitesse courantes : aucune discontinuité.
    _c.animateWith(SpringSimulation(MtSpring.snappy, _c.value, 0, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _enfoncer(),
      onPointerUp: (_) => _relacher(),
      onPointerCancel: (_) => _relacher(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapCancel: _relacher,
        onTap: !_actif
            ? null
            : () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.scale(
            scale: 1 - (1 - widget.scale) * _c.value,
            child: child,
          ),
          child: Opacity(opacity: _actif ? 1 : 0.45, child: widget.child),
        ),
      ),
    );
  }
}

/// Fait apparaître son enfant avec un ressort (opacité + léger déplacement).
/// Changer la `key` rejoue l'apparition. Animations réduites : simple fondu.
class SpringIn extends StatefulWidget {
  final Widget child;
  final double offsetY;

  const SpringIn({super.key, required this.child, this.offsetY = 12});

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.reduceMotion) {
        _c.animateTo(1, duration: const Duration(milliseconds: 150));
      } else {
        _c.animateWith(SpringSimulation(MtSpring.standard, 0, 1, 0));
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduit = context.reduceMotion;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: reduit
              ? child
              : Transform.translate(
                  offset: Offset(0, (1 - v) * widget.offsetY),
                  child: Transform.scale(scale: 0.98 + 0.02 * v, child: child),
                ),
        );
      },
      child: widget.child,
    );
  }
}

/// Écran qui monte depuis le bas et redescend par le même chemin
/// (cohérence spatiale), courbes miroir à l'aller et au retour.
class RouteDepuisLeBas<T> extends PageRouteBuilder<T> {
  RouteDepuisLeBas({required WidgetBuilder builder, super.fullscreenDialog = true})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            if (context.reduceMotion) {
              return FadeTransition(opacity: animation, child: child);
            }
            final courbe = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic.flipped,
            );
            return SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(courbe),
              child: child,
            );
          },
        );
}
