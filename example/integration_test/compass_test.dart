import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real compass emits again after cancellation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Compass sensor test'))),
    );
    final stream = FlutterCompass.events!;
    for (var attempt = 0; attempt < 2; attempt++) {
      final event = await stream.first.timeout(const Duration(seconds: 15));
      expect(
        event.heading,
        isNotNull,
        reason: 'Run this test on a device with compass sensors',
      );
      expect(event.heading!.isFinite, isTrue);
      expect(event.heading, inInclusiveRange(-180, 360));
      // Stream.first cancels its native subscription before the next iteration.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }, timeout: const Timeout(Duration(seconds: 45)));
}
