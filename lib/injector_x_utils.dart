import 'injector_x_core.dart';

abstract class InjetorXViewModelStore<T> {
  T getStore();
}

class _InjectHandlerStore extends Inject<_InjectHandlerStore> {
  _InjectHandlerStore({List<Needle>? needles}) : super(needles: needles);
  late InjectorX injectorX;
  @override
  void injector(InjectorX handler) {
    injectorX = handler;
  }
}

abstract class InjectCombinate<R extends InjectCombinate<R>> {
  final Map<String, _InjectHandlerStore> _finder = {};

  void init({List<Needle>? needles}) {
    var handler = _InjectHandlerStore(needles: needles);
    _finder.addAll({"handler": handler});
  }

  T inject<T>() {
    var handler = _finder['handler'];
    return handler!.injectorX.get<T>();
  }

  R injectMocks(List<NeedleMock> needleMocks) {
    var handler = _finder['handler'];
    if (handler != null) {
      print("aki");
      handler.injectMocks(needleMocks);
    }
    return this as R;
  }
}
