# Flutter Performance Optimization & Best Practices

This reference covers performance profiling, optimization techniques, and anti-patterns that impact app responsiveness, memory usage, and battery life.

## Table of Contents
- [Performance Profiling](#performance-profiling)
- [Build Efficiency](#build-efficiency)
- [List & Scroll Performance](#list--scroll-performance)
- [Memory Management](#memory-management)
- [Image Loading & Caching](#image-loading--caching)
- [Animation Optimization](#animation-optimization)
- [Network Performance](#network-performance)
- [Common Performance Anti-Patterns](#common-performance-anti-patterns)

---

## Performance Profiling

### DO: Profile Before Optimizing
- Use Flutter DevTools Performance view
- Use Dart DevTools to profile CPU and memory
- Measure frame render time (target: 60 fps for 60Hz, 120 fps for 120Hz displays)
- Profile on real devices (not just emulator)
- Test on low-end devices too
- Use `benchmark` for consistent measurements

### DON'T: Optimize Blindly
- ❌ Optimize without measuring first (premature optimization)
- ❌ Assume emulator performance equals real device
- ❌ Only test on latest flagship devices
- ❌ Ignore memory constraints

### Tools & Commands
```bash
# Run app with performance tracking
flutter run --profile

# Open DevTools Performance tab
flutter pub global run devtools

# Build for profiling (not release)
flutter build apk --profile
```

---

## Build Efficiency

### DO: Optimize Builds
- Use `const` constructors everywhere possible
- Break large build methods into smaller widgets
- Use `const` collections `[]` instead of creating new ones
- Cache widget hierarchies
- Use `RepaintBoundary` for complex widgets
- Implement `shouldRebuild()` in custom painters

### DON'T: Inefficient Builds
- ❌ Create new widgets inside build methods
- ❌ Skip const constructors
- ❌ Build large widget trees in single method
- ❌ Rebuild entire UI when single field changes
- ❌ Use `onChanged` callbacks that rebuild parent

### Check these patterns

#### Const Constructor Usage
```dart
// ❌ WRONG - Creates new widget every build
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        child: Text('Header'),
      ),
    ],
  );
}

// ✅ CORRECT - Reuse const widgets
class MyPage extends StatelessWidget {
  const MyPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('Header'),
        ),
      ],
    );
  }
}
```

#### Extract Large Builds
```dart
// ❌ WRONG - Entire UI rebuilds when button is pressed
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          ExpensiveWidget(), // Rebuilds unnecessarily
          Text('Count: $count'),
          FloatingActionButton(
            onPressed: () => setState(() => count++),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ✅ CORRECT - Extract expensive widget
class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const ExpensiveWidget(), // Extracted, won't rebuild
          Text('Count: $count'),
          FloatingActionButton(
            onPressed: () => setState(() => count++),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// Extract as separate const widget
class ExpensiveWidget extends StatelessWidget {
  const ExpensiveWidget();

  @override
  Widget build(BuildContext context) {
    // Complex widget tree
    return Container();
  }
}
```

---

## List & Scroll Performance

### DO: Efficient List Rendering
- Use `ListView.builder` or `GridView.builder` (never `ListView()`)
- Implement `itemExtent` for fixed-size lists (improves scrolling)
- Use `ListView.separated` for lists with dividers
- Set `shrinkWrap: false` unless in scrollable (default)
- Use proper keys for list items
- Use `NeverScrollableScrollPhysics` when inside scrollable

### DON'T: Inefficient Scrollables
- ❌ Use `ListView()` with large lists
- ❌ Omit `itemExtent` when possible
- ❌ Nest scrollables without caution
- ❌ Use `ListView(shrinkWrap: true)` unnecessarily
- ❌ Create widgets for off-screen items
- ❌ Use `Padding` directly on ListView children

### Check these patterns

#### Proper ListView.builder
```dart
// ❌ WRONG - Renders all items at once
ListView(
  children: [
    for (int i = 0; i < 1000; i++)
      ListTile(title: Text('Item $i')),
  ],
)

// ✅ CORRECT - Only renders visible items
ListView.builder(
  itemCount: itemCount,
  itemExtent: 56, // Fixed height improves performance
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].title),
    );
  },
)
```

#### Efficient Complex Lists
```dart
// ✅ CORRECT - GridView with proper builder
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.0,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return GridTile(
      child: Image.network(
        items[index].imageUrl,
        fit: BoxFit.cover,
      ),
    );
  },
)

// ✅ CORRECT - ListView.separated with proper structure
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
)
```

---

## Memory Management

### DO: Manage Memory Efficiently
- Dispose controllers in `dispose()` method
- Cancel StreamSubscriptions
- Clear caches periodically
- Use `WeakReference` for caches if needed
- Monitor memory with DevTools
- Release large objects when no longer needed

### DON'T: Leak Memory
- ❌ Leave StreamSubscriptions active
- ❌ Keep references to UI elements
- ❌ Cache unlimited data
- ❌ Store large objects globally
- ❌ Forget to dispose controllers/listeners
- ❌ Hold Context references

### Check these patterns

#### Proper Resource Cleanup
```dart
// ❌ WRONG - Controller never disposed
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    // Never disposed
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller);
  }
}

// ✅ CORRECT - Proper cleanup
class MyWidget extends StatefulWidget {
  const MyWidget();

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController controller;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _subscription = someStream.listen((_) {
      // Handle stream events
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller);
  }
}
```

#### Memory-Efficient Caching
```dart
// ✅ CORRECT - LRU cache with size limit
class CachedImageProvider {
  static const _maxCacheSize = 50; // Limit to 50 images
  static final _cache = <String, Image>{};

  static Image getOrFetch(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    final image = Image.network(url);
    _cache[url] = image;
    return image;
  }

  static void clearCache() {
    _cache.clear();
  }
}
```

---

## Image Loading & Caching

### DO: Efficient Image Handling
- Use `Image.network` with `cacheWidth`/`cacheHeight`
- Implement image caching (use `cached_network_image`)
- Use appropriate image formats (WebP for smaller size)
- Compress images before upload
- Use thumbnails for lists
- Implement progressive loading

### DON'T: Image Performance Issues
- ❌ Load full-resolution images for thumbnails
- ❌ Load images without caching
- ❌ Ignore network errors silently
- ❌ Load images on main thread from storage
- ❌ Cache unlimited images

### Check these patterns

#### Proper Image Loading
```dart
// ❌ WRONG - Full resolution image for thumbnail
Image.network(
  'https://example.com/large-image.jpg', // 4000x4000px
  width: 100,
  height: 100,
)

// ✅ CORRECT - Cache resized image
Image.network(
  'https://example.com/large-image.jpg',
  width: 100,
  height: 100,
  cacheWidth: 100,
  cacheHeight: 100,
)

// ✅ CORRECT - Use cached_network_image
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 100,
  height: 100,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  fadeInDuration: const Duration(milliseconds: 300),
)

// ✅ CORRECT - Async image loading
Future<void> loadImageFromStorage() async {
  final file = File('path/to/image.jpg');
  final bytes = await compute(file.readAsBytes, null);
  // Process bytes off main thread
}
```

---

## Animation Optimization

### DO: Efficient Animations
- Use `AnimatedBuilder` instead of `AnimatedWidget`
- Use `Opacity` with `AnimatedOpacity` instead of `opacity` in painter
- Keep animation performance to 60fps minimum
- Use `SingleTickerProviderStateMixin` for single animation
- Use `TickerProviderStateMixin` for multiple animations
- Profile animations with DevTools

### DON'T: Animation Performance Issues
- ❌ Animate large widget trees
- ❌ Skip `SingleTickerProviderStateMixin`
- ❌ Animate opacity using paint operations
- ❌ Create animators inside build method
- ❌ Animate expensive properties (width/height) repeatedly

### Check these patterns

#### Efficient Animation Structure
```dart
// ❌ WRONG - Rebuilds entire widget
class MyAnimation extends StatefulWidget {
  @override
  State<MyAnimation> createState() => _MyAnimationState();
}

class _MyAnimationState extends State<MyAnimation> {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this, // Wrong - no TickerProvider
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(controller),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.blue,
      ),
    );
  }
}

// ✅ CORRECT - Only rebuilds animating widget
class MyAnimation extends StatefulWidget {
  const MyAnimation();

  @override
  State<MyAnimation> createState() => _MyAnimationState();
}

class _MyAnimationState extends State<MyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this, // Correct - uses SingleTickerProviderStateMixin
    )..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(controller),
      child: const SizedBox(
        width: 100,
        height: 100,
        child: ColoredBox(color: Colors.blue),
      ),
    );
  }
}
```

---

## Network Performance

### DO: Efficient Networking
- Implement request timeout
- Use connection pooling
- Compress request/response bodies
- Cache API responses appropriately
- Use pagination for large datasets
- Implement retry logic with exponential backoff

### DON'T: Network Issues
- ❌ No timeout on requests
- ❌ Unlimited request/response size
- ❌ No caching strategy
- ❌ Load all data at once
- ❌ Retry immediately on failure

### Check these patterns

#### Proper HTTP Configuration
```dart
// ✅ CORRECT - Configured Dio client
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'MyApp/1.0',
    },
    responseType: ResponseType.json,
  ),
);

// Add interceptors for logging, auth, retry
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add auth token
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Refresh token and retry
      }
      return handler.next(error);
    },
  ),
);
```

---

## Common Performance Anti-Patterns

### Anti-Pattern 1: Expensive Operations in Build
```dart
// ❌ WRONG - Parsing JSON on every build
@override
Widget build(BuildContext context) {
  final data = jsonDecode(apiResponse); // Every rebuild!
  return Text(data['name']);
}

// ✅ CORRECT - Parse once, cache result
late final Map<String, dynamic> _data;

@override
void initState() {
  super.initState();
  _data = jsonDecode(apiResponse);
}

@override
Widget build(BuildContext context) {
  return Text(_data['name']);
}
```

### Anti-Pattern 2: Synchronous File I/O
```dart
// ❌ WRONG - Blocks UI thread
final data = File('large-file.txt').readAsStringSync();

// ✅ CORRECT - Async file I/O
final data = await File('large-file.txt').readAsString();

// Or use compute for heavy processing
final result = await compute(parseFile, 'large-file.txt');
```

### Anti-Pattern 3: Unoptimized Database Queries
```dart
// ❌ WRONG - Fetches all columns, no limit
final allUsers = await db.query('users');
final activeUsers = allUsers.where((u) => u.isActive).toList();

// ✅ CORRECT - Query only what's needed
final activeUsers = await db.query(
  'users',
  where: 'active = 1',
  orderBy: 'name ASC',
  limit: 100,
);
```
