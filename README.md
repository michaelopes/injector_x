# InjectorX
Dependence managment from Flutter


## How to use
```dart

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
   var repo = InjectorXBind.get<IRepo>();
   var usecase = InjectorXBind.get<IUsecase<String, bool>>();
   var viewModel = InjectorXBind.get<IViewModel>();
   
   //Example to inject mock
   var viewModel = ViewModel()
        .injectMocks([NeedleMock<IUsecase<String, bool>>(mock: UsecaseMock())]);
}
```

## How to use with a flutter_triple
```dart
abstract class IPresenterViewModel extends InjetorXTripleStore<Exception, int> {
  bool increment();
}

class PresenterViewModel
    extends InjectorViewModelTriple<PresenterViewModel, Exception, int>
    implements IPresenterViewModel {
  PresenterViewModel() : super(0);

  @override
  void injector(InjectorX handler) {}

  @override
  bool increment() {
    store.value = store.value + 1;
    return true;
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return store;
  }
}

class PresenterViewModelMock
    extends InjectorViewModelTriple<PresenterViewModelMock, Exception, int>
    implements IPresenterViewModel {
  PresenterViewModelMock() : super(0);

  @override
  void injector(InjectorX handler) {}

  @override
  bool increment() {
    store.value = store.value + 2;
    return true;
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return store;
  }
}

//_StatePresenterState() : super(needles: [Needle<IPresenterViewModel>()]);
class StatePresenter extends StatefulWidgetInject<StatePresenter> {
  StatePresenter() : super(needles: [Needle<IPresenterViewModel>()]);
  @override
  _StatePresenterState createState() => _StatePresenterState();
}

class _StatePresenterState extends State<StatePresenter> {
  late IPresenterViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.get();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TripleBuilder(
          store: viewModel.getStore(),
          builder: (_, triple) {
            print("Counter: ${triple.state}");
            return Text("Counter: ${triple.state}");
          },
        ),
        ElevatedButton(onPressed: viewModel.increment, child: Text("Increment"))
      ],
    );
  }
}

void _registerDependencies() {
  InjectorXBind.add<IPresenterViewModel>(() => PresenterViewModel());
}
void main() {
  _registerDependencies();
   //Use this
   runApp(MaterialApp(home: StatePresenter()));
   
   //Or that
   //Example to inject mock
    var widget = StatePresenter().injectMocks(
        [NeedleMock<IPresenterViewModel>(mock: PresenterViewModelMock())]);
    runApp(MaterialApp(home: widget));
}
```
