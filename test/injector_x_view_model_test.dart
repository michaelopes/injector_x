import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:injector_x/injector_x_core.dart';
import 'package:injector_x/injector_x_utils.dart';

abstract class IUsecase {
  int increment(int value);
}

class Usecase implements IUsecase {
  @override
  int increment(int value) {
    return value + 1;
  }
}

abstract class IPresenterViewModel
    extends InjetorXViewModelStore<NotifierStore<Exception, int>> {
  bool increment();
}

class PresenterViewModel extends NotifierStore<Exception, int>
    with InjectCombinate<PresenterViewModel>
    implements IPresenterViewModel {
  PresenterViewModel() : super(0) {
    init(needles: [Needle<IUsecase>()]);
  }

  IUsecase get usecase => inject();

  @override
  bool increment() {
    update(usecase.increment(state));
    return true;
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return this;
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
    expect(viewmodel.state, 0);
    viewmodel.increment();
    expect(viewmodel.state, 1);
  });

  test('Injector x view model inject mock', () async {
    var viewmodel = PresenterViewModel()
        .injectMocks([NeedleMock<IUsecase>(mock: UsecaseMock())]);
    expect(viewmodel.state, 0);
    viewmodel.increment();
    expect(viewmodel.state, 2);
  });
}
