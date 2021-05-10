import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:injector_x/injector_x_core.dart';
import 'package:injector_x/injector_x_view_model.dart';

abstract class IUsecase {
  int increment(int value);
}

class Usecase implements IUsecase {
  @override
  int increment(int value) {
    return value + 1;
  }
}

abstract class IPresenterViewModel extends InjetorXTripleStore<Exception, int> {
  void increment();
}

class PresenterViewModel
    extends InjectorViewModelTriple<PresenterViewModel, Exception, int>
    implements IPresenterViewModel {
  PresenterViewModel() : super(0, needles: [Needle<IUsecase>()]);
  late IUsecase usecase;
  @override
  void injector(InjectorX handler) {
    usecase = handler.get();
  }

  @override
  void increment() {
    store.value = usecase.increment(store.value);
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return store;
  }
}

class UsecaseMock implements IUsecase {
  @override
  int increment(int value) {
    return value + 2;
  }
}

void _registerDependencies() {
  InjectorXBind.add<IPresenterViewModel>(() => PresenterViewModel());
  InjectorXBind.add<IUsecase>(() => Usecase());
}

void main() {
  _registerDependencies();
  test('Injector x view model inject', () async {
    var viewmodel = PresenterViewModel();
    expect(viewmodel.store.value, 0);
    viewmodel.increment();
    expect(viewmodel.store.value, 1);
  });

  test('Injector x view model inject mock', () async {
    var viewmodel = PresenterViewModel()
        .injectMocks([NeedleMock<IUsecase>(mock: UsecaseMock())]);
    expect(viewmodel.store.value, 0);
    viewmodel.increment();
    expect(viewmodel.store.value, 2);
  });
}
