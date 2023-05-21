import 'dart:async';

class AsyncTask {
  CancellationToken cancellationToken = CancellationToken();
  Task task = Task();

  Future<void> execute(
      CancellationToken cancellationToken, Function function) async {
    task.execute(cancellationToken, function);
  }

  Future<void> createFuture() async {
    final completer = Completer<void>();
    final future = completer.future;
    
    return await future;
  }

  void cancel() {
    cancellationToken._isCancelled = true;
  }
}

class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class Task {
  Future<void> execute(
      CancellationToken cancellationToken, Function function) async {
    while (!cancellationToken.isCancelled) {
      function();
    }
  }
}
