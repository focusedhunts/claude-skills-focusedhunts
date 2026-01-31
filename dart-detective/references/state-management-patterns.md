# State Management Patterns for Flutter Apps

This reference covers best practices for state management in Flutter, with focus on Riverpod and Bloc patterns, architecture principles, and common anti-patterns.

## Table of Contents
- [Core Principles](#core-principles)
- [Riverpod Best Practices](#riverpod-best-practices)
- [Bloc Best Practices](#bloc-best-practices)
- [Architecture Patterns](#architecture-patterns)
- [Common Anti-Patterns](#common-anti-patterns)
- [Provider Lifecycle Management](#provider-lifecycle-management)
- [Testing State Management](#testing-state-management)

---

## Core Principles

### Separation of Concerns
- **UI Layer** - Widgets and UI logic
- **State Layer** - Riverpod providers / Bloc
- **Domain Layer** - Business logic and use cases
- **Data Layer** - Repositories and API/database clients

### Immutability
- State should always be immutable
- Use `freezed` for immutable data classes
- Return new instances instead of mutating existing state
- Use `const` constructors

### Single Responsibility
- One provider/bloc per concern
- Providers should have a single purpose
- Keep providers/blocs focused and testable

---

## Riverpod Best Practices

### DO: Riverpod Patterns
- Use `final` for providers (makes them immutable)
- Use `Consumer` widgets instead of `StateProvider` for simple state
- Use `StateNotifier` or `AsyncNotifier` for complex state
- Use `.family` modifier for parameterized providers
- Use `.select()` to listen to specific fields
- Use `.watch()` for dependencies between providers
- Cancel subscriptions properly (use `ref.onDispose()`)
- Use FutureProvider/StreamProvider for async operations

### DON'T: Riverpod Anti-Patterns
- ❌ Use global variables for state
- ❌ Mutate state directly (always return new instances)
- ❌ Create providers inside build methods
- ❌ Use `StateProvider` for complex state (use `StateNotifier` instead)
- ❌ Leave subscriptions active unnecessarily
- ❌ Ignore provider dependencies
- ❌ Use `StatefulWidget` for app state (use Riverpod instead)

### Check these patterns

#### Basic Provider Pattern
```dart
// ❌ WRONG - Direct mutation
class UserNotifier extends Notifier<User> {
  @override
  User build() => User(name: 'John', email: '');

  void updateName(String name) {
    state.name = name; // WRONG - Direct mutation
  }
}

// ✅ CORRECT - Return new instance
class UserNotifier extends Notifier<User> {
  @override
  User build() => User(name: 'John', email: '');

  void updateName(String name) {
    state = state.copyWith(name: name); // Create new instance
  }
}

final userProvider = NotifierProvider<UserNotifier, User>(UserNotifier.new);
```

#### AsyncNotifier for Async Operations
```dart
// ❌ WRONG - FutureProvider without proper caching/refresh
final userFuture = FutureProvider((ref) async {
  return await api.fetchUser();
});

// ✅ CORRECT - AsyncNotifier with refresh capability
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await api.fetchUser();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.fetchUser());
  }

  Future<void> updateUser(String name) async {
    final currentUser = state.requireValue;
    final updated = currentUser.copyWith(name: name);
    state = AsyncValue.data(updated);

    try {
      await api.updateUser(updated);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, User>(UserNotifier.new);
```

#### Family Modifier for Parameterized Providers
```dart
// ❌ WRONG - Creating multiple separate providers
final credentialProvider1 = AsyncNotifierProvider((ref) async => api.getCredential(1));
final credentialProvider2 = AsyncNotifierProvider((ref) async => api.getCredential(2));
final credentialProvider3 = AsyncNotifierProvider((ref) async => api.getCredential(3));

// ✅ CORRECT - Use .family for parameters
final credentialProvider = AsyncNotifierProvider.family<
    CredentialNotifier,
    Credential,
    String
>(
  (ref, credentialId) => CredentialNotifier(credentialId),
);

class CredentialNotifier extends AsyncNotifier<Credential> {
  late final String credentialId;

  CredentialNotifier(this.credentialId);

  @override
  Future<Credential> build() async {
    return await api.getCredential(credentialId);
  }
}

// Usage
Consumer(builder: (context, ref, child) {
  final credential1 = ref.watch(credentialProvider('cred1'));
  final credential2 = ref.watch(credentialProvider('cred2'));
  // ...
});
```

#### Select for Specific Field Listening
```dart
// ❌ WRONG - Rebuilds when any field changes
Consumer(builder: (context, ref, child) {
  final user = ref.watch(userProvider);
  return Text(user.name); // Rebuilds even if only email changed
});

// ✅ CORRECT - Listen only to specific field
Consumer(builder: (context, ref, child) {
  final userName = ref.watch(
    userProvider.select((user) => user.name),
  );
  return Text(userName); // Only rebuilds if name changes
});
```

#### Proper Cleanup with ref.onDispose
```dart
// ❌ WRONG - No cleanup
final timerProvider = NotifierProvider((ref) {
  Timer.periodic(Duration(seconds: 1), (_) {
    // Timer never cancelled
  });
  return '';
});

// ✅ CORRECT - Cancel timer on provider dispose
final timerProvider = NotifierProvider<TimerNotifier, String>(TimerNotifier.new);

class TimerNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      state = DateTime.now().toString();
    });

    return '';
  }
}
```

---

## Bloc Best Practices

### DO: Bloc Patterns
- Use `equatable` for event/state comparison
- Emit states immutably
- Handle errors gracefully with error states
- Use `Stream` transformers for advanced logic
- Test using `blocTest`
- Use proper initial state
- Provide clear, specific events

### DON'T: Bloc Anti-Patterns
- ❌ Mutate state directly
- ❌ Create side effects in `mapEventToState`
- ❌ Use Bloc for local UI state (prefer Riverpod)
- ❌ Skip error states
- ❌ Have Bloc depend on BuildContext
- ❌ Forget to emit states

### Check these patterns

#### Basic Bloc Structure
```dart
// ✅ CORRECT - Well-structured Bloc
import 'package:equatable/equatable.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();

  @override
  List<Object?> get props => [];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(const AuthInitial());
  }
}
```

#### Using Stream Transformers
```dart
// ✅ CORRECT - Using transformer for debouncing
on<SearchEvent>(
  (event, emit) async {
    emit(SearchLoading());
    try {
      final results = await repository.search(event.query);
      emit(SearchSuccess(results: results));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  },
  transformer: (events, mapper) {
    return events
        .debounceTime(const Duration(milliseconds: 300))
        .asyncExpand(mapper);
  },
);
```

---

## Architecture Patterns

### Layered Architecture
```
presentation/
├── screens/
├── widgets/
└── bloc/

domain/
├── entities/
├── repositories/
└── usecases/

data/
├── models/
├── datasources/ (local, remote)
└── repositories/ (implementation)
```

### Repository Pattern
```dart
// ✅ CORRECT - Repository abstraction
abstract class CredentialRepository {
  Future<List<Credential>> getCredentials();
  Future<Credential> getCredential(String id);
  Future<void> saveCredential(Credential credential);
  Future<void> deleteCredential(String id);
}

// Implementation
class CredentialRepositoryImpl implements CredentialRepository {
  final CredentialRemoteDataSource remoteDataSource;
  final CredentialLocalDataSource localDataSource;

  CredentialRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Credential>> getCredentials() async {
    try {
      // Try remote first
      final credentials = await remoteDataSource.getCredentials();
      // Cache locally
      await localDataSource.cacheCredentials(credentials);
      return credentials;
    } catch (e) {
      // Fallback to local cache
      return await localDataSource.getCachedCredentials();
    }
  }

  @override
  Future<void> saveCredential(Credential credential) async {
    // Save both locally and remotely
    await localDataSource.saveCredential(credential);
    try {
      await remoteDataSource.saveCredential(credential);
    } catch (e) {
      // Log error but don't fail - local save succeeded
      developer.log('Failed to sync credential to remote: $e');
    }
  }
}
```

### Dependency Injection with Riverpod
```dart
// ✅ CORRECT - DI using Riverpod providers
final apiClientProvider = Provider((ref) => ApiClient());

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(apiClient: apiClient);
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository authRepository;

  @override
  AuthState build() {
    authRepository = ref.watch(authRepositoryProvider);
    return AuthState.initial();
  }
}
```

---

## Common Anti-Patterns

### Anti-Pattern 1: Storing UI State in Global Providers
```dart
// ❌ WRONG
final pageIndexProvider = StateProvider((ref) => 0);

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    return PageView(
      onPageChanged: (index) {
        ref.read(pageIndexProvider.notifier).state = index;
      },
    );
  }
}

// ✅ CORRECT - Use PageController
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
    );
  }
}
```

### Anti-Pattern 2: Over-fetching Data
```dart
// ❌ WRONG - Fetches all user data when only name is needed
final userProvider = FutureProvider((ref) async => api.getFullUser());

Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => Text(user.name), // Only uses name
  );
}

// ✅ CORRECT - Separate providers for different data
final userNameProvider = FutureProvider((ref) async {
  return await api.getUserName();
});

final userDetailsProvider = FutureProvider((ref) async {
  return await api.getUserDetails();
});

// Only request what you need
```

### Anti-Pattern 3: Blocking UI with Heavy Computation
```dart
// ❌ WRONG - Blocks UI thread
final computationProvider = FutureProvider((ref) async {
  return heavyComputation(); // Blocks UI
});

// ✅ CORRECT - Use compute() for background execution
final computationProvider = FutureProvider((ref) async {
  return await compute(heavyComputation, null);
});

// Or use WorkManager for periodic tasks
```

---

## Provider Lifecycle Management

### DO: Manage Provider Lifecycle
```dart
// ✅ CORRECT - Cleanup resources
class DatabaseProvider extends Notifier<Database> {
  @override
  Database build() {
    final db = openDatabase();

    // Cleanup when provider is no longer used
    ref.onDispose(() {
      db.close();
    });

    return db;
  }
}

// ✅ CORRECT - Cache with TTL
final cachedDataProvider = StateNotifierProvider((ref) {
  final timer = Timer(const Duration(minutes: 5), () {
    // Invalidate cache after 5 minutes
    ref.invalidate(cachedDataProvider);
  });

  ref.onDispose(() {
    timer.cancel();
  });

  return StateNotifier([]);
});
```

### DON'T: Leave Resources Open
```dart
// ❌ WRONG - File handle never closed
final fileProvider = FutureProvider((ref) async {
  return await File('data.txt').readAsString();
});

// ❌ WRONG - Stream never cancelled
final streamProvider = StreamProvider((ref) {
  return someStream(); // Never cancelled
});
```

---

## Testing State Management

### Testing Riverpod Providers
```dart
// ✅ CORRECT - Test provider with mocked dependencies
void main() {
  test('userProvider returns user', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
      ],
    );

    final user = await container.read(userProvider.future);
    expect(user.name, equals('John'));
  });
}
```

### Testing Bloc
```dart
// ✅ CORRECT - Use blocTest
void main() {
  group('AuthBloc', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(mockAuthRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => User(id: '1', name: 'John'));

        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(LoginEvent(email: 'john@example.com', password: 'pass')),
      expect: () => [
        const AuthLoading(),
        isA<AuthSuccess>(),
      ],
    );
  });
}
```
