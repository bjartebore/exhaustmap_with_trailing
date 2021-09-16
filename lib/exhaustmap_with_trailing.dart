library exhaustmap_with_trailing;

// Dart imports:
import 'dart:async';

// Package imports:
import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _ExhaustMapWithTrailingStreamSink<S, T> extends ForwardingSink<S, T> {

  _ExhaustMapWithTrailingStreamSink(this._mapper);

  final Stream<T> Function(S? value) _mapper;
  StreamSubscription<T>? _mapperSubscription;
  bool _inputClosed = false;

  S? lastData;

  @override
  void onData(S? data) {
    if (_mapperSubscription != null) {
      // save the last if there are any
      lastData = data;
      return;
    }
    // reset last since we are processing it
    lastData = null;

    final mappedStream = _mapper(data);

    _mapperSubscription = mappedStream.listen(
      sink.add,
      onError: sink.addError,
      onDone: () {
        _mapperSubscription = null;

        if (!_inputClosed && lastData != null) {
          onData(lastData);
        } else if (_inputClosed) {
          sink.close();
        }
      },
    );
  }

  @override
  void onError(Object error, StackTrace st) => sink.addError(error, st);

  @override
  void onDone() {
    _inputClosed = true;

    if (_mapperSubscription == null) {
      if (lastData != null) {
        onData(lastData);
      } else {
        sink.close();
      }
    }
  }

  @override
  FutureOr onCancel() => _mapperSubscription?.cancel();

  @override
  void onListen() {}

  @override
  void onPause([Future? resumeSignal]) {
    if (lastData != null) {
      onData(lastData);
    } else {
      _mapperSubscription?.pause();
    }
  }

  @override
  void onResume() => _mapperSubscription?.resume();

}

class ExhaustMapWithTrailingStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  ExhaustMapWithTrailingStreamTransformer(this.mapper);

  final Stream<T> Function(S? value) mapper;

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, () => _ExhaustMapWithTrailingStreamSink<S, T>(mapper));
}

extension ExhaustMapWithTrailingExtension<T> on Stream<T> {

  Stream<S> exhaustMapWithTrailing<S>(Stream<S> Function(T? value) mapper) =>
      transform(ExhaustMapWithTrailingStreamTransformer<T, S>(mapper));
}
