import 'package:flutter/widgets.dart';
import 'package:maxi_flutter_widget/src/template/element_mold.dart';

class ElementMoldWidget<T> extends StatelessWidget {
  final T value;
  final ElementMold<T> mold;

  const ElementMoldWidget({super.key, required this.value, required this.mold});

  @override
  Widget build(BuildContext context) {
    return mold.build(context: context, value: value);
  }
}
