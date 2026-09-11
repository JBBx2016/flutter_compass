import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = 'hemanthraj/flutter_compass';
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(const MethodChannel(channel), (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(const MethodChannel(channel), null);
  });

  Future<void> emit(ByteData data) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(channel, data, (_) => done.complete());
    await done.future;
  }

  test('decodes headings without normalizing the existing Android range', () {
    final event = CompassEvent.fromList([-90, 0, 15]);
    expect(event.heading, -90);
    expect(event.headingForCameraMode, 0);
    expect(event.accuracy, 15);
    expect(CompassEvent.fromList([30, 40, -1]).accuracy, isNull);
  });

  test('missing sensor event has three nullable fields', () {
    final event = CompassEvent.fromList(null);
    expect(event.heading, isNull);
    expect(event.headingForCameraMode, isNull);
    expect(event.accuracy, isNull);
  });

  test(
    'shares a native subscription and cancels after the final listener',
    () async {
      final first = <CompassEvent>[];
      final second = <CompassEvent>[];
      final stream = FlutterCompass.events!;
      final a = stream.listen(first.add);
      final b = stream.listen(second.add);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen']);
      await emit(
        codec.encodeSuccessEnvelope(Float64List.fromList([123, 234, 5])),
      );
      expect(first.single.heading, 123);
      expect(second.single.headingForCameraMode, 234);
      await a.cancel();
      expect(calls, ['listen']);
      await b.cancel();
      expect(calls, ['listen', 'cancel']);
      final c = stream.listen(first.add);
      await Future<void>.delayed(Duration.zero);
      await emit(codec.encodeSuccessEnvelope(null));
      expect(first.last.heading, isNull);
      await c.cancel();
      expect(calls, ['listen', 'cancel', 'listen', 'cancel']);
    },
  );

  test('forwards native errors to stream listeners', () async {
    final errors = <Object>[];
    final subscription = FlutterCompass.events!.listen(
      (_) {},
      onError: errors.add,
    );
    await Future<void>.delayed(Duration.zero);
    await emit(
      codec.encodeErrorEnvelope(
        code: 'unavailable',
        message: 'Sensor unavailable',
      ),
    );
    expect(
      errors.single,
      isA<PlatformException>().having((e) => e.code, 'code', 'unavailable'),
    );
    await subscription.cancel();
  });
}
