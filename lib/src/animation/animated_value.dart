import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

typedef Lerp<T> = T Function(T a, T b, double t);

/// Petición de animación inmutable: destino, duración y curva capturados en el
/// momento de la llamada.
typedef AnimationRequest<T> = ({T target, Duration duration, Curve curve});

abstract final class Lerps {
  static double dbl(double a, double b, double t) => a + (b - a) * t;
  static int integer(int a, int b, double t) => (a + (b - a) * t).round();
  static Color color(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

// ─────────────────────────────────────────────────────────────────────────────
// Núcleo: pista + planificador con un único Ticker
// ─────────────────────────────────────────────────────────────────────────────

/// Estado plano de un valor animado. No tiene reloj propio: lo avanza un
/// [AnimationTrackScheduler]. Una pista pertenece a un solo planificador.
final class AnimationTrack<T> {
  AnimationTrack(this.lerp, T value) : _from = value, _to = value, _current = value;

  Lerp<T> lerp;

  T _from;
  T _to;
  T _current;
  int _startUs = 0;
  int _durationUs = 0;
  Curve _curve = Curves.linear;
  bool _active = false;

  T get initValue => _from;

  /// Valor interpolado en el último frame.
  T get current => _current;

  /// Destino actual.
  T get target => _to;

  bool get isAnimating => _active;

  bool accepts(Object? value) => value is T;

  void _retarget(T target, Duration duration, Curve curve, int startUs) {
    _from = _current; // arranca desde donde está, aunque esté a mitad de camino
    _to = target;
    _curve = curve;
    _durationUs = duration.inMicroseconds;
    _startUs = startUs;
  }

  /// Avanza al instante [nowUs]. Devuelve true si sigue animando.
  bool _advance(int nowUs) {
    if (_durationUs <= 0) {
      _current = _to;
      return false;
    }
    final t = (nowUs - _startUs) / _durationUs;
    if (t >= 1.0) {
      _current = _to; // final exacto, sin error de coma flotante
      return false;
    }
    _current = t <= 0.0 ? _from : lerp(_from, _to, _curve.transform(t));
    return true;
  }

  void _freeze() {
    _from = _current;
    _to = _current;
    _active = false;
  }
}

/// Avanza cualquier cantidad de [AnimationTrack] con un único [Ticker].
///
/// - El Ticker se crea recién en la primera animación (cero costo si nunca anima).
/// - Por frame solo recorre las pistas activas y llama a [onFrame] una vez.
/// - Se detiene solo cuando no queda nada animando.
/// - [animate] nunca notifica de forma síncrona: es seguro llamarlo desde `build`.
final class AnimationTrackScheduler with DisposableMixin {
  AnimationTrackScheduler({required TickerProvider vsync, required VoidCallback onFrame}) : _vsync = vsync, _onFrame = onFrame;

  final TickerProvider _vsync;
  final VoidCallback _onFrame;
  final List<AnimationTrack<Object?>> _active = [];

  Ticker? _ticker;
  int _nowUs = 0;

  bool get isAnimating => _active.isNotEmpty;

  /// Anima [track] hacia [target]. Si ya es su destino, no hace nada.
  void animate<T>(AnimationTrack<T> track, T target, Duration duration, Curve curve) {
    if (isDisposed || track._to == target) {
      return;
    }

    final ticker = _ticker ??= _vsync.createTicker(_tick);
    final running = ticker.isActive;

    // Con el ticker corriendo, la pista arranca en el tiempo del último frame;
    // si está detenido, Ticker.elapsed se reinicia a cero en start().
    track._retarget(target, duration, curve, running ? _nowUs : 0);

    if (!track._active) {
      track._active = true;
      _active.add(track);
    }

    if (!running) {
      _nowUs = 0;
      ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final nowUs = elapsed.inMicroseconds;
    _nowUs = nowUs;

    // Compactación en el lugar: sin listas nuevas por frame.
    final active = _active;
    var write = 0;
    for (var i = 0; i < active.length; i++) {
      final track = active[i];
      if (track._advance(nowUs)) {
        active[write++] = track;
      } else {
        track._active = false;
      }
    }
    active.length = write;

    _onFrame();

    // Se revisa después de onFrame: un listener pudo encadenar otra animación
    // o liberar el planificador.
    if (!isDisposed && _active.isEmpty) {
      _ticker!.stop();
    }
  }

  /// Detiene [track] en su valor actual. Si era la última pista activa,
  /// detiene el Ticker. No notifica: el valor visible no cambia.
  void stop<T>(AnimationTrack<T> track) {
    if (isDisposed || !track._active) {
      return;
    }
    track._freeze();
    _active.remove(track);
    if (_active.isEmpty) {
      _ticker?.stop();
    }
  }

  /// Detiene todas las pistas en su valor actual y el Ticker.
  /// No notifica: los valores visibles no cambian.
  void stopAll() {
    if (isDisposed || _active.isEmpty) {
      return;
    }
    for (final track in _active) {
      track._freeze();
    }
    _active.clear();
    _ticker?.stop();
  }

  @override
  void performDisposal() {
    for (final track in _active) {
      track._active = false;
    }
    _active.clear();
    _ticker?.dispose();
    _ticker = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller + widget para un valor suelto
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedValueController<T> with DisposableMixin, WithLifecycleScopeMixin {
  final Lerp<T> lerp;
  final List<void Function(AnimationRequest<T> request)> _listeners = [];

  T _value;
  final Duration _duration;
  final Curve _curve;

  /// Último valor destino solicitado.
  T get value => _value;

  /// Duración por defecto. Los overrides de [animateTo] NO la modifican.
  Duration get duration => _duration;

  /// Curva por defecto. Los overrides de [animateTo] NO la modifican.
  Curve get curve => _curve;

  Type get typeValue => T;

  new({required this._value, required this._duration, required this.lerp, Curve? curve}) : _curve = curve ?? Curves.linear {
    heart.onDispose(() {
      _listeners.clear();
    });
  }

  bool accepts(Object? value) => value is T;

  /// Los listeners se llaman de forma SÍNCRONA y no deben hacer setState en
  /// el momento (pueden estar dentro de `build`); [AnimatedValueWidget] solo
  /// redirige la petición a su Ticker.
  void addListener(void Function(AnimationRequest<T> request) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AnimationRequest<T> request) listener) {
    _listeners.remove(listener);
  }

  /// Anima hacia [target]. [duration] y [curve] aplican solo a esta animación.
  /// Si [target] ya es el destino, no hace nada.
  void animateTo(T target, {Duration? duration, Curve? curve}) {
    if (isDisposed || target == _value) {
      return;
    }
    _value = target;

    final listeners = _listeners;
    if (listeners.isEmpty) {
      return;
    }
    final AnimationRequest<T> request = (target: target, duration: duration ?? _duration, curve: curve ?? _curve);
    if (listeners.length == 1) {
      listeners[0](request);
      return;
    }
    for (final listener in List.of(listeners)) {
      listener(request);
    }
  }
}

class AnimatedValueWidget<T> extends StatefulWidget {
  const AnimatedValueWidget({
    super.key,
    required this.controller,
    required this.builder,
  });

  final AnimatedValueController<T> controller;

  final Widget Function(BuildContext context, T value) builder;

  @override
  State<AnimatedValueWidget<T>> createState() => _AnimatedValueState<T>();
}

class _AnimatedValueState<T> extends State<AnimatedValueWidget<T>> with SingleTickerProviderStateMixin {
  late final AnimationTrackScheduler _scheduler = AnimationTrackScheduler(vsync: this, onFrame: _onFrame);
  late final AnimationTrack<T> _track;

  static void _noop() {}

  void _onFrame() => setState(_noop);

  void _onRequest(AnimationRequest<T> request) {
    _scheduler.animate(_track, request.target, request.duration, request.curve);
  }

  @override
  void initState() {
    super.initState();
    _track = AnimationTrack<T>(widget.controller.lerp, widget.controller.value);
    widget.controller.addListener(_onRequest);
  }

  @override
  void didUpdateWidget(AnimatedValueWidget<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onRequest);
      final controller = widget.controller;
      controller.addListener(_onRequest);
      _track.lerp = controller.lerp;
      _scheduler.animate(_track, controller.value, controller.duration, controller.curve);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onRequest);
    _scheduler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _track.current);
}

class AnimatedDoubleController extends AnimatedValueController<double> {
  new({
    required super.value,
    required super.duration,
    super.curve,
  }) : super(
         lerp: Lerps.dbl,
       );
}

class AnimatedIntController extends AnimatedValueController<int> {
  new({
    required super.value,
    required super.duration,
    super.curve,
  }) : super(
         lerp: Lerps.integer,
       );
}

class AnimatedColorController extends AnimatedValueController<Color> {
  new({
    required super.value,
    required super.duration,
    super.curve,
  }) : super(
         lerp: Lerps.color,
       );
}
