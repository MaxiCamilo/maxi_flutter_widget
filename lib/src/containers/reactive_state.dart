import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maxi_dart_framework/maxi_dart_framework.dart';

abstract class ReactiveState<T extends StatefulWidget> extends State<T> implements Disposable, DisposableMixin {
  bool _isDisposed = false;
  bool _initiated = false;
  LifecycleScope? _heart;

  @override
  bool get isDisposed => _isDisposed;

  LifecycleScope get heart {
    if (_heart == null) {
      _heart = LifecycleScope();
      if (_isDisposed) {
        log('Disposing heart because the state is already disposed');
        _heart!.dispose();
      }
    }

    return _heart!;
  }

  Result<void> performInitiation() => Result.ok;  

  
  @override
  @nonVirtual
  void initState() {
    super.initState();
    try {
      final result = performInitiation();
      if (result is ResultValue<void>) {
        _initiated = true;
      } else {
        throw result;
      }
    } catch (e) {
      _heart?.dispose();
      rethrow;
    }
  }

  @override
  @nonVirtual
  void dispose() {
    super.dispose();
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _heart?.dispose();
    if (_initiated) {
      performDisposal();
    }
  }

  @override
  void performDisposal() {}
}
