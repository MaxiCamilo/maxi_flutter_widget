import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Hacia dónde sale la primera cresta de la onda.
///
/// - [forward]: first se mete en second (derecha en horizontal, abajo en vertical).
/// - [backward]: second se mete en first.
enum WaveDirection { forward, backward }

/// Desde qué extremo del borde arrancan las ondas.
///
/// - [start]: arriba en horizontal, izquierda en vertical.
/// - [end]: abajo en horizontal, derecha en vertical.
enum WaveStart { start, end }

/// Cuál de los dos widgets queda arriba (y es el que se recorta).
enum WaveOverlap { first, second }

/// Dos widgets contiguos (lado a lado o uno sobre otro) separados por un borde
/// ondulado. No pinta ningún color: en la franja de 2 × [amplitude] píxeles
/// ambos widgets se superponen y el de arriba se recorta con la onda.
///
/// Necesita ancho y alto acotados (SizedBox, Expanded, etc.).
class WaveSplit extends StatelessWidget {
  const WaveSplit({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.amplitude = 20,
    this.waves = 1,
    this.wavelength,
    this.startFrom = WaveStart.start,
    this.direction = WaveDirection.forward,
    this.ratio = 0.5,
    this.firstExtent,
    this.secondExtent,
    this.overlap = WaveOverlap.second,
  });

  final Widget first;
  final Widget second;

  /// horizontal: first a la izquierda, second a la derecha.
  /// vertical: first arriba, second abajo.
  final Axis axis;

  /// Cuánto se aparta la onda de la línea central, hacia cada lado.
  /// La franja compartida mide 2 × amplitude.
  final double amplitude;

  /// Cantidad de ondas completas (cresta + valle). Usar múltiplos de 0.5
  /// (0.5 = una sola cresta) para que el borde termine sobre la línea central.
  final double waves;

  /// Largo de cada onda sobre el borde. Si es null, las [waves] ondas se
  /// reparten en todo el borde. Si se define y no llegan a cubrirlo, el resto
  /// del borde queda recto.
  final double? wavelength;

  /// Desde qué extremo del borde arrancan las ondas.
  final WaveStart startFrom;

  /// Hacia qué widget sale la primera cresta.
  final WaveDirection direction;

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

  final WaveOverlap overlap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = axis == Axis.horizontal;
        final extent =
            horizontal ? constraints.maxWidth : constraints.maxHeight;
        final amp = amplitude.clamp(0.0, extent / 2).toDouble();
        final band = amp * 2;
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
        final firstOnTop = overlap == WaveOverlap.first;

        Widget clip(Widget child, {required bool isFirst}) => ClipPath(
              clipper: _WaveClipper(
                axis: axis,
                amplitude: amp,
                waves: waves,
                wavelength: wavelength,
                startFrom: startFrom,
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

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper({
    required this.axis,
    required this.amplitude,
    required this.waves,
    required this.wavelength,
    required this.startFrom,
    required this.direction,
    required this.isFirst,
  });

  final Axis axis;
  final double amplitude;
  final double waves;
  final double? wavelength;
  final WaveStart startFrom;
  final WaveDirection direction;
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

    final hasWaves = waves > 0 && c > 0 && amplitude > 0;
    final wl = hasWaves ? (wavelength ?? c / waves) : 0.0;
    final covered = waves * wl; // tramo del borde que ocupa la onda
    final sign = direction == WaveDirection.forward ? 1.0 : -1.0;

    // Desplazamiento de la onda respecto a la línea central, en la posición
    // `s` del eje cruzado.
    double offsetAt(double s) {
      if (!hasWaves || wl <= 0) return 0;
      final u = startFrom == WaveStart.start ? s : c - s;
      if (u > covered) return 0; // tramo recto
      return sign * amplitude * math.sin(2 * math.pi * u / wl);
    }

    // Línea central de la franja, en coordenadas locales del widget.
    final center = isFirst ? m - amplitude : amplitude;

    // Un punto cada ~2 px alcanza para que la curva se vea suave.
    final steps = math.max(1, (c / 2).ceil());
    final edge = [
      for (var i = 0; i <= steps; i++)
        p(center + offsetAt(c * i / steps), c * i / steps),
    ];

    final points = isFirst
        ? [p(0, 0), ...edge, p(0, c)]
        : [...edge, p(m, c), p(m, 0)];

    return Path()..addPolygon(points, true);
  }

  @override
  bool shouldReclip(_WaveClipper old) =>
      old.axis != axis ||
      old.amplitude != amplitude ||
      old.waves != waves ||
      old.wavelength != wavelength ||
      old.startFrom != startFrom ||
      old.direction != direction ||
      old.isFirst != isFirst;
}
