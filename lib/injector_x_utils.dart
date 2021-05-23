import 'injector_x_core.dart';

class InjectCombinateNotInitialized implements Exception {
  InjectCombinateNotInitialized(this.message);
  final String message;
}

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
    if (handler == null) {
      InjectCombinateNotInitialized(
          "InjectCombinate not initialized on contructor. Put a init() on class contructor");
    }
    return handler!.injectorX.get<T>();
  }

  R injectMocks(List<NeedleMock> needleMocks) {
    var handler = _finder['handler'];
    if (handler != null) {
      print("aki");
      handler.injectMocks(needleMocks);
    } else {
      InjectCombinateNotInitialized(
          "InjectCombinate not initialized on contructor. Put a init() on class contructor");
    }
    return this as R;
  }
}
