

class InterruptedException implements Exception {}

///
/// Context in which operations run
///
class OperationContext {
  bool _isRunning = true;

  bool get isRunning => _isRunning;
  Future<void> check() async {
    await Future.delayed(Duration.zero);
    if (!_isRunning) throw InterruptedException();
  }
}

///
/// A cancelable operation.
/// Allows for cooperative cancellation of tasks.
class Operation<T> {
  OperationContext _context;
  final Future<T> Function(OperationContext context) _v;
  Future<T>? _worker;
  Future<T> get worker {
    if (_worker != null) {
      return _worker!;
    } else {
      _worker = _v.call(_context);
      return _worker!;
    }
  }

  Operation(this._v) : _context = OperationContext();
  Operation.contextual(this._v, this._context);
  void cancel() {
    _context._isRunning = false;
  }

  Operation<T> extend(Operation<T> op) {
    _context = op._context;
    return this;
  }
}

///
/// Operation builder
/// Responsible for creating operations with a given context
class OperationBd<T> {
  final Future<T> Function(OperationContext context) _worker;

  OperationBd(this._worker);

  Operation<T> o<G>(Operation<G> op) =>
      Operation.contextual(_worker, op._context);
  Operation<T> context<G>(OperationContext context) =>
      Operation.contextual(_worker, context);
  Operation<T> simple() => Operation(_worker);
}
