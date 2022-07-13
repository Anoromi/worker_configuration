import 'dart:io';
import 'dart:typed_data';

import 'operation.dart';
import 'worker.dart';

OperationBd<Uint8List> work(int count, RandomAccessFile file) =>
    OperationBd(((context) async {
      /*
        Some intense work
      */
      return file.read(count);
    }));

void main(List<String> arguments) async {
  var worker = await WorkerConfiguration.functional(
      await File("path").open(), // pass initial data
      work // pass worker function
      );

  await worker.passUncancellable(1);
  worker.passCancellable(2); // will be canceled by the next request
  await worker.passCancellable(
      3); // won't be canceled because it will have enough time for completion
  await Future.delayed(Duration(seconds: 1));
  await worker.passUncancellable(4);
  worker.dispose(); // stops the worker while completing previously called tasks

  exit(0);
}