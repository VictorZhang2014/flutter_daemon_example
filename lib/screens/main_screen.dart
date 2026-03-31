import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
      Permission.ignoreBatteryOptimizations, // Request battery optimization ignore
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Background Daemon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isRunning();
                if (!isRunning) {
                  service.startService();
                } else {
                  service.invoke('setAsForeground');
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service Started! Look at notification bar.')),
                  );
                }
              },
              child: const Text('Start Background Service'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final service = FlutterBackgroundService();
                service.invoke('stopService');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service Stopped')),
                  );
                }
              },
              child: const Text('Stop Service'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                 final service = FlutterBackgroundService();
                 
                 // Send event to the background Isolate
                 service.invoke('mock_ble_message');
                 
                 // Close the UI / App
                 if (Platform.isAndroid) {
                   SystemNavigator.pop();
                 } else {
                   exit(0);
                 }
              },
              child: const Text('Mock Received BLE Message (Closes App)'),
            ),
          ],
        ),
      ),
    );
  }
}
