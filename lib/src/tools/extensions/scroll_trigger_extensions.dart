import 'dart:async';

import 'package:maxi_flutter_widget/src/tools/scroll_trigger.dart';

extension ScrollTriggerExtensions on ScrollTrigger {
  /// Registers a callback to be invoked when the scroll trigger reaches the bottom.
  /// The callback should return `true` or `null` to continue listening, or `false` to cancel the subscription.
  void onBottom(bool? Function([ScrollTrigger]) callback) {
    late final StreamSubscription subcription;

    subcription = notificationChange.listen((offset) {
      if (isAtBottom) {
        if (callback(this) == false) {
          subcription.cancel();
        }
      }
    });
  }

  /// Registers a callback to be invoked when the scroll trigger reaches the top.
  /// The callback should return `true` or `null` to continue listening, or `false` to cancel the subscription.
  void onTop(bool? Function([ScrollTrigger]) callback) {
    late final StreamSubscription subcription;

    subcription = notificationChange.listen((offset) {
      if (isAtTop) {
        if (callback(this) == false) {
          subcription.cancel();
        }
      }
    });
  }

  /// Registers a callback to be invoked when the scroll trigger reaches a specific offset.
  /// The callback should return `true` or `null` to continue listening, or `false` to cancel the subscription.
  void onSpecificOffset(double targetOffset, bool? Function([ScrollTrigger]) callback) {
    late final StreamSubscription subcription;

    subcription = notificationChange.listen((offset) {
      if (offset == targetOffset) {
        if (callback(this) == false) {
          subcription.cancel();
        }
      }
    });
  }

  /// Registers a callback to be invoked when the scroll trigger reaches a specific range.
  /// The callback should return `true` or `null` to continue listening, or `false` to cancel the subscription.
  void onSpecificRange(double startOffset, double endOffset, bool? Function([ScrollTrigger]) callback) {
    late final StreamSubscription subcription;

    subcription = notificationChange.listen((offset) {
      if (offset >= startOffset && offset <= endOffset) {
        if (callback(this) == false) {
          subcription.cancel();
        }
      }
    });
  }
}
