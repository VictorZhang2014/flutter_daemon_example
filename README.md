# Flutter BLE Daemon Example

This project demonstrates how to build a Flutter application that maintains a persistent background connection with a Bluetooth Low Energy (BLE) device, processes received messages, triggers local push notifications, and calls backend APIs—even after the user closes the application's UI.

## What this Project Does

This example proves the technical feasibility of running a "daemon-like" background isolate in Dart/Flutter. The core workflow is:

1. The app requests necessary native permissions (Bluetooth, Location, Notifications, Battery Optimization).
2. The UI starts a background service isolate.
3. Once running, the UI can be safely minimized or completely closed natively.
4. The isolated background process continues to listen for BLE characteristic updates from connected devices.
5. Upon receiving a message (or triggered by a mock event from the UI before closing), the background task:
   - Delays execution to simulate an incoming message while the app is dead.
   - Pushes a high-priority local system notification.
   - Triggers an HTTP network request to a backend API using `Dio`.

## Required Permissions

To render this daemon executable, you must declare the following platform-specific permissions.

### Android (`AndroidManifest.xml`)
Add the following `<uses-permission>` tags:
```xml
<!-- Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />

<!-- Bluetooth & Location -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Background execution & Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### iOS (`Info.plist`)
Add the following keys to your `ios/Runner/Info.plist`:
```xml
<!-- Bluetooth Permissions -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth to connect to devices even in the background.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>We need Bluetooth to connect to devices.</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>fetch</string>
</array>
```

## Libraries Used

- **[`flutter_background_service`](https://pub.dev/packages/flutter_background_service)**: Core engine that spins up a separate isolated Dart execution context (Foreground Service on Android, Background Fetch on iOS).
- **[`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus)**: Handles BLE scanning, connection, and characteristic listener streams. Fully supports Isolate execution.
- **[`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)**: For triggering local system push notifications directly from the background process. 
- **[`dio`](https://pub.dev/packages/dio)**: To invoke RESTful backend APIs silently in the background.
- **[`permission_handler`](https://pub.dev/packages/permission_handler)**: For requesting runtime permissions and managing battery optimization whitelists.

## Platform Support & Limitations

### Android
**Support Level: Excellent ✅**

- **Foreground Service**: The app uses a sticky Foreground Service (`ForegroundServiceType="connectedDevice"`) combined with `android:stopWithTask="false"`. 
- **Background Survival**: The background isolate survives the App being swiped from the Recent Tasks list.
- **Notifications & Networking**: Fully supported without limits at any time.
- **Caution / Caveat**: On extensively modified manufacturer ROMs (e.g., Huawei HarmonyOS, Xiaomi HyperOS, OPPO ColorOS), the OS's proprietary battery manager might forcefully terminate the app despite standard Android configurations. Users **must** manually whitelist the app (Allow Auto-launch, Allow Background Run) and ignore battery optimizations for guaranteed permanence.

### iOS
**Support Level: Moderate / Restricted ⚠️**

- **Background BLE**: iOS natively supports waking up the app for BLE events even in the background if configured with `UIBackgroundModes` containing `bluetooth-central`. 
- **Manual Swipes**: If the user explicitly force-quits the app by swiping it up in the iOS App Switcher, iOS violently terminates all background execution and Bluetooth hooks. The app **cannot** be restarted in the background by BLE events until the user manually opens the UI again.
- **Background Execution Time**: General background execution isolates on iOS are restricted and subjected to the OS's scheduling (`BGTaskScheduler`). Continuous background looping without active BLE audio or location services may be throttled or killed by iOS.
