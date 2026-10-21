import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

/// Coordina varios valores animados por key con UN solo Ticker.
///
/// - Sirve con `SingleTickerProviderStateMixin` (si el State no usa otro ticker).
/// - Todos los valores comparten la misma base de tiempo.
/// - Sin animaciones no crea Ticker ni consume nada por frame.
///
/// El dueño debe llamar a [dispose] en `State.dispose()` ANTES de `super.dispose()`.
class AnimationDirector with DisposableMixin, WithLifecycleScopeMixin {
  final Duration defaultDuration;
  final Curve defaultCurve;
  final TickerProvider vsync;

  //final Map<Object, AnimationTrack<Object?>> _tracks = <Object, AnimationTrack<Object?>>{};
  //final Map<Object, dynamic> _fixedValues = {};
  final Map<Object, dynamic> _values = {};

  final List<void Function(AnimationDirector)> _listeners = [];

  late final AnimationTrackScheduler _scheduler = heart.attachChild(AnimationTrackScheduler(vsync: vsync, onFrame: _notifyListeners));
  late final StreamController<(Object, dynamic)> _streamController;

  new({required this.defaultDuration, required this.defaultCurve, required this.vsync}) {
    heart.onDispose(() {
      _listeners.clear();
      _scheduler.dispose();
    });

    _streamController = heart.attachStreamController(StreamController<(Object, dynamic)>.broadcast());
  }

  static void _noop() {}

  /// Crea un director que reconstruye [state] en cada frame de animación.
  /// [state] es el propio State (`this`) que mezcla
  /// `SingleTickerProviderStateMixin` o `TickerProviderStateMixin`.
  ///
  /// ```dart
  /// class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  ///   late final anim = AnimationDirector.onState(state: this, ...);
  ///
  ///   @override
  ///   void dispose() {
  ///     anim.dispose();
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  static AnimationDirector onState({required TickerProvider state, required Duration defaultDuration, required Curve defaultCurve}) {
    assert(state is State, 'onState espera el State (this) que mezcla un TickerProvider mixin.');
    final owner = state as State;

    final director = AnimationDirector(
      defaultDuration: defaultDuration,
      defaultCurve: defaultCurve,
      vsync: state,
    );

    director.addListener((_) {
      if (owner.mounted) {
        // ignore: invalid_use_of_protected_member
        owner.setState(_noop);
      }
    });
    return director;
  }

  bool get isAnimating => _scheduler.isAnimating;

  bool contains(Object key) => _values.containsKey(key);

  Result<Stream<T>> buildValueListener<T>(Object key) => resultScopeValue(() {
    checkDisposed().$;
    return _streamController.stream.where((event) => event.$1 == key).map((event) => event.$2).where((x) {
      if (x is T) {
        return true;
      } else if (x is AnimationTrack && x.current is T) {
        return true;
      }

      return false;
    }).cast<T>();
  });

  void stop([Object? key]) {
    if (isDisposed) {
      return;
    }
    if (key == null) {
      _scheduler.stopAll();
      return;
    }

    final value = _values[key];
    if (value == null) {
      return;
    }

    if (value is AnimationTrack) {
      _scheduler.stop(value);
    }
  }

  void addListener(void Function(AnimationDirector) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AnimationDirector) listener) {
    _listeners.remove(listener);
  }

  /// Valor actual (interpolado) de [key]. Si no existe y se pasa
  /// [defaultValue], se crea con ese valor inicial.
  T $<T extends Object>(Object key, [T? value]) {
    final exists = _values[key];
    if (exists != null) {
      if (exists is AnimationTrack) {
        if (exists is AnimationTrack<T>) {
          //if (value != exists.initValue) {
          //  set<T>(key, value!);
          //}
          return exists.current;
        } else {
          throw StateError('Type mismatch for key $key: requested $T, but the value is ${exists.runtimeType}');
        }
      }

      if (exists is! T) {
        throw StateError('Type mismatch for key $key: requested $T, but the value is ${exists.runtimeType}');
      }
      /*
      if (value != null && value != exists) {
        _values[key] = value;
        _streamController.add((key, value));
      }*/

      return exists;
    }

    if (const [double, Color, int, num].contains(T)) {
      final tracket = _createTrack<T>(value);
      _values[key] = tracket;
      _streamController.add((key, tracket.current));
      return tracket.current as T;
    }
    //if (const [bool, Curve, Duration, AnimationScriptInterface].contains(T) || (value != null && value is AnimationScriptInterface)) {
    return _processFixedValue<T>(key, value);
    //}

    //throw StateError('Unsupported type for key $key: $T');
  }

  T _processFixedValue<T>(Object key, T? value) {
    if (T == bool) {
      final boolValue = value ?? true;
      _values[key] = boolValue;
      _streamController.add((key, boolValue));
      return boolValue as T;
    }

    if (T == Curve) {
      final curveValue = value ?? defaultCurve;
      _values[key] = curveValue;
      _streamController.add((key, curveValue));
      return curveValue as T;
    }
    if (T == Duration) {
      final durationValue = value ?? defaultDuration;
      _values[key] = durationValue;
      _streamController.add((key, durationValue));
      return durationValue as T;
    }

    if (T == AnimationScriptInterface || (value != null && value is AnimationScriptInterface)) {
      _values[key] = value;
      _streamController.add((key, value));
      return value as T;
    }

    if (value == null) {
      throw StateError('Value for key $key (type $T) cannot be null');
    }
    _values[key] = value;
    _streamController.add((key, value));
    return value as T;
  }

  /// Anima [key] hacia [value]. La primera vez solo fija el valor inicial
  /// (sin animación); [duration] y [curve] aplican desde la segunda llamada.
  /// Si [value] es igual al destino actual no hace nada, así que es seguro
  /// llamarlo desde `build`. Inicializá con `0.0` (no `0`) si el valor es decimal.
  /// Después de [dispose] no hace nada (útil para callbacks asíncronos tardíos).
  void set<T extends Object>(Object key, T value, {Duration? duration, Curve? curve}) {
    if (isDisposed) {
      return;
    }

    if (!(value is double || value is Color || value is int || value is num) || value is AnimationScriptInterface) {
      _values[key] = value;
      _streamController.add((key, value));
      return;
    }

    final track = _values[key];
    if (track == null) {
      _values[key] = _createTrack<T>(value);
      _streamController.add((key, value));
      return;
    }

    if (track is! AnimationTrack) {
      throw ArgumentError.value(
        value,
        'value',
        'Key $key holds ${track.runtimeType} and cannot animate to ${value.runtimeType}. '
            'If it should be decimal, initialize it with a double (e.g. 0.0).',
      );
    }

    final Object target = (value is int && track is AnimationTrack<double>) ? value.toDouble() : value;

    if (!track.accepts(target)) {
      throw ArgumentError.value(
        value,
        'value',
        'Key $key holds ${track.current.runtimeType} and cannot animate to ${value.runtimeType}. '
            'If it should be decimal, initialize it with a double (e.g. 0.0).',
      );
    }

    _scheduler.animate(track, target, duration ?? defaultDuration, curve ?? defaultCurve);
  }

  /// Registra una key de un tipo propio (Offset, Size, Alignment, EdgeInsets…)
  /// con su función de interpolación. Si la key ya existe, no hace nada, así
  /// que puede llamarse desde `build`. Después se usa con [$] y [set] normalmente.
  ///
  /// ```dart
  /// anim.define('pos', Offset.zero, (a, b, t) => Offset.lerp(a, b, t)!);
  /// ```
  void define<T>(Object key, T initial, Lerp<T> lerp) {
    if (isDisposed) {
      return;
    }
    _values.putIfAbsent(key, () => AnimationTrack<T>(lerp, initial));
  }

  AnimationTrack<Object?> _createTrack<T>(T? value) {
    // Números: el tipo estático decide int vs double, porque en web ambos son
    // el mismo número JS y `1.0 is int` da true. Solo un `int` explícito
    // genera una pista entera; num/double/dynamic van a double.

    if (value == null) {
      if (T == int) {
        value = 0 as T;
      } else if (T == double || T == num) {
        value = 0.0 as T;
      } else if (T == Color) {
        value = const Color.fromARGB(0, 0, 0, 0) as T;
      }

      throw StateError('Value for key cannot be null');
    }

    if (value is num) {
      if (T == int) {
        return AnimationTrack<int>(Lerps.integer, value as int);
      }
      return AnimationTrack<double>(Lerps.dbl, value.toDouble());
    }

    // Por tipo en runtime: acepta subclases (MaterialColor, etc.).
    if (value is Color) {
      return AnimationTrack<Color>(Lerps.color, value);
    }

    throw UnsupportedError('Unsupported type ${value.runtimeType}. Use define() with a custom lerp.');
  }

  // Una sola llamada por frame, desde el tick (fase de transient callbacks),
  // donde setState es válido y se refleja en ESTE frame.
  void _notifyListeners() {
    final listeners = _listeners;
    switch (listeners.length) {
      case 0:
        return;
      case 1:
        listeners[0](this);
      default:
        for (final listener in List.of(listeners)) {
          listener(this);
        }
    }
  }
}

/// Integra un [AnimationDirector] en un State y garantiza el orden de dispose:
/// el director (y su Ticker) se libera SIEMPRE antes que el TickerProvider mixin.
///
/// El `on State<T>, TickerProvider` obliga a declararlo DESPUÉS del mixin de
/// ticker; si el orden está mal, no compila.
///
/// ```dart
/// class _MyState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, AnimationDirectorMixin {
///   @override
///   Widget build(BuildContext context) {
///     anim.set('opacity', visible ? 1.0 : 0.0);
///     return Opacity(opacity: anim.$('opacity', 0.0), child: ...);
///   }
/// }
/// ```
mixin AnimationDirectorMixin<T extends StatefulWidget> on State<T>, TickerProvider {
  AnimationDirector? _animationDirector;
  bool _animationDirectorDisposed = false;

  /// Duración por defecto. Sobrescribila para cambiarla.
  Duration get animationDuration => const Duration(milliseconds: 250);

  /// Curva por defecto. Sobrescribila para cambiarla.
  Curve get animationCurve => Curves.easeInOut;

  /// Se crea en el primer uso: un State que nunca anima no paga nada.
  /// Después del dispose devuelve siempre un director ya liberado, nunca uno
  /// nuevo: así un `set` tardío no puede pedir un Ticker al State descartado.
  AnimationDirector get anim {
    final existing = _animationDirector;
    if (existing != null) {
      return existing;
    }

    final director = AnimationDirector.onState(
      state: this,
      defaultDuration: animationDuration,
      defaultCurve: animationCurve,
    );
    if (_animationDirectorDisposed) {
      director.dispose(); // nunca creó Ticker: el scheduler es perezoso
    }
    return _animationDirector = director;
  }

  @override
  void dispose() {
    // Corre antes que el dispose de SingleTickerProviderStateMixin /
    // TickerProviderStateMixin, que es el que verifica los tickers activos.
    // Se conserva la referencia (no se pone en null) para no recrearlo.
    _animationDirectorDisposed = true;
    _animationDirector?.dispose();
    super.dispose();
  }
}
