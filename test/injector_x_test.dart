import 'package:flutter_test/flutter_test.dart';
import 'package:injector_x/injector_x.dart';

abstract class IRepo {
  bool save(String param);
}

class Repo implements IRepo {
  @override
  bool save(String name) {
    print("Save a: $name");
    return true;
  }
}

abstract class IUsecase<Input, Output> {
  Output call(Input param);
}

class Usecase extends Inject<Usecase> implements IUsecase<String, bool> {
  Usecase() : super(needles: [Needle<IRepo>()]);
  late IRepo repo;

  @override
  bool call(String param) {
    if (param == "Michael") {
      return repo.save(param);
    } else {
      return false;
    }
  }

  @override
  void injector(InjectorX handler) {
    repo = handler.get();
  }
}

abstract class IViewModel {
  bool saveUserName(String name);
}

class ViewModel extends Inject<ViewModel> implements IViewModel {
  ViewModel() : super(needles: [Needle<IUsecase<String, bool>>()]);

  late IUsecase<String, bool> usecase;

  @override
  void injector(InjectorX handler) {
    usecase = handler.get();
  }

  @override
  bool saveUserName(String name) {
    return usecase(name);
  }
}

/*MOCKS*/
class UsecaseMock implements IUsecase<String, bool> {
  @override
  bool call(String param) {
    return true;
  }
}

void _registerDependencies() {
  InjectorXBind.add<IRepo>(() => Repo());
  InjectorXBind.add<IUsecase<String, bool>>(() => Usecase(), singleton: true);
  InjectorXBind.add<IViewModel>(() => ViewModel());
}

void main() {
  _registerDependencies();

  test('Check chain of dependences register', () {
    var repo = InjectorXBind.get<IRepo>();
    var usecase = InjectorXBind.get<IUsecase<String, bool>>();
    var viewModel = InjectorXBind.get<IViewModel>();

    expect(repo, isA<Repo>());
    expect(usecase, isA<Usecase>());
    expect(viewModel, isA<ViewModel>());

    var name = "Michael";
    expect(repo.save(name), isTrue);
    expect(usecase(name), isTrue);
    expect(viewModel.saveUserName(name), isTrue);
  });

  test('Check usecase rule', () {
    var repo = InjectorXBind.get<IRepo>();
    var usecase = InjectorXBind.get<IUsecase<String, bool>>();
    var viewModel = InjectorXBind.get<IViewModel>();
    var name = "João";
    expect(repo.save(name), isTrue);
    expect(usecase(name), isFalse);
    expect(viewModel.saveUserName(name), isFalse);
  });

  test('Check usecase mock', () {
    var repo = InjectorXBind.get<IRepo>();
    var usecase = InjectorXBind.get<IUsecase<String, bool>>();
    var viewModel =
        ViewModel().injectMocks([NeedleMock<IUsecase>(mock: UsecaseMock())]);
    var name = "João";
    expect(repo.save(name), isTrue);
    expect(usecase(name), isFalse);
    expect(viewModel.saveUserName(name), isTrue);
  });

  test('Check usecase new instance', () {
    var usecaseNew =
        InjectorXBind.get<IUsecase<String, bool>>(newInstance: true);
    var usecase = InjectorXBind.get<IUsecase<String, bool>>();

    var equals = usecase.hashCode == usecaseNew.hashCode;
    expect(equals, isFalse);
  });

  test('Check get usecase short type', () {
    var usecase = InjectorXBind.get<IUsecase>();

    expect(usecase, isNotNull);
  });

  test('Check InjectionNotFound', () {
    expect(() => InjectorXBind.get<UsecaseMock>(),
        throwsA(isInstanceOf<InjectionNotFound>()));
  });

  test('Check NeedleMock', () {
    var needleMock = NeedleMock<IUsecase<String, bool>>(mock: UsecaseMock());
    expect(needleMock.isNewInstance(), isTrue);

    needleMock = NeedleMock(type: String, mock: UsecaseMock());
    expect(needleMock.type, String);
  });

  test('Check ref needle not found', () {
    var handler = InjectorX([Needle<IRepo>()]);
    expect(() => handler.get<String>(),
        throwsA(isInstanceOf<InjectionNotFound>()));
  });

  test('Check replace method', () {
    var usecaseOld = InjectorXBind.get<IUsecase<String, bool>>();
    InjectorXBind.replace<IUsecase<String, bool>>(() => UsecaseMock());
    var usecaseNew = InjectorXBind.get<IUsecase<String, bool>>();
    expect(usecaseOld.hashCode == usecaseNew.hashCode, isFalse);
  });

  test('Check replace with add method', () {
    var usecaseOld = InjectorXBind.get<IUsecase<String, bool>>();
    InjectorXBind.add<IUsecase<String, bool>>(() => UsecaseMock());
    var usecaseNew = InjectorXBind.get<IUsecase<String, bool>>();
    expect(usecaseOld.hashCode == usecaseNew.hashCode, isFalse);
  });
}
