import 'package:flutter/widgets.dart';

import 'injector_x_core.dart';

class _InjectHandlerWidget extends Inject<_InjectHandlerWidget> {
  _InjectHandlerWidget({List<Needle>? needles}) : super(needles: needles);
  late InjectorX injectorX;
  @override
  void injector(InjectorX handler) {
    injectorX = handler;
  }
}

mixin _InjectHandlerWidgetMixin {
  final Map<String, _InjectHandlerWidget> handlerMap = {};
  _InjectHandlerWidget get handler => handlerMap["handler"]!;
  set handler(_InjectHandlerWidget h) => handlerMap["handler"] = h;
}

abstract class StatefulWidgetInject<T extends StatefulWidgetInject<T>>
    extends StatefulWidget with _InjectHandlerWidgetMixin {
  StatefulWidgetInject({List<Needle>? needles}) {
    this.handler = _InjectHandlerWidget(needles: needles);
  }

  T get<T>() {
    return handler.injectorX.get<T>();
  }

  T injectMocks(List<NeedleMock> needleMocks) {
    handler.injectMocks(needleMocks);
    this.createState();
    return this as T;
  }
}
