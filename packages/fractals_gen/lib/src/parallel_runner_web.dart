import 'dart:async';

/// Dart web targets do not support dart:isolate.
int get parallelism => 1;

Future<T> runInParallel<T>(FutureOr<T> Function() work) async => work();
