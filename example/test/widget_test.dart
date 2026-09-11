// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('backgrounding cancels sensors and resuming listens again', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hemanthraj/flutter_compass'),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();
    expect(calls, ['listen']);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls, ['listen', 'cancel']);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, ['listen', 'cancel', 'listen']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls, ['listen', 'cancel', 'listen', 'cancel']);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hemanthraj/flutter_compass'),
      null,
    );
  });

  testWidgets('explains denied permission without subscribing to sensors', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var compassListens = 0;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 0,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hemanthraj/flutter_compass'),
      (_) async {
        compassListens++;
        return null;
      },
    );
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Location Permission Required'), findsOneWidget);
    expect(find.text('Request Permissions'), findsOneWidget);
    expect(compassListens, 0);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hemanthraj/flutter_compass'),
      null,
    );
  });
}
