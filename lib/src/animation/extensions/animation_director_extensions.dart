import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

extension AnimationDirectorExtensions on AnimationDirector {
  /*T buildValue<T extends Object>(Object key, T Function(AnimationDirector director, T current) updater, {Duration? duration, Curve? curve}) {
    final current = $<T>(key);
    final updated = updater(this, current);
    set(key, updated, duration: duration, curve: curve);
    return $<T>(key);
  }*/
}
