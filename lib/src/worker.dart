import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dart_ext/src/tools.dart';

import 'operation.dart';

class TaskRequisites<T> {
  final T value;
  final bool cancelable;

  TaskRequisites(this.value, this.cancelable);
}

///
/// A class responsible for the creation of workers
/// using isolates.
/// Worker completes only one task at any point.
/// Allows task to be canceled through [OperationContext].
/// Aimed at working with cancelable IO tasks.
///
class WorkerConfiguration<T, G> {
  final Isolate _i;
  final SendPort _echoPort;
  ReceivePort _receivePort;
  StreamQueue<dynamic> stream;
  WorkerConfiguration._(
      this._i, this._echoPort, this._receivePort, this.stream);

  /// Creates an instance with initial data and a worker function.
  /// Worker function will be used to parse inputted values
  static Future<WorkerConfiguration<T, G>> functional<T, G, Data>(
      Data data, OperationBd<G> Function(T value, Data data) worker) async {
    var echoReceiver = ReceivePort();
    var isolate = await Isolate.spawn(
        _isolateWork(worker), Pair(echoReceiver.sendPort, data));
    var echoPort = await echoReceiver.first as SendPort;
    var receiver = ReceivePort();
    echoPort.send(receiver.sendPort);
    return WorkerConfiguration._(
        isolate, echoPort, echoReceiver, StreamQueue(receiver));
  }

  Future<Pair<T, G?>> pass(TaskRequisites<T> value) async {
    _echoPort.send(value);
    var result = (await stream.next) as Pair<T, G?>;
    return result;
  }

  Future<Pair<T, G?>> passCancellable(T value) {
    return pass(TaskRequisites(value, true));
  }

  Future<Pair<T, G?>> passUncancellable(T value) {
    return pass(TaskRequisites(value, false));
  }

  Future<void> dispose() async {
    _echoPort.send(null);
    await stream.next;
    _receivePort.close();
    _i.kill(priority: Isolate.beforeNextEvent);
  }
}

///
/// Function responsible for parsing a stream of data
Future<void> Function(Pair<SendPort, Data> pair) _isolateWork<T, G, Data>(
    OperationBd<G> Function(T, Data) worker) {
  return (Pair<SendPort, Data> pair) async {
    var ourReceivePort = ReceivePort();
    pair.a.send(ourReceivePort.sendPort);

    SendPort? sender;
    Pair<TaskRequisites<T>, Operation<G>>? currentFuture;
    ourReceivePort.listen((msg) {
      if (msg == null) {
        // closes the port after all tasks are completed
        if (currentFuture != null) {
          if (currentFuture!.a.cancelable) {
            currentFuture!.b.cancel();
          }
          currentFuture!.b.worker.whenComplete(() {
            ourReceivePort.close();
            sender!.send(null);
          });
          currentFuture!.b.worker.then((value) {
            ourReceivePort.close();
          });
        } else {
          ourReceivePort.close();
        }
      } else if (msg is SendPort) {
        sender = msg;
      } else {
        msg as TaskRequisites<T>;

        if (currentFuture != null) {
          var prevFuture = currentFuture!;
          currentFuture = Pair(
              msg,
              OperationBd((context) async {
                try {
                  if (prevFuture.a.cancelable) {
                    prevFuture.b.cancel();
                  }
                  await prevFuture.b.worker;
                  // ignore: empty_catches
                } catch (e) {}
                return worker(msg.value, pair.b).context(context).worker;
              }).simple());
          currentFuture!.b.worker
              .then((value) => sender!.send(Pair(msg.value, value)),
                  onError: (v, er) {
            sender!.send(Pair(msg.value, null));
          });
        } else {
          currentFuture = Pair(msg, worker(msg.value, pair.b).simple());
          currentFuture!.b.worker
              .then((value) => sender!.send(Pair(msg.value, value)),
                  onError: (v, er) {
            sender!.send(Pair(msg.value, null));
          });
        }
      }
    });
  };
}
