// import 'dart:io';

// import 'worker.dart';
// import 'operation.dart';

// class CounterHolder {
//   int i = 0;
//   CounterHolder();
// }

// void main(List<String> arguments) async {
//   var worker = await WorkerConfiguration.functional(
//       CounterHolder(),
//       (String val, CounterHolder ind) => OperationBd(((context) async {
//             print("Working $val");
//             print("ind ${ind.i}");
//             ind.i++;
//             await Future.delayed(Duration(seconds: 1));
//             await context.check();
//             print("OperationContext running ${context.isRunning}");
//             return val.length;
//           })));

//   print("passed one");
//   await worker.passUncancellable("One").then((value) => print('got $value'));
//   print("passing cancelable two");
//   worker.passCancellable("Two").then((value) => print('got $value'));
//   print("passing three");
//   worker.passUncancellable("Three").then((value) => print("got $value"));
//   await Future.delayed(Duration(seconds: 5));
//   worker.dispose();

//   exit(0);
// }

import 'package:dart_ext/src/operation.dart';



void main(List<String> args) {
  var operation = Operation(((context) async {

    /*
      do something intense
    */
    await context.check();
    /*
      do something intense
    */
  }));
}
