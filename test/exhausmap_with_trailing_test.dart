// Package imports:
import 'package:rxdart/subjects.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:exhaustmap_with_trailing/exhaustmap_with_trailing.dart';

Future delay(int milliseconds) async {
  if (milliseconds == 0) {
    return Future.delayed(Duration.zero);
  }
  return Future.delayed(Duration(milliseconds: milliseconds));
}

class _WaitFor<T> {

  const _WaitFor(this.value, [ this.milliseconds = 0]);

  final int milliseconds;
  final T value;

  @override
  String toString() {
    return '$value';
  }
}

void main() {

  group('exhausmap with trailing', () {

    test('skips events that fall behind', () async {

        final subject = PublishSubject();

        final waitFor = expectLater(subject.stream.exhaustMapWithTrailing((w) async* {
          if (w == null) {
            yield null;
          }
          if (w!.milliseconds > 0) {
            await Future.delayed(Duration(milliseconds: w.milliseconds));
          } else {
            await Future.delayed(Duration.zero);
          }
          yield w.value;
        }), emitsInOrder([
          1, 2, 3, 4, 5
        ]));

        subject.add(const _WaitFor(1, 5)); // should run
        await delay(6);
        subject.add(const _WaitFor(2, 300)); // should run
        await delay(10);
        subject.add(const _WaitFor(-1, 10)); // skip
        await delay(10);
        subject.add(const _WaitFor(-2)); // skip
        await delay(10);
        subject.add(const _WaitFor(-3, 10)); // skip
        await delay(10);
        subject.add(const _WaitFor(3, 10)); // should run
        await delay(300);
        subject.add(const _WaitFor(4)); // should run
        await delay(10);
        subject.add(const _WaitFor(5)); // should run

        await waitFor;
      });

  });

}
