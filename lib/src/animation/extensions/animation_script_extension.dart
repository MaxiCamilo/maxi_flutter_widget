import 'dart:async';

import 'package:maxi_dart_framework/maxi_dart_framework.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

extension AnimationScriptExtension on AnimationScriptInterface {
  Future<void> executeAndWait(AnimationDirector director) => futureScopeVoid(() async {
    final completer = Completer();
    execute(director, onFinished: () => completer.complete()).$;
    await completer.future;
  });
}
