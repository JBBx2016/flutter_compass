import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _hasPermissions = false;
  bool _isResumed = true;
  final _events = StreamController<CompassEvent>.broadcast();
  StreamSubscription<CompassEvent>? _compassSubscription;
  CompassEvent? _lastRead;
  String? _lastReadError;
  DateTime? _lastReadAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fetchPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    _events.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _isResumed = state == AppLifecycleState.resumed);
    _updateCompassSubscription();
    if (_isResumed) _fetchPermissionStatus();
  }

  void _updateCompassSubscription() {
    if (_isResumed && _hasPermissions) {
      _compassSubscription ??= FlutterCompass.events!.listen(
        _events.add,
        onError: _events.addError,
      );
    } else {
      // Cancel immediately: the framework may not render another frame while paused.
      _compassSubscription?.cancel();
      _compassSubscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Flutter Compass')),
        body: Builder(
          builder: (context) {
            if (!_isResumed) {
              return const Center(child: Text('Compass paused'));
            }
            if (_hasPermissions) {
              return Column(
                children: <Widget>[
                  _buildManualReader(),
                  Expanded(child: _buildCompass()),
                ],
              );
            } else {
              return _buildPermissionSheet();
            }
          },
        ),
      ),
    );
  }

  Widget _buildManualReader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          ElevatedButton(
            child: Text('Read Value'),
            onPressed: () async {
              try {
                final event = await _events.stream.first.timeout(
                  const Duration(seconds: 15),
                );
                if (!mounted) return;
                setState(() {
                  _lastRead = event;
                  _lastReadAt = DateTime.now();
                  _lastReadError = null;
                });
              } catch (error) {
                if (!mounted) return;
                setState(
                  () => _lastReadError = 'Unable to read heading: $error',
                );
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _lastReadError ?? '$_lastRead',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$_lastReadAt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: _events.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null) {
          return Center(child: Text("Device does not have sensors !"));
        }

        return Material(
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            padding: EdgeInsets.all(16.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Transform.rotate(
              angle: (direction * (math.pi / 180) * -1),
              child: Image.asset('assets/compass.jpg'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Location Permission Required'),
          ElevatedButton(
            child: Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          ),
        ],
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
        _updateCompassSubscription();
      }
    });
  }
}
