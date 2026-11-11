import 'package:flutter/widgets.dart';

/// Hacia dónde apunta la punta del separador.
///
/// - [forward]: first se mete en second  → ">" en horizontal, "v" en vertical.
/// - [backward]: second se mete en first → "<" en horizontal, "^" en vertical.
enum ChevronDirection { forward, backward }

/// Cuál de los dos widgets queda arriba (y es el que se recorta).
enum ChevronOverlap { first, second }

/// Dos widgets contiguos (lado a lado o uno sobre otro) separados por una
/// punta de flecha. No pinta ningún color: en la franja de [space] píxeles
/// ambos widgets se superponen y el de arriba se recorta con la forma.
///
/// Necesita ancho y alto acotados (SizedBox, Expanded, etc.).
class ChevronSplit extends StatelessWidget {
  const ChevronSplit({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.space = 60,
    this.ratio = 0.5,
    this.firstExtent,
    this.secondExtent,
    this.tipPosition = 0.5,
    this.direction = ChevronDirection.forward,
    this.overlap = ChevronOverlap.second,
  });

  final Widget first;
  final Widget second;

  /// horizontal: first a la izquierda, second a la derecha.
  /// vertical: first arriba, second abajo.
  final Axis axis;

  /// Profundidad de la punta sobre el eje principal
  /// (ancho en horizontal, alto en vertical).
  final double space;

  /// Reparto del espacio restante: 0.5 = mitad y mitad, 0.3 = first más chico.
  final double ratio;

  /// Tamaño fijo de first sobre el eje principal (franja incluida).
  /// Si se define, reemplaza a [ratio] y second ocupa el resto. Si no entra,
  /// se limita al espacio disponible (funciona como máximo).
  final double? firstExtent;

  /// Igual que [firstExtent] pero para second: tamaño fijo (máximo) de
  /// second, franja incluida, y first ocupa el resto. Si se definen los dos,
  /// gana [firstExtent].
  final double? secondExtent;

  /// Posición de la punta sobre el eje cruzado: 0.5 = centrada,
  /// 0 = arriba/izquierda, 1 = abajo/derecha (ahí degenera en una diagonal).
  final double tipPosition;

  final ChevronDirection direction;
  final ChevronOverlap overlap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = axis == Axis.horizontal;
        final extent =
            horizontal ? constraints.maxWidth : constraints.maxHeight;
        final band = space.clamp(0.0, extent).toDouble();
        final fixedFirst = firstExtent;
        final fixedSecond = secondExtent;
        final double bandStart;
        if (fixedFirst != null) {
          bandStart = fixedFirst.clamp(band, extent).toDouble() - band;
        } else if (fixedSecond != null) {
          bandStart = extent - fixedSecond.clamp(band, extent).toDouble();
        } else {
          bandStart = (extent - band) * ratio.clamp(0.0, 1.0);
        }
        final bandEnd = bandStart + band;
        final firstOnTop = overlap == ChevronOverlap.first;

        Widget clip(Widget child, {required bool isFirst}) => ClipPath(
              clipper: _ChevronClipper(
                axis: axis,
                space: band,
                tipPosition: tipPosition.clamp(0.0, 1.0).toDouble(),
                direction: direction,
                isFirst: isFirst,
              ),
              child: child,
            );

        final firstChild = firstOnTop ? clip(first, isFirst: true) : first;
        final secondChild = firstOnTop ? second : clip(second, isFirst: false);

        // first ocupa [0, bandEnd], second ocupa [bandStart, extent]:
        // se pisan exactamente en la franja.
        final a = horizontal
            ? Positioned(
                left: 0, top: 0, bottom: 0, width: bandEnd, child: firstChild)
            : Positioned(
                left: 0, top: 0, right: 0, height: bandEnd, child: firstChild);
        final b = horizontal
            ? Positioned(
                left: bandStart, top: 0, bottom: 0, right: 0, child: secondChild)
            : Positioned(
                left: 0, top: bandStart, right: 0, bottom: 0, child: secondChild);

        return Stack(children: firstOnTop ? [b, a] : [a, b]);
      },
    );
  }
}

class _ChevronClipper extends CustomClipper<Path> {
  const _ChevronClipper({
    required this.axis,
    required this.space,
    required this.tipPosition,
    required this.direction,
    required this.isFirst,
  });

  final Axis axis;
  final double space;
  final double tipPosition;
  final ChevronDirection direction;
  final bool isFirst;

  @override
  Path getClip(Size size) {
    final horizontal = axis == Axis.horizontal;
    // m = extensión sobre el eje principal, c = sobre el eje cruzado.
    final m = horizontal ? size.width : size.height;
    final c = horizontal ? size.height : size.width;
    // (principal, cruzado) -> coordenadas reales; en vertical se transpone.
    Offset p(double main, double cross) =>
        horizontal ? Offset(main, cross) : Offset(cross, main);

    final t = c * tipPosition;
    final forward = direction == ChevronDirection.forward;

    final points = isFirst
        // La franja son los últimos `space` px del widget.
        ? [
            p(0, 0),
            p(forward ? m - space : m, 0),
            p(forward ? m : m - space, t), // punta
            p(forward ? m - space : m, c),
            p(0, c),
          ]
        // La franja son los primeros `space` px del widget.
        : [
            p(forward ? 0 : space, 0),
            p(m, 0),
            p(m, c),
            p(forward ? 0 : space, c),
            p(forward ? space : 0, t), // punta
          ];

    return Path()..addPolygon(points, true);
  }

  @override
  bool shouldReclip(_ChevronClipper old) =>
      old.axis != axis ||
      old.space != space ||
      old.tipPosition != tipPosition ||
      old.direction != direction ||
      old.isFirst != isFirst;
}
