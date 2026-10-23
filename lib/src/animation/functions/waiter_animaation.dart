import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

final class WaiterAnimaation extends AnimationScript {
  final Duration duration;

  const new(this.duration);

  @override
  FutureResult<void> performAnimation({required AnimationDirector director, required ILifecycleScope hearth}) => futureScopeVoid(() async {
    await $$_(hearth.wait(duration));
  });
}
