abstract class Finalizer {
  void finalize();
}

class CloseFinalizer extends Finalizer {
  final dynamic value;
  CloseFinalizer(this.value);

  @override
  void finalize() => value.close();
}

class FinalizerPool {
  static final instance = FinalizerPool();

  final _pools = <List<Finalizer>>[];

  void _prepare() => _pools.add(<Finalizer>[]);
  void _cleanup() => _pools.removeLast().reversed.forEach((f) => f.finalize());

  void register(Finalizer finalizer) => _pools.last.add(finalizer);

  void runSync(void Function() func) {
    _prepare();

    try {
      func();
    } finally {
      _cleanup();
    }
  }

  Future<void> runAsync(Future Function() func) async {
    _prepare();

    try {
      await func();
    } finally {
      _cleanup();
    }
  }
}
