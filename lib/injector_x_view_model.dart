import 'package:flutter_triple/flutter_triple.dart';

import 'injector_x_core.dart';

class _InjectHandlerStore extends Inject<_InjectHandlerStore> {
  _InjectHandlerStore({List<Needle>? needles}) : super(needles: needles);
  late InjectorX injectorX;
  @override
  void injector(InjectorX handler) {
    injectorX = handler;
  }
}

abstract class InjetorXTripleStore<E extends Object, T extends Object> {
  NotifierStore<E, T> getStore();
}

class _InjetorXTripleStore<E extends Object, T extends Object>
    extends NotifierStore<E, T> {
  _InjetorXTripleStore(T initialState) : super(initialState);
  set value(T v) => update(v);
  T get value => state;
}

abstract class InjectorViewModelTriple<
    R extends InjectorViewModelTriple<R, E, T>,
    E extends Object,
    T extends Object> {
  late _InjetorXTripleStore<E, T> store;
  late _InjectHandlerStore handler;
  InjectorViewModelTriple(T initalState, {List<Needle>? needles}) {
    store = _InjetorXTripleStore<E, T>(initalState);
    handler = _InjectHandlerStore(needles: needles);
    this.injector(handler.injectorX);
  }

  R injectMocks(List<NeedleMock> needleMocks) {
    handler.injectMocks(needleMocks);
    this.injector(handler.injectorX);
    return this as R;
  }

  void injector(InjectorX handler);
}
