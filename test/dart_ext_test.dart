import 'dart:io';
import 'dart:isolate';

import 'package:dart_ext/dart_ext.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {

    test("Worker test", () async {
      var conf = await WorkerConfiguration.functional<String, int, void>(
          null,
          (v, d) => OperationBd((context) async {
                await Future.delayed(Duration(seconds: 1));
                await context.check();
                return v.length;
              }));
      conf.stream.rest.listen((event) {
        print("Nya $event");
      }, onError: (a, b) {
        print("Error");
      });
      conf.passCancellable("1");
      await Future.delayed(Duration(milliseconds: 500));
      conf.passCancellable("2");
      await Future.delayed(Duration(milliseconds: 500));
      conf.passCancellable("3");
      await Future.delayed(Duration(milliseconds: 3200));
      conf.passCancellable("4");
      await Future.delayed(Duration(seconds: 3));
    });

    test("Cancelable test", () async {
      var worker = OperationBd((context) async {
        print("1");
        print("2");
        print("3");
        await Future.delayed(Duration(seconds: 1));
        print(context.isRunning);
        await context.check();
        print("4");
      }).si();

      worker.worker.then((value) => print(value),
          onError: (v, e) => print("Error $v, $e"));
      await Future.delayed(Duration.zero);
      worker.cancel();
      await Future.delayed(Duration(seconds: 2));
    });
  });
}
