# Dart Language Best Practices

Comprehensive reference for Dart language issues, anti-patterns, and best practices. Use this guide when reviewing Dart code for language-level bugs, null safety issues, async problems, or type system violations.

## Table of Contents

- [Null Safety](#null-safety)
- [Type System](#type-system)
- [Async/Await and Futures](#asyncawait-and-futures)
- [Collections](#collections)
- [Performance Optimization](#performance-optimization)
- [Language Features](#language-features)
- [Common Mistakes](#common-mistakes)
- [Silent Dart Bugs](#silent-dart-bugs)

---

## Null Safety

Dart's null safety system prevents null reference errors at compile time.

### Late Variables

```dart
// ❌ WRONG - Late variable used before initialization
late String _config;

void loadConfig() {
  print(_config); // Runtime error: late variable not initialized
}

// ✅ CORRECT - Initialize before use
late String _config;

void loadConfig() {
  _config = 'value';
  print(_config); // OK
}

// ✅ CORRECT - Lazy initialization pattern
late final String _config = _loadConfig();

String _loadConfig() {
  return 'value';
}
```

### Nullable vs Non-nullable Types

```dart
// ❌ WRONG - Ignoring nullable values
String processUser(User? user) {
  return user.name; // Compile error: user might be null
}

// ✅ CORRECT - Handle nullability explicitly
String processUser(User? user) {
  if (user == null) return 'Unknown';
  return user.name;
}

// ✅ CORRECT - Use null-coalescing operator
String processUser(User? user) {
  return user?.name ?? 'Unknown';
}

// ✅ CORRECT - Null-aware property access
void printUser(User? user) {
  print(user?.name); // prints null if user is null
}
```

### Null-Aware Operators

```dart
// ❌ WRONG - Manual null checks everywhere
if (user != null) {
  if (user.profile != null) {
    if (user.profile!.avatar != null) {
      print(user.profile!.avatar!.url);
    }
  }
}

// ✅ CORRECT - Use null-coalescing and null-aware chaining
print(user?.profile?.avatar?.url ?? 'no avatar');
```

### Migration Patterns

```dart
// ❌ WRONG - Using ! everywhere (defeats null safety)
String getValue() {
  final value = getValue();
  return value!; // Too aggressive with !
}

// ✅ CORRECT - Handle nullability properly
String? getValue() {
  return null; // Or actual value
}

// ✅ CORRECT - Non-null guarantee
String getValueOrDefault() {
  return getValue() ?? 'default';
}
```

---

## Type System

Dart's type system helps catch errors and improves code clarity.

### Type Inference and Explicit Types

```dart
// ❌ WRONG - Too vague with var
var processData(data) {
  var result = data * 2;
  return result;
}

// ✅ CORRECT - Explicit types for clarity
int processData(int data) {
  int result = data * 2;
  return result;
}

// ✅ CORRECT - var for obvious types
var name = 'John'; // Type inference works here
final numbers = [1, 2, 3]; // List<int> is clear
```

### Generics

```dart
// ❌ WRONG - Using dynamic when generic works
List<dynamic> items = [];
items.add('string');
items.add(123);
// Later: String value = items[0] as String; // Runtime error prone

// ✅ CORRECT - Use generics for type safety
List<String> items = [];
items.add('string');
items.add(123); // Compile error: caught early

// ✅ CORRECT - Generic functions
T? findFirst<T>(List<T> items, bool Function(T) predicate) {
  for (final item in items) {
    if (predicate(item)) return item;
  }
  return null;
}
```

### Type Casting and Checking

```dart
// ❌ WRONG - Unsafe casting
Object obj = "string";
String str = obj as String; // OK, but what if obj isn't String?

String value = (obj as String).toUpperCase(); // Crashes if cast fails

// ✅ CORRECT - Check before casting
Object obj = "string";
if (obj is String) {
  String str = obj; // Automatic narrowing
  print(str.toUpperCase());
}

// ✅ CORRECT - Safe casting pattern
final result = maybeString is String ? maybeString.toUpperCase() : null;
```

### Dynamic vs Object

```dart
// ❌ WRONG - Using dynamic loses type safety
dynamic value = 42;
String text = value; // No compile error, but wrong at runtime

// ❌ WRONG - Everything is dynamic
void process(dynamic input) {
  print(input.unknownMethod()); // Crashes at runtime
}

// ✅ CORRECT - Use Object for "any type"
Object value = 42;
if (value is String) {
  print(value.toUpperCase()); // Type narrowing
}

// ✅ CORRECT - Use specific types
void process(String input) {
  print(input.toUpperCase());
}
```

---

## Async/Await and Futures

Async/await patterns are critical for correct asynchronous programming.

### Future Handling

```dart
// ❌ WRONG - Ignoring futures
void loadData() {
  fetchData(); // Future created but ignored - unpredictable behavior
}

// ❌ WRONG - Not awaiting futures
Future<String> loadData() async {
  fetchData(); // Not awaited!
  return "done"; // Returns before fetchData completes
}

// ✅ CORRECT - Await futures
Future<String> loadData() async {
  await fetchData();
  return "done";
}

// ✅ CORRECT - Chain futures with then
void loadData() {
  fetchData().then((result) {
    print('Data: $result');
  });
}
```

### Error Handling in Async Code

```dart
// ❌ WRONG - No error handling
Future<void> fetchAndProcess() async {
  final data = await fetchData(); // What if this throws?
  processData(data);
}

// ❌ WRONG - Incomplete error handling
Future<void> fetchAndProcess() async {
  try {
    final data = await fetchData();
    processData(data);
  } catch (e) {
    // Swallowing errors silently
  }
}

// ✅ CORRECT - Proper error handling
Future<void> fetchAndProcess() async {
  try {
    final data = await fetchData();
    processData(data);
  } catch (e) {
    print('Error loading data: $e');
    rethrow; // Or handle appropriately
  }
}

// ✅ CORRECT - Using whenComplete for cleanup
Future<void> fetchAndProcess() async {
  try {
    final data = await fetchData();
    processData(data);
  } finally {
    // Cleanup code runs regardless
    closeConnection();
  }
}
```

### Async Patterns

```dart
// ❌ WRONG - Sequential when parallel would be better
Future<Data> loadBoth() async {
  final user = await fetchUser();
  final settings = await fetchSettings();
  return Data(user, settings);
}

// ✅ CORRECT - Parallel async operations
Future<Data> loadBoth() async {
  final userFuture = fetchUser();
  final settingsFuture = fetchSettings();

  final user = await userFuture;
  final settings = await settingsFuture;
  return Data(user, settings);
}

// ✅ CORRECT - Using Future.wait
Future<Data> loadBoth() async {
  final results = await Future.wait([
    fetchUser(),
    fetchSettings(),
  ]);
  return Data(results[0] as User, results[1] as UserSettings);
}
```

### Stream Handling

```dart
// ❌ WRONG - Not canceling stream subscriptions
void listenToUpdates() {
  dataStream.listen((event) {
    print(event);
  }); // Memory leak: listener never unsubscribed
}

// ✅ CORRECT - Cancel subscriptions
StreamSubscription? _subscription;

void listenToUpdates() {
  _subscription = dataStream.listen((event) {
    print(event);
  });
}

void dispose() {
  _subscription?.cancel();
}

// ✅ CORRECT - Using StreamBuilder in Flutter
StreamBuilder<Data>(
  stream: dataStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) return Text(snapshot.data.toString());
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    return CircularProgressIndicator();
  },
)
```

---

## Collections

Lists, Maps, and Sets have specific best practices.

### List Best Practices

```dart
// ❌ WRONG - Modifying list during iteration
for (int i = 0; i < items.length; i++) {
  if (items[i] > 100) {
    items.removeAt(i); // Skips elements, unpredictable
  }
}

// ✅ CORRECT - Filter first
items = items.where((item) => item <= 100).toList();

// ✅ CORRECT - Iterate over copy
for (final item in items.toList()) {
  if (item > 100) {
    items.remove(item);
  }
}

// ✅ CORRECT - Use list methods
items.removeWhere((item) => item > 100);
```

### Immutable Collections

```dart
// ❌ WRONG - Mutable collection exposed
List<String> getNames() {
  return _names; // Caller can modify!
}

// ✅ CORRECT - Return unmodifiable view
List<String> getNames() {
  return List.unmodifiable(_names);
}

// ✅ CORRECT - Use const for compile-time constants
const List<String> defaultNames = ['Alice', 'Bob'];
```

### Collection Operators

```dart
// ❌ WRONG - Verbose collection operations
List<int> doubled = [];
for (int num in numbers) {
  doubled.add(num * 2);
}

// ✅ CORRECT - Use collection operators
List<int> doubled = numbers.map((num) => num * 2).toList();

// ✅ CORRECT - Spread operator for clarity
List<int> combined = [...list1, ...list2];

// ✅ CORRECT - Collection if for conditional adding
List<int> items = [
  1,
  2,
  if (includeThree) 3,
  4,
];
```

### Map Handling

```dart
// ❌ WRONG - Not checking before accessing
String value = map['key']; // Runtime error if key not found

// ✅ CORRECT - Safe access
String? value = map['key']; // Returns null if not found
String value = map['key'] ?? 'default';

// ✅ CORRECT - Use containsKey when needed
if (map.containsKey('key')) {
  String value = map['key']!;
}

// ✅ CORRECT - putIfAbsent pattern
map.putIfAbsent('key', () => computeValue());
```

---

## Performance Optimization

### Const Usage

```dart
// ❌ WRONG - Creating new instances every time
Widget build(BuildContext context) {
  return Text(
    'Hello',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ); // New TextStyle created every rebuild
}

// ✅ CORRECT - Use const for constant values
const _textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

Widget build(BuildContext context) {
  return Text('Hello', style: _textStyle);
}

// ✅ CORRECT - Const constructors
const button = FloatingActionButton(
  onPressed: null,
  child: Icon(Icons.add),
);
```

### Final vs Late Final

```dart
// ❌ WRONG - Reassignable field when it shouldn't be
class Config {
  String apiUrl = 'https://api.example.com'; // Might change accidentally
}

// ✅ CORRECT - Use final for immutable values
class Config {
  final String apiUrl = 'https://api.example.com';
}

// ✅ CORRECT - Late final for lazy initialization
class Config {
  late final String apiUrl;

  Config(String url) {
    apiUrl = url;
  }
}
```

### Lazy Evaluation

```dart
// ❌ WRONG - Computing values eagerly
class ExpensiveClass {
  final data = _computeExpensive(); // Computed even if not used
}

// ✅ CORRECT - Lazy computation
class ExpensiveClass {
  late final data = _computeExpensive(); // Only computed when accessed
}

// ✅ CORRECT - Method-based lazy loading
class ExpensiveClass {
  late final data = _computeExpensive();

  String? get cachedData => _cache;
  String? _cache;
}
```

---

## Language Features

### Extensions

```dart
// ✅ CORRECT - Extension methods for clean code
extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

void use() {
  print('hello world'.toTitleCase()); // Output: Hello World
}
```

### Mixins

```dart
// ❌ WRONG - Deep inheritance hierarchies
class Animal {}
class Walker extends Animal {}
class Swimmer extends Walker {}
class Flyer extends Swimmer {} // What about flying swimmers?

// ✅ CORRECT - Use mixins for cross-cutting concerns
mixin Walker {
  void walk() => print('Walking');
}

mixin Swimmer {
  void swim() => print('Swimming');
}

mixin Flyer {
  void fly() => print('Flying');
}

class Duck with Walker, Swimmer, Flyer {}
```

### Sealed Classes (Dart 3.0+)

```dart
// ✅ CORRECT - Sealed classes for exhaustive pattern matching
sealed class Result {}

class Success extends Result {
  final String data;
  Success(this.data);
}

class Error extends Result {
  final String message;
  Error(this.message);
}

// Compiler ensures all cases handled
String handleResult(Result result) {
  return switch (result) {
    Success(data: final data) => 'Success: $data',
    Error(message: final msg) => 'Error: $msg',
  };
}
```

---

## Common Mistakes

### Mutable Default Parameters

```dart
// ❌ WRONG - Mutable default parameter
void addToList(List<String> items = []) {
  items.add('new item');
  print(items); // Same list reused!
}

addToList(); // prints [new item]
addToList(); // prints [new item, new item]

// ✅ CORRECT - Create new instance
void addToList(List<String>? items) {
  items ??= [];
  items.add('new item');
  print(items);
}
```

### Equality Comparison

```dart
// ❌ WRONG - Using == for reference equality
class User {
  final String name;
  User(this.name);
}

final user1 = User('John');
final user2 = User('John');
print(user1 == user2); // false - different objects

// ✅ CORRECT - Override == for value equality
class User {
  final String name;
  User(this.name);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is User && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

final user1 = User('John');
final user2 = User('John');
print(user1 == user2); // true - same value

// ✅ CORRECT - Use freezed for automatic implementation
@freezed
class User with _$User {
  const factory User(String name) = _User;
}
```

### Late Initialization Errors

```dart
// ❌ WRONG - Multiple assignments to late variable
late String config;

void setup() {
  config = 'value1';
  config = 'value2'; // Runtime error: already initialized
}

// ✅ CORRECT - Assign once
late String config;

void setup() {
  config = 'value1';
}

// ✅ CORRECT - Use late final for truly immutable
late final String config = _loadConfig();
```

---

## Silent Dart Bugs

These bugs don't throw errors but cause incorrect behavior.

### Ignored Futures

```dart
// ❌ SILENT BUG - Future ignored
void handleTap() {
  saveData(); // Future created and discarded
  Navigator.pop(context); // May happen before save completes
}

// ✅ CORRECT - Await the future
void handleTap() async {
  await saveData();
  Navigator.pop(context);
}

// ✅ CORRECT - Explicitly ignore if intentional
void handleTap() async {
  unawaited(saveData()); // Signals intent to ignore
  Navigator.pop(context);
}
```

### Uncaught Async Exceptions

```dart
// ❌ SILENT BUG - Exception in async context
Future<void> process() async {
  try {
    await fetchData();
  } catch (e) {
    // Error not rethrown or logged
  }
}

// ✅ CORRECT - Handle or rethrow
Future<void> process() async {
  try {
    await fetchData();
  } on NetworkException catch (e) {
    print('Network error: $e');
  } on Exception {
    rethrow; // Let caller handle other exceptions
  }
}
```

### Type Coercion Issues

```dart
// ❌ SILENT BUG - Unexpected type coercion
String id = 123; // Compile error with null safety, but...
final value = someValue as String; // Might fail at runtime if wrong type

// ✅ CORRECT - Explicit type checking
String id = '123';
if (someValue is String) {
  String value = someValue;
}
```

### Null-Related Logic Errors

```dart
// ❌ SILENT BUG - Logic error with nullability
String? getName() => null;

void greet() {
  final name = getName();
  print('Hello $name'); // Prints "Hello null" - not an error
}

// ✅ CORRECT - Explicit null handling
void greet() {
  final name = getName();
  if (name != null) {
    print('Hello $name');
  } else {
    print('Hello stranger');
  }
}

// ✅ CORRECT - Use ?? for defaults
void greet() {
  final name = getName() ?? 'stranger';
  print('Hello $name');
}
```

### Stream Leaks

```dart
// ❌ SILENT BUG - Stream subscription leaked
class DataProvider {
  final stream = Stream.periodic(Duration(seconds: 1), (_) => _getData());

  void startListening() {
    stream.listen(print); // Subscription never cancelled
  }
}

// ✅ CORRECT - Track and cancel subscriptions
class DataProvider {
  StreamSubscription? _subscription;

  void startListening() {
    _subscription = stream.listen(print);
  }

  void stopListening() {
    _subscription?.cancel();
  }

  void dispose() {
    stopListening();
  }
}
```

---

## Quick Reference

| Issue | Wrong | Right |
|-------|-------|-------|
| Null handling | `obj.prop` (might be null) | `obj?.prop ?? default` |
| Ignore future | `futureCall();` | `await futureCall();` or `unawaited()` |
| List mutation | Loop with `.removeAt()` | `.removeWhere()` or `.where().toList()` |
| Type safety | `dynamic value` | `String value` or `Object?` with checks |
| Constants | `TextStyle(...)` in build | `const _style = TextStyle(...)` |
| Late init | Multiple assignments | Assign once, use `late final` |
| Equality | `==` without override | Override `==` and `hashCode` |
| Streams | No subscription cancel | Store and cancel in dispose |
