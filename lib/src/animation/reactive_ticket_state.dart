import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/maxi_flutter_widget.dart';

abstract class ReactiveSingleTickerState<W extends StatefulWidget> extends ReactiveState<W> with SingleTickerProviderStateMixin<W> {
  @override
  void dispose() {
    heart.dispose();
    super.dispose();
  }
}
