## Summary

A library for creating cancelable operations and workers using dart isolates.

**Author: Andrii Zahorulko**

## Operation

Operation is a wrapper around future which gives
the ability to cancel a task.
For example, you can use it when
a future for reading a file is obsolete.

In a normal scenario you would need to
wait for the future to complete **or else
2 functions using the same data**

You can solve it by duplication but that might become
cumbersome. Also, that future you ignored will still eat away
your computational power.

As such, Operation aims to create cancelable tasks.

```dart
  var operation = Operation(((context) async {
    /*
      do something intense
    */
    await context.check();
    /*
      do something intense
    */
  }));
```

By checking the context we not only cycle out other
functions in the event loop (and consequently allow other work to be done), but also check if the operation was canceled.

The issue comes when we want check
context inside other function. We can pass the context as
a parameter.

```dart
  var operation = Operation(((context) async {
    await someVeryIntenseFunction(context);
    /*
      do something else
    */
  }));
```

Or you can use **OperationBd**.

```dart
  OperationBd<Result> someVeryIntenseFunction() =>
    OperationBd((context) {
        /*
            intense work
        */
    });
  var operation = Operation(((context) async {
    await someVeryIntenseFunction().context(context).worker;
    /*
      do something else
    */
  }));
```

## Worker

First we create a worker

```dart
  var worker = await WorkerConfiguration.functional(
      await File("path").open(), // pass initial data
      work // pass worker function
      );
```

We also need a function that returns OperationBd

```dart
OperationBd<Uint8List> work(int count, RandomAccessFile file) =>
    OperationBd(((context) async {
      /*
        Some intense work
      */
      return file.read(count);
    }));
```

Then we pass values to a worker and get a future.
We can also make requests cancelable, for something like
user input based suggestions

```dart
  await worker.passUncancellable(1);
  worker.passCancellable(2); // will be canceled by the next request
  await worker.passCancellable(
      3); // won't be canceled because it will have enough time for completion
  await Future.delayed(Duration(seconds: 1));
  await worker.passUncancellable(4);
```
