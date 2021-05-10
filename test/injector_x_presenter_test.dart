import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:injector_x/injector_x_core.dart';
import 'package:injector_x/injector_x_presenter.dart';
import 'package:injector_x/injector_x_view_model.dart';

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
  testWidgets('Injector x presenter check inject', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StatePresenter()));
    var text = find.text("Counter: 0");
    expect(text, findsOneWidget);
    var btn = find.byType(ElevatedButton);
    await tester.tap(btn);
    await tester.pumpAndSettle();
    text = find.text("Counter: 1");
    expect(text, findsOneWidget);
  });

  testWidgets('Injector x presenter check inject mock', (tester) async {
    var widget = StatePresenter().injectMocks(
        [NeedleMock<IPresenterViewModel>(mock: PresenterViewModelMock())]);
    await tester.pumpWidget(MaterialApp(home: widget));
    var text = find.text("Counter: 0");
    expect(text, findsOneWidget);
    var btn = find.byType(ElevatedButton);
    await tester.tap(btn);
    await tester.pumpAndSettle();
    text = find.text("Counter: 2");
    expect(text, findsOneWidget);
  });
}
