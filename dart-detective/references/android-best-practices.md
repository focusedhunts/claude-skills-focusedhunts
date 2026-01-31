# Android Best Practices for Flutter Apps

This reference covers Android-specific patterns, lifecycle management, permissions, and platform integration best practices for Flutter applications.

## Table of Contents
- [Android Lifecycle & State Management](#android-lifecycle--state-management)
- [Permissions Handling](#permissions-handling)
- [Platform Channels](#platform-channels)
- [Services & Background Execution](#services--background-execution)
- [Manifest Configuration](#manifest-configuration)
- [Resource Management](#resource-management)
- [Navigation & Activity Management](#navigation--activity-management)
- [Kotlin/Java Interoperability](#kotlinjava-interoperability)

---

## Android Lifecycle & State Management

### Understanding Android App Lifecycle
Flutter apps run on Android within the main activity lifecycle:
- **onCreate** → **onStart** → **onResume** (running)
- **onPause** → **onStop** → **onDestroy** (terminated)
- **onPause** → **onResume** (app backgrounded then restored)

### DO: Lifecycle-Aware Patterns
- Persist critical state when `onPause` is called
- Cancel network requests/subscriptions in `onPause`
- Clear sensitive data in memory when app pauses
- Use `AppLifecycleState` for Dart-level lifecycle management
- Properly manage Riverpod/Bloc providers through lifecycle changes

### DON'T: Lifecycle Anti-Patterns
- ❌ Assume `onDestroy` always runs (it often doesn't)
- ❌ Leave long-running operations in memory after pause
- ❌ Store UI state in native code expecting persistence
- ❌ Ignore background execution restrictions (Android 8+)

### Check these patterns
```dart
// ✅ CORRECT - AppLifecycleListener with state cleanup
import 'package:flutter/services.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App moved to background - save state, clear sensitive data
        _saveAppState();
        _clearSensitiveMemory();
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground
        _restoreAppState();
        break;
      case AppLifecycleState.detached:
        // App will be terminated
        _cleanup();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

---

## Permissions Handling

### DO: Proper Permission Request Flow
- Request permissions at runtime (Android 6+)
- Group related permissions logically
- Request only truly necessary permissions
- Handle denial gracefully with fallback UX
- Explain why each permission is needed (with rationale)
- Use `permission_handler` or `flutter_native_contact_picker` packages

### Common Permissions for Password Managers
- `READ_CONTACTS` (if importing credentials from contacts)
- `CAMERA` (for biometric scanning or QR code imports)
- `INTERNET` (for sync and API communication)
- `WRITE_SECURE_SETTINGS` (not recommended, very restricted)

### DON'T: Permission Anti-Patterns
- ❌ Request permissions at app startup blindly
- ❌ Request all permissions at once without context
- ❌ Ignore permission denial and crash
- ❌ Request unnecessary permissions
- ❌ Don't provide rationale for permission request
- ❌ Re-request immediately after denial

### Check these patterns
```dart
// ❌ WRONG - Requests permissions without context
void initState() {
  super.initState();
  _requestAllPermissions(); // Wrong - no context, no fallback
}

// ✅ CORRECT - Context-aware permission request
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();

  if (status.isDenied) {
    // Permission denied, provide fallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(text: 'Camera permission required to scan QR codes'),
    );
  } else if (status.isPermanentlyDenied) {
    // Permanently denied, guide user to settings
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text('Camera permission is required but was permanently denied.'),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  } else if (status.isGranted) {
    // Permission granted, proceed
    _openCamera();
  }
}
```

---

## Platform Channels

### DO: Safe Platform Communication
- Use strongly-typed platform channel data (avoid dynamic Map)
- Validate data received from platform code
- Handle native exceptions gracefully
- Document expected message format
- Use `StandardMethodCodec` for JSON-compatible data
- Implement error handling on both sides (Dart and Kotlin/Java)

### DON'T: Unsafe Platform Patterns
- ❌ Send unvalidated data to native code
- ❌ Trust native code return values without validation
- ❌ Ignore exceptions from platform channels
- ❌ Pass credentials through platform channels unnecessarily
- ❌ Use platform channels for high-frequency calls (use native plugins instead)
- ❌ Log sensitive data in platform channel calls

### Check these patterns
```dart
// ❌ WRONG - Unvalidated platform channel communication
Future<void> callNativeFunction(Map<String, dynamic> data) async {
  try {
    final result = await _channel.invokeMethod('process', data);
    _processResult(result); // No validation
  } catch (e) {
    print('Error: $e'); // Might log sensitive data
  }
}

// ✅ CORRECT - Typed, validated platform channel
class NativeService {
  static const platform = MethodChannel('com.example.app/native');

  Future<NativeResponse> callNativeFunction(String data) async {
    try {
      if (data.isEmpty) {
        throw ArgumentError('Data cannot be empty');
      }

      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'process',
        {'data': data},
      );

      // Validate response type
      if (result == null || result is! Map<dynamic, dynamic>) {
        throw Exception('Invalid response format from native code');
      }

      return NativeResponse.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      developer.log('Platform exception: ${e.code}');
      rethrow;
    }
  }
}

class NativeResponse {
  final String status;
  final String? errorMessage;

  NativeResponse({required this.status, this.errorMessage});

  factory NativeResponse.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('status')) {
      throw FormatException('Missing required field: status');
    }
    return NativeResponse(
      status: map['status'] as String,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
```

---

## Services & Background Execution

### DO: Background Task Patterns
- Use WorkManager for periodic tasks (Android 8+)
- Use BroadcastReceiver for system events
- Respect doze mode and battery optimization restrictions
- Use ForegroundService for user-visible background work
- Request SCHEDULE_EXACT_ALARM only if necessary

### DON'T: Background Anti-Patterns
- ❌ Start background processes from app without WorkManager
- ❌ Expect long-running services to continue in background
- ❌ Request unnecessary background permissions
- ❌ Run network operations without WorkManager on Android 8+
- ❌ Ignore battery optimization restrictions
- ❌ Start services from BroadcastReceiver (use WorkManager instead)

### Check these patterns
```dart
// ❌ WRONG - Background task without WorkManager
void startSync() {
  Future.delayed(const Duration(hours: 1), () {
    _syncData(); // Will be killed when app goes to background
  });
}

// ✅ CORRECT - WorkManager for periodic sync
import 'package:workmanager/workmanager.dart';

void initWorkManager() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Workmanager().registerPeriodicTask(
    'sync_task',
    'syncData',
    frequency: Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresDeviceIdle: false,
      requiresStorageNotLow: true,
    ),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // This runs in an isolated context
    _syncData();
    return Future.value(true);
  });
}
```

---

## Manifest Configuration

### DO: Manifest Best Practices
- Request minimum required permissions
- Set appropriate `targetSdkVersion` (current/recent)
- Configure activity orientation appropriately
- Set secure flags for sensitive screens
- Enable hardware acceleration where beneficial
- Configure intent filters for deep linking

### DON'T: Manifest Anti-Patterns
- ❌ Request excessive permissions
- ❌ Set `targetSdkVersion` to old versions
- ❌ Expose activities/services unnecessarily
- ❌ Hardcode API keys or sensitive data in manifest
- ❌ Use deprecated Android APIs

### Example AndroidManifest.xml configuration
```xml
<!-- ✅ CORRECT -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.passwordmanager">

    <!-- Request only necessary permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />

    <!-- Omit camera unless truly needed -->
    <!-- Omit contact access unless truly needed -->

    <application
        android:allowBackup="false"
        android:enableOnBackInvokedCallback="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.App"
        android:usesCleartextTraffic="false">

        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden"
            android:exported="true"
            android:hardwareAccelerated="true"
            android:launchMode="singleTask"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.App">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
```

---

## Resource Management

### DO: Resource Cleanup
- Close database connections in `dispose()`
- Cancel StreamSubscriptions
- Release camera/sensor resources
- Clear image/file caches periodically
- Unregister BroadcastReceivers in `onDestroy()`
- Manage memory carefully with large datasets

### DON'T: Resource Leaks
- ❌ Leave database connections open
- ❌ Subscribe to streams without cancelling
- ❌ Keep large bitmaps in memory
- ❌ Cache unlimited data in memory
- ❌ Leave listeners registered indefinitely

### Check these patterns
```dart
// ❌ WRONG - Resource leak, no cleanup
class DatabaseService {
  late Database db;

  Future<void> init() async {
    db = await openDatabase('app.db');
    // Never closed
  }
}

// ✅ CORRECT - Proper resource cleanup
class DatabaseService {
  Database? _db;

  Future<void> init() async {
    _db = await openDatabase('app.db');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

// Usage in app
Future<void> initServices() async {
  final dbService = DatabaseService();
  await dbService.init();

  // Ensure cleanup on app exit
  addAppExitListener(() async {
    await dbService.close();
  });
}
```

---

## Navigation & Activity Management

### DO: Proper Activity/Navigation Management
- Use GoRouter for navigation state management
- Handle back button correctly (override `onBackPressed` if needed)
- Implement proper back stack management
- Support deep linking with proper route configuration
- Maintain activity instances appropriately (singleTask/singleTop)

### DON'T: Navigation Anti-Patterns
- ❌ Create multiple instances of the same activity
- ❌ Use Navigator.popUntil without checking
- ❌ Hardcode back button behavior
- ❌ Leave orphaned activities in back stack
- ❌ Ignore deep link routing configuration

### Check these patterns
```dart
// ✅ CORRECT - GoRouter with proper configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: 'credentials/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return CredentialDetailScreen(id: id!);
          },
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    // Redirect to login if not authenticated
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn && state.location != '/login') {
      return '/login';
    }
    return null;
  },
);
```

---

## Kotlin/Java Interoperability

### DO: Kotlin/Java Code Quality
- Use Kotlin for new platform-specific code
- Use null-safety features
- Properly handle exceptions
- Use coroutines for async operations
- Implement proper logging

### DON'T: Unsafe Interop
- ❌ Write Java for new code (unless existing codebase)
- ❌ Return null without indicating what went wrong
- ❌ Block main thread in platform code
- ❌ Throw raw exceptions without context
- ❌ Log sensitive data

### Example Kotlin implementation
```kotlin
// ✅ CORRECT - Safe, idiomatic Kotlin
class BiometricService(private val context: Context) {

    fun authenticateBiometric(
        onSuccess: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        val executor = ContextCompat.getMainExecutor(context)
        val biometricPrompt = BiometricPrompt(
            context as Activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(result)
                    onSuccess("Biometric authentication successful")
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    onError("Authentication error: $errString")
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authenticate")
            .setSubtitle("Use your biometric credentials")
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }
}
```
