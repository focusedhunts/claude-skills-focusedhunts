# Security Checklist for Flutter Password Manager Apps

For password manager applications, security is paramount. This checklist covers the critical security vulnerabilities and anti-patterns specific to password management applications.

## Table of Contents
- [Credential Storage & Encryption](#credential-storage--encryption)
- [API & Network Security](#api--network-security)
- [Authentication & Authorization](#authentication--authorization)
- [Data Protection in Memory](#data-protection-in-memory)
- [Input Validation & Sanitization](#input-validation--sanitization)
- [Platform Security (Android)](#platform-security-android)
- [Dependency & Library Security](#dependency--library-security)

---

## Credential Storage & Encryption

### DO: Use encrypted storage
- **flutter_secure_storage** - Use for storing sensitive data (master passwords, tokens, API keys)
- **Hive with encryption** - Use encrypted Hive boxes for local database
- Never store credentials in SharedPreferences (unencrypted)

### DON'T: Plaintext sensitive data
- ❌ SharedPreferences for passwords, tokens, or API keys
- ❌ Hardcoded credentials in code or config files
- ❌ Unencrypted local database entries for sensitive fields
- ❌ Storing master password in memory without clearing on app pause

### Android-Specific
- Use Android Keystore for key material
- Use EncryptedSharedPreferences via androidx.security:security-crypto
- Verify that flutter_secure_storage uses Android Keystore (it should by default)

### Check these patterns
```dart
// ❌ WRONG - Unencrypted storage
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('password', userPassword);

// ✅ CORRECT - Encrypted storage
final secureStorage = const FlutterSecureStorage();
await secureStorage.write(key: 'password', value: userPassword);

// ✅ CORRECT - Encrypted Hive
final box = await Hive.openBox<Credential>('credentials',
  encryptionCipher: HiveAesCipher(encryptionKey));
```

---

## API & Network Security

### DO: Secure API communications
- Use HTTPS only (validate certificates)
- Implement certificate pinning for critical endpoints
- Use SecureSocket with custom trust certificates
- Implement timeout on API calls
- Clear sensitive data from request/response logs

### DON'T: Insecure API patterns
- ❌ Accept invalid SSL certificates (`HttpClient.badCertificateCallback = (cert, host, port) => true`)
- ❌ Send credentials in query parameters
- ❌ Log sensitive data (passwords, tokens, PII)
- ❌ Store API responses containing credentials in local files
- ❌ Cache sensitive API responses in memory indefinitely

### Check these patterns
```dart
// ❌ WRONG - Accepts any certificate
HttpClient httpClient = HttpClient()
  ..badCertificateCallback = ((cert, host, port) => true);

// ✅ CORRECT - Certificate pinning
final securityContext = SecurityContext.defaultContext;
// Load certificate pinning
final certificateBytes = await rootBundle.load('assets/cert.pem');
securityContext.setTrustedCertificatesBytes(certificateBytes.buffer.asUint8List());
HttpClient httpClient = HttpClient(context: securityContext);

// ❌ WRONG - Credentials in query params
http.get(Uri.parse('https://api.example.com/login?password=$password'));

// ✅ CORRECT - Credentials in request body
http.post(
  Uri.parse('https://api.example.com/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'password': password}),
);

// ❌ WRONG - Logging credentials
log('User login with password: $password');

// ✅ CORRECT - Sanitize logs
log('User authentication attempt');
```

---

## Authentication & Authorization

### DO: Implement secure authentication
- Implement biometric authentication (fingerprint, face recognition)
- Use secure token storage (not in SharedPreferences)
- Implement token refresh mechanism with secure refresh tokens
- Add rate limiting to authentication attempts
- Implement account lockout after failed attempts
- Use strong session management

### DON'T: Weak authentication
- ❌ Store tokens in plaintext
- ❌ Accept any user input without validation as login/password
- ❌ Store login credentials for auto-login (always require re-authentication)
- ❌ Lack timeout/session expiration
- ❌ Weak password validation (no length minimum, no character requirements)

### Check these patterns
```dart
// ❌ WRONG - Token in SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('authToken', token);

// ✅ CORRECT - Token in secure storage
final secureStorage = const FlutterSecureStorage();
await secureStorage.write(key: 'authToken', value: token);

// ❌ WRONG - No auth timeout
class AuthProvider {
  // Token lives forever
}

// ✅ CORRECT - Implement timeout
class AuthProvider {
  DateTime lastActivityTime = DateTime.now();
  final Duration sessionTimeout = const Duration(minutes: 15);

  bool isSessionValid() {
    final elapsed = DateTime.now().difference(lastActivityTime);
    return elapsed < sessionTimeout;
  }
}
```

---

## Data Protection in Memory

### DO: Clear sensitive data
- Clear sensitive data (passwords, decrypted credentials) from memory when done
- Clear UI text fields that contain sensitive data
- Use immutable structures for sensitive data where possible
- Clear memory on app pause/background

### DON'T: Persist sensitive data in memory
- ❌ Store passwords in global variables or singletons
- ❌ Keep decrypted credentials in memory longer than needed
- ❌ Store sensitive data in widget state without clearing
- ❌ Leave plain-text passwords in TextEditingController history

### Check these patterns
```dart
// ❌ WRONG - Password persists in memory
String globalPassword = '';
void savePassword(String pwd) {
  globalPassword = pwd; // Never cleared
}

// ✅ CORRECT - Clear sensitive data
Uint8List sensitiveData = encryptedPassword;
try {
  // Use sensitiveData
  final decrypted = decrypt(sensitiveData);
  // ... work with decrypted data
} finally {
  // Clear from memory
  sensitiveData.fillRange(0, sensitiveData.length, 0);
}

// ❌ WRONG - Password stored in TextEditingController
final passwordController = TextEditingController()..text = userPassword;

// ✅ CORRECT - Clear after use
final passwordController = TextEditingController();
try {
  // Use password
  final password = passwordController.text;
} finally {
  passwordController.clear();
}
```

---

## Input Validation & Sanitization

### DO: Validate all inputs
- Validate email format before use
- Validate password strength requirements
- Sanitize search queries and filters
- Validate all API responses before use
- Check for null/empty before processing

### DON'T: Skip input validation
- ❌ Accept input without validation
- ❌ Use regex without proper escaping
- ❌ Trust API responses without type checking
- ❌ Allow SQL injection patterns (though less relevant with ORMs)
- ❌ Accept oversized input that could cause DoS

### Check these patterns
```dart
// ❌ WRONG - No validation
void loginUser(String email, String password) {
  sendLoginRequest(email, password);
}

// ✅ CORRECT - Validate before use
void loginUser(String email, String password) {
  if (!email.contains('@') || email.isEmpty) {
    throw Exception('Invalid email format');
  }
  if (password.length < 8) {
    throw Exception('Password too short');
  }
  sendLoginRequest(email, password);
}

// ❌ WRONG - Trust API response
final user = User.fromJson(apiResponse['user']);

// ✅ CORRECT - Validate response
if (apiResponse['user'] is Map<String, dynamic>) {
  final user = User.fromJson(apiResponse['user']);
} else {
  throw Exception('Invalid API response format');
}
```

---

## Platform Security (Android)

### DO: Secure Android implementation
- Request minimum necessary permissions
- Use runtime permissions for sensitive access
- Disable screenshot capability for sensitive screens
- Implement secure keyboard (no suggestions for passwords)
- Use FLAG_SECURE for UI security
- Respect Android Security & Privacy guidelines

### DON'T: Weak Android security
- ❌ Request unnecessary permissions
- ❌ Declare all permissions in manifest without runtime checks
- ❌ Allow screenshots on password/credential screens
- ❌ Show password suggestions in keyboard
- ❌ Expose sensitive data in logcat
- ❌ Ignore Android permission denials

### Check these patterns
```dart
// ✅ CORRECT - Disable screenshots on sensitive screens
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class PasswordScreen extends StatefulWidget {
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  @override
  void initState() {
    super.initState();
    _disableScreenshots();
  }

  Future<void> _disableScreenshots() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void dispose() {
    // Re-enable screenshots when leaving
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password')),
      body: const Text('Sensitive Data'),
    );
  }
}

// ✅ CORRECT - Secure password input (no suggestions)
TextField(
  obscureText: true,
  enableSuggestions: false,
  autocorrect: false,
  keyboardType: TextInputType.visiblePassword,
  decoration: InputDecoration(labelText: 'Password'),
)
```

---

## Dependency & Library Security

### DO: Use reputable, maintained dependencies
- Check library GitHub for:
  - Active maintenance (recent commits)
  - Security audit history
  - Transparent issue handling
  - Community reviews and ratings
- Run `flutter pub outdated` regularly
- Use dependency locking (pubspec.lock)
- Review security advisories for dependencies

### DON'T: Risky dependency patterns
- ❌ Use deprecated or unmaintained libraries
- ❌ Use obscure libraries with minimal GitHub stars/forks
- ❌ Ignore security warnings or CVE advisories
- ❌ Add unnecessary dependencies (follow YAGNI principle)
- ❌ Use libraries that require excessive permissions

### Recommended secure libraries for password managers
- **flutter_secure_storage** - Encrypted credential storage
- **dio** - HTTP client with interceptor support
- **riverpod** or **bloc** - State management
- **freezed** + **json_serializable** - Data model immutability
- **local_auth** - Biometric authentication
- **pointycastle** or **encrypt** - Cryptographic operations
- **hive** (with encryption) - Local encrypted database
- **drift** - Type-safe database abstraction

### Libraries to avoid for password managers
- ❌ Any custom/unknown crypto libraries (use proven ones)
- ❌ Libraries requiring excessive/vague permissions
- ❌ Unmaintained/deprecated libraries
- ❌ Libraries that auto-log data

---

## Common Vulnerability Patterns in Flutter

### Data Exposed in Logs
```dart
// ❌ WRONG
debugPrint('User password: $password');

// ✅ CORRECT
debugPrint('User authentication successful'); // No credentials in logs
```

### Memory Leaks with Streams
```dart
// ❌ WRONG - Stream never cancelled
authProvider.authStream.listen((user) {
  setState(() => this.user = user);
  // Never cancelled - leaks memory
});

// ✅ CORRECT - Cancel on dispose
StreamSubscription? _subscription;

@override
void initState() {
  super.initState();
  _subscription = authProvider.authStream.listen((user) {
    setState(() => this.user = user);
  });
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### Improper Exception Handling
```dart
// ❌ WRONG - Catches all, logs sensitive data
try {
  final result = await api.fetchCredentials();
} catch (e, st) {
  print('Error: $e\nStackTrace: $st'); // Might contain sensitive data
}

// ✅ CORRECT - Specific handling, no sensitive logging
try {
  final result = await api.fetchCredentials();
} catch (AuthenticationException) {
  // Handle auth errors specifically
  showErrorDialog('Authentication failed');
} catch (NetworkException) {
  // Handle network errors
  showErrorDialog('Network error');
} catch (e) {
  // Generic fallback without logging sensitive data
  developer.log('Unexpected error', level: 1000);
}
```
