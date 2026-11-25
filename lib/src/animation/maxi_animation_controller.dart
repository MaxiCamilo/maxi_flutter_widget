import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

// ============================================================================
// Interpolaciones
// ============================================================================

/// Interpolación sin tipo: las pistas castean internamente.
typedef _ErasedLerp = Object Function(Object a, Object b, double t);

/// Registro global de interpolaciones por tipo.
///
/// Los tipos sin lerp registrado (bool, String, enums...) no se animan:
/// cambian de golpe en el siguiente frame.
abstract final class MaxiLerp {
  static final Map<Type, _ErasedLerp> _registry = <Type, _ErasedLerp>{
    double: (a, b, t) => lerpDouble(a as double, b as double, t)!,
    int: (a, b, t) {
      final ai = a as int;
      final bi = b as int;
      return (ai + (bi - ai) * t).round();
    },
    Color: (a, b, t) => Color.lerp(a as Color, b as Color, t)!,
    Offset: (a, b, t) => Offset.lerp(a as Offset, b as Offset, t)!,
    Size: (a, b, t) => Size.lerp(a as Size, b as Size, t)!,
    Rect: (a, b, t) => Rect.lerp(a as Rect, b as Rect, t)!,
    Alignment: (a, b, t) => Alignment.lerp(a as Alignment, b as Alignment, t)!,
    EdgeInsets: (a, b, t) => EdgeInsets.lerp(a as EdgeInsets, b as EdgeInsets, t)!,
    BorderRadius: (a, b, t) => BorderRadius.lerp(a as BorderRadius, b as BorderRadius, t)!,
    AlignmentGeometry: (a, b, t) => AlignmentGeometry.lerp(a as AlignmentGeometry, b as AlignmentGeometry, t)!,
  };

  /// Registra (o reemplaza) la interpolación de un tipo propio.
  ///
  /// ```dart
  /// MaxiLerp.register<BoxShadow>((a, b, t) => BoxShadow.lerp(a, b, t)!);
  /// ```
  static void register<T extends Object>(T Function(T a, T b, double t) lerp) {
    _registry[T] = (a, b, t) => lerp(a as T, b as T, t);
  }

  static _ErasedLerp? _of<T>() => _registry[T];
}

/// Convierte [value] a [T]. Tolera int <-> double (un `set('h', 300)` sobre
/// una clave escuchada como double no debe romper).
T _coerce<T extends Object>(Object value, Object key) {
  if (value is T) {
    return value;
  }
  if (value is num) {
    if (T == double) {
      return value.toDouble() as T;
    }
    if (T == int) {
      return value.round() as T;
    }
  }
  throw StateError('MaxiAnimation: la clave "$key" contiene ${value.runtimeType}, pero se pidió $T.');
}

// ============================================================================
// Controlador de valores
// ============================================================================

abstract interface class _KeyObserver {
  void _onKeyChanged(Object key, Object value, Duration? duration, Curve? curve);
}

/// Almacén de valores destino por clave. NO anima nada: solo guarda el valor
/// final y avisa a quien esté escuchando esa clave en particular.
///
/// - `set` sobre una clave sin oyentes = una escritura en un Map, nada más.
/// - Solo se notifica a los contenedores suscritos a ESA clave.
/// - No necesita TickerProvider: se puede crear en cualquier lado
///   (State, servicio, gestor de estado...).
class MaxiAnimationController with DisposableMixin, WithLifecycleScopeMixin {
  MaxiAnimationController({Map<Object, Object>? initialValues, Map<Object, Object>? fixedValues}) {
    if (initialValues != null) {
      _values.addAll(initialValues);
    }
    if (fixedValues != null) {
      _values.addAll(fixedValues);
      _fixed.addAll(fixedValues.keys);
    }
  }

  final Map<Object, Object> _values = <Object, Object>{};
  final Map<Object, Set<_KeyObserver>> _observers = <Object, Set<_KeyObserver>>{};

  StreamController<(Object, Object)>? _changeListering;

  /// Claves que nunca se animan: un cambio solo reconstruye a quien las escucha.
  final Set<Object> _fixed = <Object>{};

  bool contains(Object key) => _values.containsKey(key);

  /// Valor destino actual (no el interpolado de algún contenedor).
  Object? operator [](Object key) => _values[key];

  T? get<T extends Object>(Object key) {
    final value = _values[key];
    return value == null ? null : _coerce<T>(value, key);
  }

  Stream<(Object, Object)> get onChange {
    _changeListering ??= heart.attachStreamController(StreamController<(Object, Object)>.broadcast());
    return _changeListering!.stream;
  }

  /// Indica si algún contenedor está escuchando [key] en este momento.
  bool isListened(Object key) => _observers.containsKey(key) || (_changeListering != null && _changeListering!.hasListener);

  /// Cambia el destino de [key]. Los contenedores que la escuchan animan
  /// desde su valor ACTUAL (aunque estén a mitad de una animación).
  ///
  /// [duration] y [curve] pisan los del contenedor solo para este cambio.
  void set(Object key, Object value, {Duration? duration, Curve? curve}) {
    assert(!isDisposed, 'MaxiAnimationController usado después de dispose().');
    if (_values[key] == value) {
      return;
    }
    _values[key] = value;
    _changeListering?.add((key, value));

    final observers = _observers[key];
    if (observers == null) {
      return;
    }
    // Una clave fija ignora cualquier duración: solo provoca el rebuild.
    if (_fixed.contains(key)) {
      duration = Duration.zero;
    }
    // _onKeyChanged nunca modifica _observers: se puede iterar directo.
    for (final observer in observers) {
      observer._onKeyChanged(key, value, duration, curve);
    }
  }

  /// Cambia el valor sin animación (solo esta vez; la clave sigue animable).
  void jump(Object key, Object value) => set(key, value, duration: Duration.zero);

  /// Marca [key] como fija y le asigna [value]. A partir de ahí, cualquier
  /// `set` sobre ella reconstruye a los contenedores que la escuchan, sin animar.
  void setFixed(Object key, Object value) {
    _fixed.add(key);
    set(key, value);
  }

  /// Indica si [key] está marcada como fija.
  bool isFixed(Object key) => _fixed.contains(key);

  /// Vuelve a hacer animable a [key]. El valor no cambia.
  void unfix(Object key) => _fixed.remove(key);

  /// Cambia varias claves juntas. Cada contenedor afectado se reconstruye
  /// una sola vez en el siguiente frame.
  void setAll(Map<Object, Object> values, {Duration? duration, Curve? curve}) {
    for (final entry in values.entries) {
      set(entry.key, entry.value, duration: duration, curve: curve);
    }
  }

  void triggerValue<T extends Object>(Object key, {Duration? duration, Curve? curve}) {
    final value = _values[key];
    if (value != null) {
      if (value is int) {
        set(key, value + 1, duration: duration, curve: curve);
      } else if (value is double) {
        set(key, value + 0.01, duration: duration, curve: curve);
      } else if (value is bool) {
        set(key, !value, duration: duration, curve: curve);
      } else if (value is String) {
        set(key, '$value ', duration: duration, curve: curve);
      }

      return;
    }

    if (T == int) {
      set(key, 1, duration: duration, curve: curve);
    } else if (T == double) {
      set(key, 0.01, duration: duration, curve: curve);
    } else if (T == bool) {
      set(key, false, duration: duration, curve: curve);
    } else if (T == String) {
      set(key, '', duration: duration, curve: curve);
    }
  }

  Object _readOrCreate(Object key, Object defaultValue) => _values.putIfAbsent(key, () => defaultValue);

  void _subscribe(Object key, _KeyObserver observer) {
    (_observers[key] ??= <_KeyObserver>{}).add(observer);
  }

  void _unsubscribe(Object key, _KeyObserver observer) {
    final set = _observers[key];
    if (set == null) {
      return;
    }
    set.remove(observer);
    if (set.isEmpty) {
      _observers.remove(key);
    }
  }

  @override
  void performDisposal() {
    super.performDisposal();

    _observers.clear();
  }
}

// ============================================================================
// Pista (estado de animación de una clave dentro de un contenedor)
// ============================================================================

/// Una pista no guarda "el valor actual": guarda desde dónde, hacia dónde y
/// cuándo. El valor se calcula a pedido con [sample] para un instante dado.
final class _Track<T extends Object> {
  _Track(this.key, T initial, this._lerp) : _from = initial, _to = initial;

  final Object key;
  final _ErasedLerp? _lerp;

  T _from;
  T _to;
  Curve _curve = Curves.linear;
  int _startUs = 0;
  int _durationUs = 0;

  /// Último build en el que el builder pidió esta clave.
  int epoch = 0;

  /// Leída con `anim.watch`: nunca interpola en este contenedor.
  bool fixed = false;

  /// Instante (en el reloj del contenedor) en que termina la animación.
  int get endUs => _startUs + _durationUs;

  /// Valor en el instante [nowUs]. Solo se llama desde `listen` (en el build).
  T sample(int nowUs) {
    if (_durationUs <= 0) {
      return _to;
    }
    final t = (nowUs - _startUs) / _durationUs;
    if (t >= 1.0) {
      return _to; // final exacto
    }
    if (t <= 0.0) {
      return _from;
    }
    return _lerp!(_from, _to, _curve.transform(t)) as T;
  }

  /// Nuevo destino partiendo del valor que tenía en [nowUs].
  /// Devuelve false si el destino no cambia.
  bool retarget(Object raw, int nowUs, Duration duration, Curve curve) {
    final target = _coerce<T>(raw, key);
    if (target == _to) {
      return false;
    }
    _from = sample(nowUs); // se congela donde está y sigue desde ahí
    _to = target;
    _curve = curve;
    _startUs = nowUs;
    _durationUs = (fixed || _lerp == null) ? 0 : duration.inMicroseconds;
    return true;
  }
}

// ============================================================================
// Contenedor animado
// ============================================================================

/// Acceso que recibe el builder.
final class MaxiAnim {
  MaxiAnim._(this._state);

  final _MaxiAnimationContainerState _state;

  /// Valor interpolado de [key] y suscripción a sus cambios.
  ///
  /// - Si la clave no existe en el controlador, se crea con [defaultValue].
  /// - Si en un build deja de pedirse, la suscripción se descarta sola.
  /// - Debe llamarse de forma síncrona dentro del builder (no dentro de un
  ///   LayoutBuilder/Builder hijo: leé el valor antes y pasalo).
  T listen<T extends Object>(Object key, T defaultValue) => _state._listen<T>(key, defaultValue, false);

  /// Como [listen], pero sin animar: devuelve el valor tal cual está en el
  /// controlador y, si cambia, solo reconstruye este contenedor.
  ///
  /// Útil para modos, textos, enums, flags... o para un número que en este
  /// contenedor querés que salte aunque en otro se anime.
  /// En un mismo contenedor usá una sola forma (listen o watch) por clave.
  T watch<T extends Object>(Object key, T defaultValue) => _state._listen<T>(key, defaultValue, true);

  MaxiAnimationController get controller => _state.widget.controller;

  bool get isAnimating => _state._clockUs < _state._endUs;

  bool isAnimatingKey(Object key) {
    final track = _state._tracks[key];
    return track != null && _state._clockUs < track.endUs;
  }

  void setValue(
    Object key,
    Object value, {
    Duration? duration,
    Curve? curve,
  }) => controller.set(key, value, duration: duration, curve: curve);

  void triggerValue<T extends Object>(
    Object key, {
    Duration? duration,
    Curve? curve,
  }) {
    controller.triggerValue<T>(key, duration: duration, curve: curve);
  }
}

class MaxiAnimationContainer extends StatefulWidget {
  const MaxiAnimationContainer({
    super.key,
    required this.controller,
    required this.builder,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
  });

  final MaxiAnimationController controller;
  final Widget Function(BuildContext context, MaxiAnim anim) builder;
  final Duration duration;
  final Curve curve;

  @override
  State<MaxiAnimationContainer> createState() => _MaxiAnimationContainerState();
}

class _MaxiAnimationContainerState extends State<MaxiAnimationContainer> with SingleTickerProviderStateMixin implements _KeyObserver {
  final Map<Object, _Track<Object>> _tracks = <Object, _Track<Object>>{};
  late final MaxiAnim _scope = MaxiAnim._(this);

  Ticker? _ticker;

  /// Reloj propio y monótono del contenedor (µs). Avanza solo mientras el
  /// Ticker corre; al detenerse se guarda en [_offsetUs] para que al
  /// reiniciar (Ticker.elapsed vuelve a 0) el tiempo nunca retroceda.
  int _clockUs = 0;
  int _offsetUs = 0;

  /// Fin de la animación más larga en curso. Si `_clockUs >= _endUs`,
  /// no hay nada que animar.
  int _endUs = 0;

  int _epoch = 0;
  bool _building = false;

  static void _noop() {}

  // --------------------------------------------------------------------------
  // Suscripción (durante build)
  // --------------------------------------------------------------------------

  T _listen<T extends Object>(Object key, T defaultValue, bool fixed) {
    assert(
      _building,
      'anim.listen/watch("$key") se llamó fuera del builder de MaxiAnimationContainer. '
      'Leé el valor en el builder y pasalo a los widgets hijos.',
    );

    var track = _tracks[key];
    if (track == null) {
      final initial = _coerce<T>(widget.controller._readOrCreate(key, defaultValue), key);
      // El lerp se guarda igual: si en otro build la clave pasa de watch a
      // listen (o al revés), la misma pista sirve para ambos modos.
      track = _Track<T>(key, initial, MaxiLerp._of<T>());
      _tracks[key] = track;
      widget.controller._subscribe(key, this);
    }
    track.fixed = fixed;
    track.epoch = _epoch;
    // El cálculo ocurre acá, en el build, y solo para lo que se pide.
    return _coerce<T>(track.sample(_clockUs), key);
  }

  /// Descarta las claves que el último build no pidió y recalcula el fin
  /// de animación con las que quedan (evita frames de más).
  void _sweep() {
    final epoch = _epoch;
    final controller = widget.controller;
    var endUs = 0;
    _tracks.removeWhere((key, track) {
      if (track.epoch == epoch) {
        if (track.endUs > endUs) {
          endUs = track.endUs;
        }
        return false;
      }
      controller._unsubscribe(key, this);
      return true;
    });
    _endUs = endUs;
    if (_clockUs >= _endUs) {
      _stopTicker();
    }
  }

  void _stopTicker() {
    final ticker = _ticker;
    if (ticker != null && ticker.isActive) {
      ticker.stop();
      _offsetUs = _clockUs;
    }
  }

  // --------------------------------------------------------------------------
  // Reacción a cambios del controlador
  // --------------------------------------------------------------------------

  /// Nunca llama a setState: solo reprograma la pista y arranca el Ticker.
  /// Por eso es seguro aunque el `set` ocurra durante el build de otro widget.
  @override
  void _onKeyChanged(Object key, Object value, Duration? duration, Curve? curve) {
    final track = _tracks[key];
    if (track == null) {
      return;
    }

    // La pista parte del valor que tenía en el último frame (o del valor
    // final, si el contenedor estaba quieto).
    if (!track.retarget(value, _clockUs, duration ?? widget.duration, curve ?? widget.curve)) {
      return;
    }

    if (track.endUs > _endUs) {
      _endUs = track.endUs;
    }

    // Se arranca aunque la duración sea cero: hace falta al menos un frame
    // para reconstruir con el valor nuevo.
    final ticker = _ticker ??= createTicker(_tick);
    if (!ticker.isActive) {
      ticker.start();
    }
  }

  /// O(1) por frame: no interpola nada, solo avanza el reloj y pide rebuild.
  void _tick(Duration elapsed) {
    _clockUs = _offsetUs + elapsed.inMicroseconds;
    if (_clockUs >= _endUs) {
      _stopTicker();
    }
    setState(_noop);
  }

  // --------------------------------------------------------------------------
  // Ciclo de vida
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _epoch++;
    _building = true;
    final Widget child;
    try {
      child = widget.builder(context, _scope);
    } finally {
      _building = false;
    }
    _sweep();
    return child;
  }

  @override
  void didUpdateWidget(covariant MaxiAnimationContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      // Las pistas se recrean en el build con los valores del controlador nuevo.
      _detachAll(oldWidget.controller);
    }
  }

  void _detachAll(MaxiAnimationController controller) {
    for (final key in _tracks.keys) {
      controller._unsubscribe(key, this);
    }
    _tracks.clear();
    _endUs = 0;
    _stopTicker();
  }

  @override
  void dispose() {
    _detachAll(widget.controller);
    _ticker?.dispose(); // antes de super.dispose(), o el mixin se queja
    super.dispose();
  }
}
