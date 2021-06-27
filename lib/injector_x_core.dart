class InjectionNotFound implements Exception {
  InjectionNotFound(this.message);
  final String message;
}

abstract class INeedle<T> {
  Type getType();
  T? getMock();
  bool isNewInstance();
}

class Needle<T> implements INeedle<T> {
  late Type type;
  final bool newInstance;
  Needle({this.newInstance = false}) {
    type = T;
  }

  @override
  T? getMock() {
    return null;
  }

  @override
  Type getType() {
    return this.type;
  }

  @override
  bool isNewInstance() {
    return this.newInstance;
  }
}

class NeedleMock<T> implements INeedle<T> {
  late Type type;
  final T mock;

  NeedleMock({Type? type, required this.mock}) {
    if (type == null) {
      this.type = T;
    } else {
      this.type = type;
    }
  }

  @override
  T? getMock() {
    return mock;
  }

  @override
  Type getType() {
    return this.type;
  }

  @override
  bool isNewInstance() {
    return true;
  }
}

abstract class Injectable {
  final List<INeedle>? needles;
  Injectable({this.needles});
}

typedef InjectableAdd<T> = T Function();

class _InjectStore<T extends Object> {
  final String key;
  final InjectableAdd<T> injectable;
  final bool isSingleton;
  dynamic singleton;
  _InjectStore({
    required this.key,
    required this.singleton,
    required this.injectable,
    required this.isSingleton,
  });
}

class InjectorXBind {
  static final List<_InjectStore> _store = [];

  static String getKey(String key) {
    var kArr = key.split("<");
    if (kArr.isNotEmpty) {
      return kArr[0];
    } else {
      return key;
    }
  }

  static bool _checkKeyExists(String key) {
    return _store.where((e) => e.key == key).isNotEmpty;
  }

  static void add<T extends Object>(InjectableAdd<T> injectable,
      {bool singleton = false}) {
    var key = getKey(T.toString());
    if (_checkKeyExists(key)) {
      replace<T>(injectable);
    }
    _store.add(_InjectStore<T>(
      key: key,
      singleton: null,
      injectable: injectable,
      isSingleton: singleton,
    ));
  }

  static void replace<T extends Object>(InjectableAdd<T> injectable,
      {bool singleton = false}) {
    var key = getKey(T.toString());
    var list = _store.where((e) => e.key == key).toList();
    if (list.isNotEmpty) {
      _store.removeWhere((e) => e.key == key);
      _store.add(_InjectStore<T>(
        key: key,
        singleton: null,
        injectable: injectable,
        isSingleton: singleton,
      ));
    }
  }

  static T get<T extends Object>({bool newInstance = false}) {
    try {
      return getByType(T, newInstance: newInstance) as T;
    } on Exception catch (e) {
      throw e;
    }
  }

  static dynamic getByType(Type type, {bool newInstance = false}) {
    var key = getKey(type.toString());
    if (!_checkKeyExists(key)) {
      throw InjectionNotFound("Injection not found from ${type.toString()}.");
    }

    var ref = _store.where((e) => e.key == key).first;

    if (!ref.isSingleton) {
      return ref.injectable();
    } else {
      if (!newInstance) {
        var singleton = ref.singleton;
        if (singleton == null) {
          ref.singleton = ref.injectable();
        }
        return ref.singleton;
      } else {
        return ref.injectable();
      }
    }
  }
}

class InjectorX {
  InjectorX(this.injectNeedles) {
    for (var needle in injectNeedles) {
      var _key = InjectorXBind.getKey(needle.getType().toString());
      if (needle.getMock() != null) {
        _refs[_key] = needle.getMock();
      } else {
        var obj = InjectorXBind.getByType(needle.getType(),
            newInstance: needle.isNewInstance());
        _refs[_key] = obj;
      }
    }
  }

  final List<INeedle> injectNeedles;
  final Map<String, dynamic> _refs = {};

  T get<T>() {
    var key = InjectorXBind.getKey(T.toString());
    if (_refs.containsKey(key)) {
      return _refs[key];
    } else {
      print("The injection reference ${T.toString()} is not found");
      throw InjectionNotFound(
          "The injection reference ${T.toString()} is not found");
    }
  }
}

abstract class Inject<T extends Inject<T>> extends Injectable {
  Inject({List<Needle>? needles}) : super(needles: needles) {
    this.injector(InjectorX(needles ?? []));
  }

  T injectMocks(List<NeedleMock> needleMocks) {
    var localNeedles = <INeedle>[];
    if (this.needles != null) {
      for (var arg in needleMocks) {
        localNeedles = this
            .needles!
            .where((e) =>
                InjectorXBind.getKey(e.getType().toString()) !=
                InjectorXBind.getKey(arg.type.toString())
                    .replaceAll("Mock", ""))
            .toList();
      }
    }

    needleMocks.addAll(
        localNeedles.map((e) => NeedleMock(type: e.getType(), mock: null)));
    this.injector(InjectorX(needleMocks));
    return this as T;
  }

  void injector(InjectorX handler);
}
