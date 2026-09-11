import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class CompassEvent {
  /// Magnetic heading in degrees: iOS 0–360, Android -180–180; zero is north.
  /// Null when compass sensors are unavailable.
  final double? heading;

  /// iOS heading out of the back of the device; Android returns zero.
  final double? headingForCameraMode;

  /// Estimated deviation in degrees, or null when unknown.
  /// iOS supplies platform accuracy; Android estimates 15, 30 or 45 degrees.
  final double? accuracy;

  CompassEvent.fromList(List<double>? data)
    : heading = data?[0],
      headingForCameraMode = data?[1],
      accuracy = (data == null) || (data[2] == -1) ? null : data[2];

  @override
  String toString() {
    return 'heading: $heading\nheadingForCameraMode: $headingForCameraMode\naccuracy: $accuracy';
  }
}

/// [FlutterCompass] is a singleton class that provides access to compass events.
/// See [CompassEvent.heading] for the platform-specific heading range.
class FlutterCompass {
  static final FlutterCompass _instance = FlutterCompass._();

  factory FlutterCompass() {
    return _instance;
  }

  FlutterCompass._();

  static const EventChannel _compassChannel = EventChannel(
    'hemanthraj/flutter_compass',
  );
  static Stream<CompassEvent>? _stream;

  /// Provides a [Stream] of compass events that can be listened to.
  static Stream<CompassEvent>? get events {
    if (kIsWeb) {
      return const Stream<CompassEvent>.empty();
    }
    _stream ??= _compassChannel.receiveBroadcastStream().map(
      (dynamic data) => CompassEvent.fromList(data?.cast<double>()),
    );
    return _stream;
  }
}
