import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background service initialization
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'BLE Background Service', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'BLE daemon',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // For flutter_local_notifications initialization in background
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Listen for the mock message from UI, delay 5s, then push notification
  service.on('mock_ble_message').listen((event) async {
    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(seconds: 5));
      _handleBleMessage("Test from background after app closed ($i/3)!".codeUnits, flutterLocalNotificationsPlugin);
    }
  });

  // Example: Mock BLE event loop
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "BLE daemon running",
          content: "Listening for BLE messages at ${DateTime.now().hour}:${DateTime.now().minute}",
        );
      }
    }
  });

  /*
  // REAL BLE LOGIC:
  // Hook into system events if a message arrives
  // This assumes the device is connected before app goes to background
  
  final List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
  for (var device in connectedDevices) {
    // Check for target device
    if (device.remoteId.str == "YOUR_DEVICE_MAC") {
       List<BluetoothService> services = await device.discoverServices();
       for (var s in services) {
         for (var c in s.characteristics) {
           if (c.properties.notify || c.properties.indicate) {
             await c.setNotifyValue(true);
             c.onValueReceived.listen((value) {
                // HANDLE BLE MESSAGE
                _handleBleMessage(value, flutterLocalNotificationsPlugin);
             });
           }
         }
       }
    }
  }
  */
}

// Function to handle BLE message, show notification and trigger API
Future<void> _handleBleMessage(
  List<int> value, 
  FlutterLocalNotificationsPlugin plugin
) async {
  String message = String.fromCharCodes(value);
  
  // 1. Show Local Push Notification
  await plugin.show(
    id: 0,
    title: 'Received BLE Message',
    body: 'Device says: $message',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'my_foreground',
        'BLE Background Service',
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );

  // 2. Call backend API
  try {
    final dio = Dio();
    // Simulate API call
    final response = await dio.post(
      'https://jsonplaceholder.typicode.com/posts',
      data: {'message': message},
    );
    print("API Response: ${response.statusCode}");
  } catch (e) {
    print("API Error: $e");
  }
}
