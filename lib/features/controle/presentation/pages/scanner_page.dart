import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malitrans_controleur_app/core/theme/app_theme.dart';
import 'package:malitrans_controleur_app/core/ui/components.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scan caméra plein écran : renvoie (pop) le contenu du premier QR lu.
/// Ouvert depuis le bas (RouteDepuisLeBas), il se referme par le même chemin.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _lu = false;
  bool _lampe = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_lu) return;
    for (final code in capture.barcodes) {
      final valeur = code.rawValue;
      if (valeur != null && valeur.isNotEmpty) {
        // Image (cadre vert) et vibration sur la même frame.
        HapticFeedback.mediumImpact();
        setState(() => _lu = true);
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) Navigator.of(context).pop(valeur);
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final teinteVerre = Colors.black.withValues(alpha: 0.35);

    return Theme(
      // Interface toujours sombre au-dessus de la caméra.
      data: AppTheme.darkTheme,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Center(
                  child: EtatVide(
                    icone: Icons.no_photography_outlined,
                    titre: error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Accès à la caméra refusé'
                        : 'Caméra indisponible',
                    message: error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Autorisez la caméra dans les réglages du téléphone, ou saisissez le code à la main.'
                        : error.errorCode.name,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, contraintes) {
                  final cote = (contraintes.maxWidth * 0.68).clamp(200.0, 300.0);
                  final fenetre = Rect.fromCenter(
                    center: Offset(contraintes.maxWidth / 2, contraintes.maxHeight * 0.45),
                    width: cote,
                    height: cote,
                  );
                  return TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: _lu ? c.success : Colors.white),
                    duration: const Duration(milliseconds: 120),
                    builder: (context, couleur, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _CadreVisee(fenetre: fenetre, couleur: couleur ?? Colors.white),
                    ),
                  );
                },
              ),
              // Barre du haut : fermer (à gauche), lampe et caméra (à droite).
              Positioned(
                top: haut + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    BoutonRond(
                      icone: Icons.close_rounded,
                      tooltip: 'Fermer',
                      couleur: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    BoutonRond(
                      icone: _lampe ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                      tooltip: 'Lampe',
                      couleur: _lampe ? AppTheme.amber500 : Colors.white,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _controller.toggleTorch();
                        setState(() => _lampe = !_lampe);
                      },
                    ),
                    const SizedBox(width: 12),
                    BoutonRond(
                      icone: Icons.cameraswitch_rounded,
                      tooltip: 'Changer de caméra',
                      couleur: Colors.white,
                      onPressed: () => _controller.switchCamera(),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: bas + 32,
                child: Center(
                  child: Glass(
                    teinte: teinteVerre,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text(
                        _lu ? 'QR code lu' : 'Visez le QR code du billet ou de l’abonnement',
                        textAlign: TextAlign.center,
                        style: context.t.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
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

/// Assombrit tout sauf la fenêtre de visée, et dessine ses coins.
class _CadreVisee extends CustomPainter {
  final Rect fenetre;
  final Color couleur;

  _CadreVisee({required this.fenetre, required this.couleur});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(fenetre, const Radius.circular(28));
    final voile = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(voile, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final trait = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const l = 52.0; // longueur de chaque branche de coin
    const r = 28.0;
    final f = fenetre;
    for (final (coin, dx, dy) in [
      (f.topLeft, 1.0, 1.0),
      (f.topRight, -1.0, 1.0),
      (f.bottomLeft, 1.0, -1.0),
      (f.bottomRight, -1.0, -1.0),
    ]) {
      final p = Path()
        ..moveTo(coin.dx, coin.dy + dy * (r + l - r))
        ..lineTo(coin.dx, coin.dy + dy * r)
        ..arcToPoint(
          Offset(coin.dx + dx * r, coin.dy),
          radius: const Radius.circular(r),
          clockwise: dx * dy > 0,
        )
        ..lineTo(coin.dx + dx * (l), coin.dy);
      canvas.drawPath(p, trait);
    }
  }

  @override
  bool shouldRepaint(covariant _CadreVisee old) => old.fenetre != fenetre || old.couleur != couleur;
}
