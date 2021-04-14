library exhaustmap_with_trailing;

// Dart imports:
import 'dart:async';

// Package imports:
import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _ExhaustMapWithTrailingStreamSink<S, T> implements ForwardingSink<S, T> {

  _ExhaustMapWithTrailingStreamSink(this._mapper);

  final Stream<T> Function(S? value) _mapper;
  StreamSubscription<T>? _mapperSubscription;
  bool _inputClosed = false;

  S? lastData;

  @override
  void add(EventSink<T> sink, S? data) {
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
          add(sink, lastData);
        } else if (_inputClosed) {
          sink.close();
        }
      },
    );
  }

  @override
  void addError(EventSink<T> sink, dynamic e, [st]) => sink.addError(e, st);

  @override
  void close(EventSink<T> sink) {
    _inputClosed = true;

    if (_mapperSubscription == null) {
      if (lastData != null) {
        add(sink, lastData);
      } else {
        sink.close();
      }
    }
  }

  @override
  FutureOr onCancel(EventSink<T> sink) => _mapperSubscription?.cancel();

  @override
  void onListen(EventSink<T> sink) {}

  @override
  void onPause(EventSink<T> sink, [Future? resumeSignal]) {
    if (lastData != null) {
      add(sink, lastData);
    } else {
      _mapperSubscription?.pause();
    }
  }

  @override
  void onResume(EventSink<T> sink) => _mapperSubscription?.resume();
}

class ExhaustMapWithTrailingStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  ExhaustMapWithTrailingStreamTransformer(this.mapper);

  final Stream<T> Function(S? value) mapper;

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, _ExhaustMapWithTrailingStreamSink<S, T>(mapper));
}

extension ExhaustMapWithTrailingExtension<T> on Stream<T> {

  Stream<S> exhaustMapWithTrailing<S>(Stream<S> Function(T? value) mapper) =>
      transform(ExhaustMapWithTrailingStreamTransformer<T, S>(mapper));
}
