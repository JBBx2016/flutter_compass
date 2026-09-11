# flutter_compass

A Flutter compass for Android and iOS. This repository maintains the Kolumbus
fork of [flutter_compass](https://github.com/hemanthrajv/flutter_compass).

## Usage

Depend on a reviewed, immutable commit of this repository:

```yaml
dependencies:
  flutter_compass:
    git:
      url: https://github.com/JBBx2016/flutter_compass.git
      ref: <full-reviewed-commit-sha>
```

```dart
final subscription = FlutterCompass.events!.listen((event) {
  final heading = event.heading;
  if (heading == null) {
    // Compass sensors are unavailable on this Android device.
    return;
  }
  // Use heading and event.accuracy.
});

// Release native sensors when the compass is no longer needed.
await subscription.cancel();
```

## Compatibility

- Flutter 3.44 or later; Dart 3.9 or later. Flutter 3.44 introduced AGP 9
  compatibility; the example uses built-in Kotlin available with Flutter 3.47.
- Android: compile SDK 36, Java 17, AGP 9.1.0 / Gradle 9.3.1.
  The plugin keeps its Android API 21 floor; the consuming Flutter version can
  require a higher floor. Android remains Java and does not apply a Kotlin plugin.
- iOS: plugin deployment target 14.0, CocoaPods or Swift Package Manager.
  Current Flutter and the example require iOS 15.0. SwiftPM requires Swift 5.9.
- Android and iOS provide sensor data. On web the stream is empty; other desktop
  platforms are unsupported.

## Event contract and lifecycle

The existing Dart API and event-channel name remain unchanged.

| Field | Meaning |
|---|---|
| `heading` | Magnetic heading. iOS reports 0–360 degrees; the existing Android azimuth is -180–180 degrees. Zero is north. |
| `headingForCameraMode` | iOS heading out of the back of the device; Android retains its existing zero placeholder. |
| `accuracy` | iOS platform heading accuracy; Android estimates 15/30/45 degrees from sensor status, or null when unknown. |

Android emits a null heading when the required sensors are absent. Errors from
the native event channel are forwarded to stream listeners.

Listeners share one broadcast subscription. Cancelling the last listener stops
native heading and motion updates; a later listener starts them again. Android
also unregisters sensors when its Flutter engine detaches.

The fork's iOS behavior is preserved: magnetic north, a 5-degree heading filter,
motion sampling at 3 Hz, and motion updates only while subscribed. The original
background fix is cancellation-driven: it does **not** automatically cancel an
active subscription when the app backgrounds. Apps must cancel their compass
subscription when their UI/lifecycle no longer needs it. Pausing a Dart stream
subscription alone does not release native sensors.

## Permissions and privacy

The plugin does not request permissions, persist readings, or transmit data.
Android accelerometer/magnetometer readings at this sampling rate do not require
location permission. The example retains its explicit foreground-location
permission demonstration; it never requests background location.

For iOS apps that request location authorization, provide a meaningful
`NSLocationWhenInUseUsageDescription`. Review the app's motion permission usage
and provide `NSMotionUsageDescription` when required. This plugin does not use
Apple's required-reason API categories (file timestamps, disk space, boot time,
user defaults, or active keyboards), so it does not add an empty privacy manifest.
The host app remains responsible for declarations covering its full data use.

## Development

```sh
fvm flutter pub get
fvm dart format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test
fvm flutter analyze
fvm flutter test
cd example
fvm flutter test
fvm flutter build apk --debug
fvm flutter build apk --release
fvm flutter build ios --simulator
cd android
./gradlew :flutter_compass:testDebugUnitTest
```

The example enables SwiftPM per project. To verify CocoaPods, temporarily set
`flutter.config.enable-swift-package-manager` to `false` in the example's
pubspec, run the iOS build, then restore it to `true`. No global Flutter setting
needs to change. The example uses permission_handler 12.0.3 to retain SDK 36;
13.x requires SDK 37.

See [validation and device checks](docs/modernization.md) for the tested
toolchains, preserved fork differences, and remaining runtime checks.
