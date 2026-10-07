import 'package:flutter/widgets.dart';

@immutable
abstract base class ElementMold<T> {
  const ElementMold();

  Widget build({required BuildContext context, required T value});
}
