
# InjectorX
Dependence managment from Flutter

A ideia do InjectorX surgiu para facilitar o controle e a manutenção das injeções de dependências em um projeto flutter com o Clean Architecture. 
A principal diferença InjectorX para os principais packages já disponíveis é o controle de injeção por contexto, assim descentralizando as 
injeções e não instanciando o que não precisa fora daquele contexto. Nesse modelo o objeto em si é um service locator para suas próprias injeções,
substituindo a necessidade de passar as injeções via controlador, contudo não perdendo o poder de desacoplamento de código, facilitando ainda 
mais a visualização do que é injetado naquele objeto.


## Mind Map:

![Mind Map](https://user-images.githubusercontent.com/10121156/118364170-4e01d780-b565-11eb-924b-130365ab3730.jpeg)


### Passo a passo do que o diagrama representa:

Antes de tudo devemos definir nossos contratos da aplicação.

Em um contrato é estabelecido quais as regras que um objeto tem que ter ao ser implementado.
Para que os objetos subjacentes não se acople a implementação em si e sim ao contrato, sendo assim independente
da implementação qualquer objeto que siga as regras do contrato será aceito na injeção referenciada.


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
abstract class IViewModelTriple extends InjetorXViewModelStore<NotifierStore<Exception, int>> {
  Future<void> save(String email, String name);
}

/*
Nesse caso não preciso herdar de Inject, pois o contexto desse objeto 
não precisa controlar suas injeções, contudo o InjetorX poderá injetá-lo onde 
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
Como nossa implementação do repositório depende do contrato da api, devemos 
herdar da classe Inject para podermos manipular as injeções desse contexto 
separadamente.
 */

class UserRepoImpl extends Inject<UserRepoImpl> implements IUserRepo {
  /*
  No construtor dessa classe não é preciso passar as referências que precisam ser injetadas. 
  Isso é feito um pouco diferente agora, através de Needles 
  (Needle é agulha em inglês). Cada agulha (Ex: Needle<IApi>()) fará a referência 
  necessária ao contrato para o InjectorX saiba o que deve ser injetado no contexto desse
  objeto, pelo no método injector.
  */
  UserRepoImpl() : super(needles: [Needle<IApi>()]);
  /*
  Aqui é definido a variável do contrato da Api que o repositório aceitará para ser
  injetado em seu contexto.
  */
  late IApi api;

  /*
  Quando a classe herda de Inject automaticamente esse método será criado ele terá 
  objeto InjectorX que é um service locator para identificar e referenciar as 
  injeções ao contrato que o IUserRepoImpl precisa.
  */
  @override
  void injector(InjectorX handler) {
    /*
    Aqui de forma abstraída o handler do InjectorX 
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
  O ViewModel é responsável pelo controle de estado de uma tela, ou de um widget em específico, note que o 
  view model não controla regra de negócio e sim estado da tela qual for referenciado.
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
 O InjectorX também pode ser integrado com o flutter_triple de maneira simplificada
 facilitando ainda mais o controle de estado por fluxo.
 */
class PresenterViewModel extends NotifierStore<Exception, int>
    with InjectCombinate<PresenterViewModel>
    implements IPresenterViewModel {
  PresenterViewModel() : super(0) {
    /*
    Note que há uma pequena diferença agora temos um init() dentro da chamada do 
    contrutor. Isso ocorre porque ao herdar de InjectCombinate precisa ser iniciado para que o InjectorX saba quais  needles responsáveis pela gerência dos contratos de injeção .
    Para saber mais sobre o flutter_triple acesse: https://pub.dev/packages/flutter_triple
   */
    init(needles: [Needle<IUsecase>()]);
  }
  /*
  No te que referenciamos a dependência diferente agora, não é manipulado mais pelo injector(InjectorX hangles) sim dessa nova maneira referenciado pelo inject()
  */
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

/*
Agora partiremos para implementação de uma view para exemplificar o fluxo completo.
O InjectoX tem um recurso específico para lidar com a view.

Nesse primeiro exemplo será usado o ViewModel com RxNotifier;

Observe que agora não é mais implementado o método:
@override
void injector(InjectorX handler) {
  userUsecase = handler.get();
}

Se tratando de uma view isso é feito de maneira diferente. Olhem no intiState() a novo jeito proposto.
*/

class ScreenExample extends StatefulWidget
    with InjectCombinate<ScreenExample> {
  ScreenExample() {
     init(needles: [Needle<IViewModel>()])
  };
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
    simplesmente chamamos widget.inject() que terá o service locator da view com os recursos do InjectorX
    */
    viewModel = widget.inject();
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
Aqui outro exemplo de como podemos implementar com o flutter_triple não há muita diferença em essência
a não ser como lidamos com a mudança de estado.
*/
class ScreenTripleExample extends StatefulWidget
    with InjectCombinate<ScreenTripleExample> {
  ScreenTripleExample() {
     //Não se esqueça de iniciar o injectorX
     init(needles: [Needle<IViewModel>()])
  };
  @override
  _ScreenTripleExampleState createState() => _ScreenTripleExampleState();
}

class _ScreenTripleExampleState extends State<ScreenTripleExample> {
  late IViewModelTriple viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.inject();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ScopedBuilder(
        //Note que agora é usado o getStore da implementação ViewModel com flutter_triple
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
do app mostrar para o InjectorX qual a implementação de cada contrato.
Note que em nenhum momento é passado implementação para o construtor de outra referência, por mais 
que a implementação tenha injeções em sua implementação.
Isso fará toda a diferença no controle de injeção, pois fica mais simples a visualização e tudo não será 
carregado de uma vez em memória e sim por demanda, à medida que cada objeto necessite de uma injeção.

```dart
void _registerDependencies() {
  InjectorXBind.add<IApi>(() => ApiImpl());
  InjectorXBind.add<IUserRepo>(() => UserRepoImpl());
  InjectorXBind.add<IUserUsecase>(() => UserUsecaseImpl());
  InjectorXBind.add<IViewModel>(() => ViewModelImpl());
  InjectorXBind.add<IViewModelTriple>(() => ViewModelTriple());
}
```

#### Como ficaria isso com GetIt só um exemplo simples e fictício
Note que é passado as referências de injeção por construtor, aqui como é 
um exemplo pequeno ainda conseguimos visualizar facilmente, contudo à medida que 
precisar de várias injeções em um único construtor e aplicação for crescendo, isso virará 
um caos e ficará extremamente difícil de visualizar e controlar o que está injetando no que.
E nesse caso todos os objetos foram subidos em memória mesmo que não precise 
daquela referência ela já está em memória.


```dart
void _setup() {
  GetIt.I.registerSingleton<IApi>(ApiImpl());
  GetIt.I.registerSingleton<IUserRepo>(UserRepoImpl( GetIt.I.get<IApi>() ));
  GetIt.I.registerSingleton<IUserUsecase>(UserUsecaseImpl( GetIt.I.get<IUserRepo>() ));
  GetIt.I.registerSingleton<IViewModel>(ViewModelImpl( GetIt.I.get<IUserUsecase>() ));
  GetIt.I.registerSingleton<IViewModelTriple>(ViewModelTriple( GetIt.I.get<IUserUsecase>() ));
}
```

O InjectoX não depende de uma chamada específica utilizando a referência do gerenciador de dependência
no GetIt toda vez que precisamos recuperar um objeto que está registrado em seu pacote e feito como no exemplo abaixo:

```dart
 var viewModel = GetIt.I.get<IViewModel>();
```
Se não for feito como no exemplo acima todas as referências que precisam ser auto injetadas não funcionarão.

No injectorX posso ser livre e fazer de dois jeitos.
Usando o gerenciador de dependência como abaixo:

```dart
 IViewModel viewModel = InjectorXBind.get();
```
Ou instanciando a classe diretamente:

```dart

 /* 
 ViewModel depende de IUserUsecase que é implementado por UserUsecaseImpl que
 por sua vez depende de IUserRepo que é implementado por UserRepoImpl que por
 sua vez depende de IApi que é implementado por ApiImpl. Controle de dependência
 é feito em etapas por cada contexto, por isso instanciar a classe diretamente não faz diferença.
 Que mesmo assim tudo que precisa ser injetado nesse contexto será injetado sem problemas.
 */
 
 var viewModel = ViewModelImpl();
```

#### Registrado singleton

```dart
void _registerDependencies() {
  InjectorXBind.add<IApi>(() => ApiImpl(), singleton: true);
  InjectorXBind.add<IUserRepo>(() => UserRepoImpl(), singleton: true);
  InjectorXBind.add<IUserUsecase>(() => UserUsecaseImpl(), singleton: true);
  InjectorXBind.add<IViewModel>(() => ViewModelImpl(), singleton: true);
  InjectorXBind.add<IViewModelTriple>(() => ViewModelTriple(), singleton: true);
}
```

Dessa maneira é referenciado o contrato ao singleton, contudo esse singleton só será gerado uma instância se algum 
objeto subjacente necessite do seu uso, caso contrário o objeto não será posto em memória.


#### Instanciando um novo objeto mesmo tendo registrado em singleton

Existem 2 maneira de fazer isso uma é pelo InjetorXBind como abaixo:

```dart
 IViewModel viewModel = InjectorXBind.get(newInstance: true);
```
Da maneira do exemplo acima, mesmo tendo feito o registo no InjetorXBind como singleton essa chamada trará um nova instância do objeto;

Contudo isso pode ser feito se o Needle de um objeto em específico precisar que toda as vezes a suas injeções sejam instanciadas novamente

Ex no caso do IUserRepo:
```dart
class UserRepoImpl extends Inject<UserRepoImpl> implements IUserRepo {
  /*
  Note o parâmetro newInstance: true na referência no Needle<IApi>
  isso quer dizer que mesmo que o InjectorXBind tenha feito o registro 
  desse contrato em singleton, nesse objeto isso será ignorado e sempre trará 
  uma nova instância de ApiImpl.
  */
  UserRepoImpl() : super(needles: [Needle<IApi>(newInstance: true)]);
  late IApi api;
  @override
  void injector(InjectorX handler) {
    api = handler.get();
  }
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
```

### Testes e injeção de mocks
Injetando ApiMock no UserRepoImp
Existem duas maneiras de fazer isso, uma InjectorXBind.get e outra instanciando a classe diretamente.
Nesse exemplo estou utilizando o Mockito para construção dos mocks

```dart
class ApiMock extends Mock implements IApi {}

void main() {

  _registerDependencies();
  
  late ApiMock apiMock;
  
  setUp(() {
     apiMock = ApiMock();
  });

   /*
   Ex com InjectorXBind.get;
   */
  test("test use InjectorXBind.get", () async {

    when(apiMock.post("", "")).thenAwswer((_) async => true);
    /*
    É utilizado injectMocks da implementação a qual quer testar para substituir as injeções dentro do seu 
    contexto testando e injetando unicamente só o que pertence ao objeto que está mesa de teste, 
    ignorando totalmente tudo que não faz parte desse contexto em específico.
    */
    var userRepoImp = (InjectorXBind.get<IUserRepo>() as UserRepoImpl).injectMocks([NeedleMock<IApi>(mock: apiMock)]);
    var res = await userRepoImp.saveUser("", "");
    expect(res, isTrue);
  });

   /*
   Exemplo por instância;
   */
  test("test use direct implement instance", () async {

    when(apiMock.post("", "")).thenAwswer((_) async => true);
    /*
    É utilizado injectMocks da implementação a qual quer testar para substituir as injeções dentro do seu 
    contexto testando e injetando unicamente só o que pertence ao objeto que está mesa de teste, 
    ignorando totalmente tudo que não faz parte desse contexto em específico.
    Assim a escrita fica mais simplificada contudo tem o mesmo resultado final
    */
    var userRepoImp = UserRepoImpl().injectMocks([NeedleMock<IApi>(mock: apiMock)]);
    var res = await userRepoImp.saveUser("", "");
    expect(res, isTrue);
  });
}
```

Este tipo de injeção de mock pode ser feito qual qualquer objeto relacionado ao InjectorX sendo eles InjectorViewModelTriple, StatefulWidgetInject e Inject, todos eles terão o mesmo comportamento e facilidade.


### Caso queira ajudar dessa doc ou ficou com alguma dúvida deixe sua sugestão de melhoria 
Email: michael.s.lopes@hotmail.com

Assunto: Help InjectorX

LinkedIn: https://linkedin.com/in/michaelslopes/




#### Obrigado a todos e espero que gostem dessa lib e tenham as mesmas vantagens que eu tive a usá-la.