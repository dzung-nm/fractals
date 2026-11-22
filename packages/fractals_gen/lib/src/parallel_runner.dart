import 'dart:async';

import 'parallel_runner_web.dart'
    if (dart.library.isolate) 'parallel_runner_native.dart'
    as implementation;

/// Uses a native isolate when available, or the current event loop on web.
Future<T> runInParallel<T>(FutureOr<T> Function() work) =>
    implementation.runInParallel(work);

/// The number of chunks that may safely run in parallel on this platform.
int get parallelism => implementation.parallelism;
