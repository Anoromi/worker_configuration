
class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);

  @override
  String toString() {
    return "($a, $b)";
  }
}

class Result<T, Err> {
  final T? _v;
  final Err? _err;
  final bool _hasValue;

  T get unwrap => _hasValue ? _v! : throw Exception("No value");
  Err get unwrapErr => !_hasValue ? _err! : throw Exception("No value");

  bool get isOk => _hasValue;
  bool get isErr => !_hasValue;

  Result.ok(T v)
      : _v = v,
        _err = null,
        _hasValue = true;
  Result.err(Err err)
      : _v = null,
        _err = err,
        _hasValue = true;
}
