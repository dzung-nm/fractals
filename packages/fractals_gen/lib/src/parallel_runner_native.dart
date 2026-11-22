import 'dart:async';
import 'dart:io';
import 'dart:isolate';

int get parallelism => Platform.numberOfProcessors;

Future<T> runInParallel<T>(FutureOr<T> Function() work) => Isolate.run(work);
