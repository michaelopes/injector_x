import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:injector_x/injector_x_core.dart';
import 'package:injector_x/injector_x_utils.dart';

abstract class IPresenterViewModel
    extends InjetorXViewModelStore<NotifierStore<Exception, int>> {
  bool increment();
}

class PresenterViewModel extends NotifierStore<Exception, int>
    with InjectCombinate<PresenterViewModel>
    implements IPresenterViewModel {
  PresenterViewModel() : super(0) {
    init();
  }

  @override
  bool increment() {
    update(state + 1);
    return true;
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return this;
  }
}

class PresenterViewModelMock extends NotifierStore<Exception, int>
    with InjectCombinate<PresenterViewModel>
    implements IPresenterViewModel {
  PresenterViewModelMock() : super(0) {
    init();
  }

  @override
  bool increment() {
    update(state + 2);
    return true;
  }

  @override
  NotifierStore<Exception, int> getStore() {
    return this;
  }
}

class StatePresenter extends StatefulWidget
    with InjectCombinate<StatePresenter> {
  StatePresenter() {
    init(needles: [Needle<IPresenterViewModel>()]);
  }
  @override
  _StatePresenterState createState() => _StatePresenterState();
}

class _StatePresenterState extends State<StatePresenter> {
  late IPresenterViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.inject();
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
