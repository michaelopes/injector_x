
A ideia do InjectorX surgiu para facilitar o controle e a manutenção das injeções de dependências em um projeto flutter com o Clean Architecture. 
A principal diferença InjectorX para os principais packages já disponíveis é o controle de injeção por contexto, sendo assim descentralizando as 
injeções e não instanciando o que não precisa fora daquele contexto. Nesse modelo o objeto em si é um service locator para suas próprias injeções,
substituindo a necessidade de passar as injeções via controlador, contudo não perdendo a o poder de desacoplamento de código e facilitando ainda 
mais a visualização do que é injetado naquele objeto.


## Mind Map:

![Mind Map](https://user-images.githubusercontent.com/10121156/118364170-4e01d780-b565-11eb-924b-130365ab3730.jpeg)


### Passo a passo do que o diagrama representa:

Antes de tudo devemos definir nossos contratos da aplicação.

Em um contrado é estabelecido quais as regras que um objeto tem que ter para ao ser implementado.
Para que os objetos subjacentes não se acople a implementação em si e sim ao contrato, sendo assim independente
da implementação qualquer objeto que siga as regas do contrato será aceito na injeção referênciada.

```dart
abstract class IApi {
  Future<dynamic> post(String url, dynamic data);
}

abstract class IUserRepo {
  Future<bool> saveUser(String email, String name);
}

abstract class IUserUsecase {
  Future<bool> call(String email, String name);
}

abstract class IViewModel {
  Future<bool> save(String email, String name);
  bool get inLoading;
}

/* 
Esse contrato é utilizando o flutter_tripple será exemplificado 
mais para frente 
*/
abstract class IViewModelTriple extends InjetorXTripleStore<Exception, bool> {
  Future<void> save(String email, String name);
}

/*
Nesse caso não peciso herdar de Inject, pois o contexto desse objeto 
não precisa controlar suas injeções, contudo o InjetorX poderá injeta-lo onde 
houver necessidade como no exemplo seguinte UserRepoImpl
*/
class ApiImpl implements IApi {
  @override
  Future post(String url, data) async {
    var httpClient = Dio();
    return await httpClient.post(url, data: data);
  }
}

/*
Como nossa implementação do repositório depende do contrado da api, devemos 
herdar da classe Inject para podermos manipular as injeções desse contexto 
separadamente.
 */

class UserRepoImpl extends Inject<UserRepoImpl> implements IUserRepo {
  /*
   No contrutor filho não é preciso passar o que esse objeto precisa para 
  como injeção. Isso é feito um pouco diferente agora, através de Needles 
  (Needle é agulha em inglês). Cada agulha (Needle<IApi>()) fará a refêrencia 
  necessária ao contrato para o InjectorX saiba o que deve ser injetado no contexto desse
  objeto, pelo no método injector.
   */
  UserRepoImpl() : super(needles: [Needle<IApi>()]);
  /*
  Aqui é definido a variável do contrado da Api que o repositório aceitará para ser
  injetado em seu contexto.
  */
  late IApi api;

  /*
  Quando herdamos de Inject automaticamente esse método será criado ele terá 
  objecto InjectorX que é um service locator para identificar e referênciar as 
  injeções ao contrato que o IUserRepoImpl precisa.
  */
  @override
  void injector(InjectorX handler) {
    /*
    Aqui de forma abstratida o handler do InjectorX 
    buscará a implementação registada para o contrato IApi
    */
    api = handler.get();
  }

  /*
  Aqui utilizaremos a implementação do contrato em sí, não sabemos qual é 
  a implementação e não precisamos, pois seguindo a regra do contrato imposto isso 
  fica irrelevante.
  */
  @override
  Future<bool> saveUser(String email, String name) async {
    try {
      await api
          .post("https://api.com/user/save", {"email": email, "name": name});
      return true;
    } on Exception {
      return false;
    }
  }
}

/*
Aqui tudo se repetirá como no exemplo anterior, contudo aqui não sabemos 
o que o UserRepoImpl injeta em seu contexto apenas referenciamos ao seu contrato
e o InjectorX saberá o que injetar em cada contexto etapa por etapa.
*/
class UserUsecaseImpl extends Inject<UserUsecaseImpl> implements IUserUsecase {
  UserUsecaseImpl() : super(needles: [Needle<IUserRepo>()]);

  late IUserRepo repo;
  /*
  O conceito de use case é para controlar a regra de negócio de um comportamento em 
  específico nesse caso só deixará salvar usuários com email do gmail. 
  */
  @override
  Future<bool> call(String email, String name) async {
    if (email.contains("@gmail.com")) {
      return await repo.saveUser(email, name);
    } else {
      return false;
    }
  }

  @override
  void injector(InjectorX handler) {
    repo = handler.get();
  }
}

/*
  O ViewModel é responsavel pelo controle de estado de uma tela, ou de um widget em específico
  note que o view model não controla regra de negócio sim estado da tela qual for referênciado.
  Nesse caso o estado está sendo controlado por RxNotifier, contudo isso pode ser feito 
 com qualquer outro gerenciador de estado da sua preferência.
 */
class ViewModelImpl extends Inject<ViewModelImpl> implements IViewModel {
  ViewModelImpl() : super(needles: [Needle<IUserUsecase>()]);

  late IUserUsecase userUsecase;
  var _inLoading = RxNotifier(false);

  set inLoading(bool v) => _inLoading.value = v;
  bool get inLoading => _inLoading.value;

  @override
  void injector(InjectorX handler) {
    userUsecase = handler.get();
  }

  @override
  Future<bool> save(String email, String name) async {
    var _result = false;

    inLoading = true;
    _result = await userUsecase(email, name);
    inLoading = false;

    return _result;
  }
}

/* 
O InjectorX também pode ser integrado com o flutter_triple de maneira simplicada
facilitando ainda mais o controle de estado por fluxo.
 */

class ViewModelTriple
    extends InjectorViewModelTriple<ViewModelTriple, Exception, bool>
    implements IViewModelTriple {
  /*
  Note que há uma pequena diferença agora a 2 parâmetros no super. Isso 
  ocorre porque ao herdar de InjectorViewModelTriple além dos needles responsáveis
  pela gerencia dos contratos de injeção também devemos passar o estado inicial 
  do flutter_triple.
  Para saber mais sobre o flutter_triple acesse: https://pub.dev/packages/flutter_triple
  */
  ViewModelTriple() : super(false, needles: [Needle<IUserUsecase>()]);

  late IUserUsecase userUsecase;
  @override
  void injector(InjectorX handler) {
    userUsecase = handler.get();
  }

  /*
  Aqui retorno a store do flutter_triple responsável pelo gerenciamento de 
  estado do ViewModel. Ao implementar IViewModelTriple que extende de InjetorXTripleStore<Exception, bool>
  Esse médoto deverá ser implementado para que a Tela/View/Ui tem acesso a essa a store da implementação 
  atraves de seu contrato. 
   */
  @override
  NotifierStore<Exception, bool> getStore() {
    return store;
  }

  @override
  Future<void> save(String email, String name) async {
    store.setLoading(true);
    try {
      store.value = await userUsecase(email, name);
    } on Exception catch (e) {
      store.setError(e);
    }
    store.setLoading(false);
  }
}

/*
Agora partiremos para implementação de uma view para exemplificar o fluxo completo.
O InjectoX tem um recurso expecífico para lidar com as view por enquanto somente é possível
com Stateful mais em breve o Stateless também terá suporte.
Note que ao em vez de herdar de StatefulWidget herdaremos de StatefulWidgetInject
isso nos dará todos os recursos de injeção que já vemos para tráz contudo no contexto de um 
Widget.
Nesse primeiro exempo será usado o ViewModel com RxNotifier;

Observe que agora não é mais implementado o método:
@override
void injector(InjectorX handler) {
  userUsecase = handler.get();
}

Se tratando de uma view isso é feito de maneira diferente. Olhem no intiState() a novo jeito proposto.
*/

class ScreenExample extends StatefulWidgetInject<ScreenExample> {
  ScreenExample() : super(needles: [Needle<IViewModel>()]);
  @override
  _ScreenExampleState createState() => _ScreenExampleState();
}

class _ScreenExampleState extends State<ScreenExample> {
  late IViewModel viewModel;

  @override
  void initState() {
    super.initState();
    /*
    Aqui agora ao em vez de usar o handler do método injector como exemplificado anteriormente, 
    simplesmente chamos widget.get() que terár o service locator da view com os recursos do InjectorX
    */
    viewModel = widget.get();
  }

  @override
  Widget build(BuildContext context) {
    return RxBuilder(
      builder: (_) => IndexedStack(
        index: viewModel.inLoading ? 0 : 1,
        children: [
          Center(child: CircularProgressIndicator()),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                var success =
                    await viewModel.save("mail@gmail.com", "Username");
                if (success) {
                  print("Users successful saved");
                } else {
                  print("Error on save user");
                }
              },
              child: Text("Salvar dados do usuário"),
            ),
          )
        ],
      ),
    );
  }
}

/*
Aqui outro exemplo de como podemos implementar com o flutter_triple não a muita diferênca em essência
a não ser como lidamos com a mudaça de estado.
 */
class ScreenTripleExample extends StatefulWidgetInject<ScreenTripleExample> {
  ScreenTripleExample() : super(needles: [Needle<IViewModelTriple>()]);
  @override
  _ScreenTripleExampleState createState() => _ScreenTripleExampleState();
}

class _ScreenTripleExampleState extends State<ScreenTripleExample> {
  late IViewModelTriple viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.get();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ScopedBuilder(
        //Note que agora usamos o getStore da implementação ViewModel com flutter_triple
        store: viewModel.getStore(),
        onState: (context, state) => Center(
          child: ElevatedButton(
            onPressed: () async {
              await viewModel.save("mail@gmail.com", "Username");
            },
            child: Text("Salvar dados do usuário"),
          ),
        ),
        onError: (context, error) => Center(child: Text(error.toString())),
        onLoading: (context) => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
```

### Referência de contratos
Para que o InjectorX saiba o que deve injetar em cada needle devemos na inicialização
do app mostrar para o InjectoX qual a implementação de cada contrato.
Note que em nenhum momento é passado implementação para o contrutor de outra refêrencia, por mais 
que a implementação tem injeções em sua implementação.
Isso fará toda a diferença no controle de injeção, pois fica mais simples a visualização e tudo não será 
carregado de uma vez em memória e sim por demanda, a medida que cada objeto necessite de uma injeção.


```dart
void _registerDependencies() {
  InjectorXBind.add<IApi>(() => ApiImpl());
  InjectorXBind.add<IUserRepo>(() => UserRepoImpl());
  InjectorXBind.add<IUserUsecase>(() => UserUsecaseImpl());
  InjectorXBind.add<IViewModel>(() => ViewModelImpl());
  InjectorXBind.add<IViewModelTriple>(() => ViewModelTriple());
}
```

#### Como ficaria isso com GetIt só um exemplo simples e ficticio
Note que passamos as referências de injeção por contrutor, aqui como é 
um exemplo pequeno ainda conseguimos visualizar facilmente, contudo a medida que 
presisar de várias injeções em um único contrutor e aplicação for crescendo, isso virará 
um caos e ficará extremamente difícil de visualizar e controlar o que está injetando no que.
E nesse caso todos os objetos foram subidos em memória mesmo que o um objeto não precise 
daquela referência ele já está disponível.

```dart
void _setup() {
  GetIt.I.registerSingleton<IApi>(ApiImpl());
  GetIt.I.registerSingleton<IUserRepo>(UserRepoImpl( GetIt.I.get<IApi>() ));
  GetIt.I.registerSingleton<IUserUsecase>(UserUsecaseImpl( GetIt.I.get<IUserRepo>() ));
  GetIt.I.registerSingleton<IViewModel>(ViewModelImpl( GetIt.I.get<IUserUsecase>() ));
  GetIt.I.registerSingleton<IViewModelTriple>(ViewModelTriple( GetIt.I.get<IUserUsecase>() ));
}
```

O InjectoX não depende de uma chamada expecícica utilizando a refência do gerenciador de depêndencia
no GetIt toda vez que precisamos recuperar um objeto que está registrado em seu pacote e feito como no exemplo abaixo:
```dart
 var viewModel = GetIt.I.get<IViewModel>();
```
Se não for feito assim todas as referências que precisam ser auto injetadas não funcionaram.

No injectorX posso ser livre e fazer de dois jeitos.

Usando o gerenciador de depêndencia como abaixo:
```dart
 IViewModel viewModel = InjectorXBind.get();
```
Ou instânciando a classe diretamente:

```dart
 var viewModel = ViewModelImpl();
```

Que mesmo assim tudo que precisa ser injetado nesse contexto será injetado sem problemas.


















