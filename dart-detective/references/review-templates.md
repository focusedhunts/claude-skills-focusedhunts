# Review Templates

Modular templates and checklists for conducting focused code reviews. Load the relevant sections based on your review focus.

## Table of Contents

- [Issue Reporting Format](#issue-reporting-format)
- [Issue Categorization](#issue-categorization)
- [Security Review Checklist](#security-review-checklist)
- [Bug Detection Checklist](#bug-detection-checklist)
- [State Management Review](#state-management-review)
- [Platform Channel & Android Review](#platform-channel--android-review)
- [Performance Review](#performance-review)
- [Output Format Guidelines](#output-format-guidelines)
- [Quality Checklist](#quality-checklist)

---

## Issue Reporting Format

Use this format when documenting each identified issue:

**Issue:** Clear, concise title (1-10 words)

**Severity:** CRITICAL | IMPORTANT | MINOR

**Category:** Security | Bug | Performance | Style | Architecture

**File:** Path to affected file(s)

**Line:** Specific line numbers if applicable

**Problem:** What's wrong and why it matters (2-4 sentences)

**Impact:** How it affects users (security, performance, UX, stability)

**Solution:** Corrected code or specific steps to fix

### Example Issue Report

```
Issue: Plaintext password storage in SharedPreferences
Severity: CRITICAL
Category: Security
File: lib/services/auth_service.dart (line 45)
Problem: User credentials stored in unencrypted SharedPreferences. This violates null safety and security best practices, making passwords accessible to any app with storage access.
Impact: User credentials can be accessed by any malicious app installed on device. This is critical for a password manager.
Solution: Use flutter_secure_storage instead:

  final secureStorage = const FlutterSecureStorage();
  await secureStorage.write(key: 'password', value: userPassword);
```

---

## Issue Categorization

Organize findings by severity and category:

### CRITICAL (Must fix before release)

- Security vulnerabilities (credential exposure, encryption failures, auth bypasses)
- Crashes and runtime errors (null pointer exceptions, type errors, platform errors)
- Functionality bugs (features that don't work as designed)
- Data loss scenarios (unhandled errors causing data corruption or loss)
- Memory leaks that impact app stability
- Unhandled exceptions in critical paths

### IMPORTANT (Fix in next sprint)

- Memory leaks (especially in long-lived services or streams)
- Performance degradation (noticeable slowdowns, battery impact)
- Architectural violations (breaks established patterns in codebase)
- Missing error handling (unhandled edge cases, no fallbacks)
- Security best practices (things that could be exploited with effort)
- Incomplete implementations (partially working features)

### MINOR (Future improvement)

- Code style improvements (naming, formatting)
- Performance micro-optimizations (negligible user impact)
- Test coverage gaps (untested code paths)
- Documentation improvements
- Code cleanup and refactoring opportunities
- Non-critical best practice violations

---

## Security Review Checklist

Use when reviewing password managers or security-critical code.

### Credential Storage

- [ ] Credentials stored encrypted (flutter_secure_storage or Hive with encryption)
- [ ] No plaintext credentials in SharedPreferences
- [ ] No hardcoded credentials in code
- [ ] Master password cleared from memory when app pauses
- [ ] Sensitive data cleared when app exits
- [ ] Android Keystore used for key material
- [ ] EncryptedSharedPreferences used if SharedPreferences necessary

### API & Network Security

- [ ] HTTPS enforced (no plain HTTP)
- [ ] Certificate validation correct
- [ ] Credentials sent in request body, never query params
- [ ] API tokens rotated appropriately
- [ ] Request timeout configured
- [ ] Responses validated before use
- [ ] No API keys/tokens exposed in logs
- [ ] Error responses don't leak sensitive information

### Authentication & Authorization

- [ ] Login/logout flow correct
- [ ] Session management secure
- [ ] Tokens expire appropriately
- [ ] Refresh token flow implemented if applicable
- [ ] Biometric auth properly validated
- [ ] No bypasses to authentication checks

### Data Protection

- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit
- [ ] Temporary files cleared (camera, documents, etc.)
- [ ] Clipboard data cleared after use
- [ ] Database encrypted if using local database
- [ ] No sensitive data in logs or debug output
- [ ] Memory sanitization for passwords/tokens

### Input Validation & Sanitization

- [ ] Email addresses validated
- [ ] URLs validated before opening
- [ ] JSON/API responses validated before use
- [ ] File paths sanitized (no path traversal)
- [ ] No direct shell command execution
- [ ] XSS prevention (if webview used)
- [ ] SQL injection prevention (if SQL used)

### Platform Security (Android)

- [ ] Permissions requested justified and minimal
- [ ] Runtime permissions handled correctly
- [ ] Manifest permissions correct
- [ ] Debuggable set to false in release build
- [ ] No world-readable files
- [ ] Content providers properly secured
- [ ] Intents validated before opening
- [ ] No sensitive data in intent extras

### Dependencies & Libraries

- [ ] All dependencies are maintained and trusted
- [ ] No known vulnerabilities in dependency versions
- [ ] Dependency versions locked (pubspec.lock committed)
- [ ] Audit trail for critical security dependencies
- [ ] Custom crypto implementations avoided
- [ ] Security libraries properly used (not misused)

---

## Bug Detection Checklist

### Visible Bugs

- [ ] App crashes during normal usage
- [ ] Features don't work as designed
- [ ] UI displays incorrectly
- [ ] Exceptions thrown and logged
- [ ] Type errors in debug output
- [ ] Null reference errors
- [ ] Undefined methods called

### Silent Bugs (Non-Visible Issues)

- [ ] Ignored futures (unawaited operations)
- [ ] Uncaught async exceptions
- [ ] Logic errors (wrong calculations, invalid state transitions)
- [ ] Routing issues (undefined routes, navigation problems)
- [ ] State inconsistencies (UI and data out of sync)
- [ ] Race conditions (async operations conflicting)
- [ ] Missing validation (unchecked assumptions about data)
- [ ] Incomplete error handling (errors swallowed silently)
- [ ] Side effects in unexpected places
- [ ] Resource leaks (streams, listeners not cancelled)

### Common Error Patterns

- [ ] Null pointer exceptions (proper null safety)
- [ ] Type casting errors (unsafe as operator)
- [ ] Index out of bounds (list access without checks)
- [ ] Concurrent modification (modifying collection during iteration)
- [ ] Memory leaks (retained references, uncancelled listeners)
- [ ] Deadlocks (circular dependencies, blocking operations)
- [ ] Data race conditions (shared mutable state)

---

## State Management Review

### Provider/Riverpod Patterns

- [ ] Providers immutable
- [ ] No mutable state in providers
- [ ] Dependencies between providers correct
- [ ] Family modifiers used for parameterized providers
- [ ] `.select()` used to listen to specific fields (not entire state)
- [ ] `.watch()` used appropriately in providers
- [ ] `.listen()` used for side effects (notifications, analytics)
- [ ] Consumer widgets don't trigger unnecessary rebuilds

### Lifecycle & Cleanup

- [ ] Listeners cancelled on dispose
- [ ] Streams closed properly
- [ ] Controllers disposed (TextEditingController, ScrollController, etc.)
- [ ] `ref.onDispose()` used for cleanup
- [ ] No memory leaks from retained references
- [ ] Async operations cancelled when widget disposed

### Immutability & Updates

- [ ] State updates create new instances (copyWith, spread operator)
- [ ] No direct mutation of state objects
- [ ] Collections are immutable or treated as immutable
- [ ] Copy-on-write pattern followed for updates
- [ ] Immutable libraries used (freezed, built_value) where appropriate

### Error Handling

- [ ] AsyncValue handles loading/error/data states
- [ ] Error states displayed to user
- [ ] Errors logged appropriately
- [ ] Retry mechanisms implemented where needed
- [ ] Fallback values provided where appropriate

### Architecture

- [ ] Single responsibility for each provider
- [ ] Clear data flow (no circular dependencies)
- [ ] Separation of concerns (UI/state/data layers)
- [ ] Testable state management (can test providers in isolation)
- [ ] Scalable pattern (works as app grows)

---

## Platform Channel & Android Review

### Platform Channel Usage

- [ ] Messages properly serialized/deserialized
- [ ] Error handling bidirectional (Dart and Kotlin)
- [ ] Timeouts configured
- [ ] Null values handled correctly
- [ ] Type safety maintained across channel
- [ ] Callbacks properly managed

### Android Integration

- [ ] Permissions in manifest correct
- [ ] Runtime permissions requested and handled
- [ ] Lifecycle methods respected (onResume, onPause, etc.)
- [ ] Background services properly implemented
- [ ] Notifications properly configured
- [ ] Intents validated before handling
- [ ] No hardcoded paths or configuration

### Manifest Configuration

- [ ] Debuggable false in release
- [ ] Required features specified
- [ ] Permissions minimized
- [ ] Content providers properly secured
- [ ] Activities configured for orientation
- [ ] Deep links validated

---

## Performance Review

### Build Efficiency

- [ ] Const constructors used where possible
- [ ] const keyword used for constant values
- [ ] Rebuilds minimized (proper state management)
- [ ] Consumer widgets scoped correctly
- [ ] onGenerateRoute/onGenerateTitle doesn't rebuild
- [ ] Build methods are fast (no heavy computation)

### List & Scroll Performance

- [ ] ListView.builder used instead of ListView for long lists
- [ ] Caching implemented for expensive computations
- [ ] Images cached appropriately
- [ ] Addwisereposts implemented for incremental loading
- [ ] Key usage correct (especially in list items)
- [ ] Duplicate items filtered out

### Memory Management

- [ ] Large objects not retained unnecessarily
- [ ] Streams and listeners properly cancelled
- [ ] Image caches sized appropriately
- [ ] Caches cleared when appropriate
- [ ] No memory leaks from circular references
- [ ] Heap size reasonable for app functionality

### Image Loading & Caching

- [ ] Images cached by CachedNetworkImage or similar
- [ ] Image sizes optimized (not loading huge images)
- [ ] Memory cache limits configured
- [ ] Disk cache limits configured
- [ ] Placeholder images provided
- [ ] Error handling for failed image loads

### Animation Optimization

- [ ] 60 FPS target met
- [ ] Heavy computations not on animation frame
- [ ] AnimationController disposed properly
- [ ] SingleTickerProviderStateMixin used correctly
- [ ] Transform used instead of layout changes where possible

### Network Performance

- [ ] HTTP/2 or similar used if available
- [ ] Request/response compression enabled
- [ ] Connection pooling configured
- [ ] DNS prefetch/preconnect used
- [ ] Caching headers respected
- [ ] Batch requests where appropriate

---

## Output Format Guidelines

When presenting code review findings:

### 1. Executive Summary (2-3 sentences)

- Overall health assessment of the code
- Most critical finding or main theme
- Recommended immediate next step

Example:
```
The authentication flow is mostly secure but has a critical vulnerability in credential storage. The app stores passwords in plaintext SharedPreferences, which makes credentials accessible to any app on the device. Migrate to flutter_secure_storage immediately before release.
```

### 2. Detailed Findings (organized by severity/category)

- Critical issues first (security, crashes, data loss)
- Important issues next (architecture, performance)
- Minor issues last (style, cleanup)
- Each issue clearly formatted with Issue/Severity/Category/File/Problem/Impact/Solution
- Provided code examples for each fix
- Clear explanation of why this matters

### 3. Code Improvements (prepared for direct use)

- Corrected code blocks
- Clear indication of changes (highlight changed lines)
- Explanation of why each change improves the code
- Before/after side-by-side comparison
- Ready to paste/apply by developer

### 4. Summary & Action Items

- List of all issues identified (title + severity)
- Priority order for fixes (CRITICAL → IMPORTANT → MINOR)
- Estimated effort for each major issue (small/medium/large)
- Recommended testing strategy for key fixes
- Timeline for addressing issues (if applicable)

---

## Quality Checklist

Before finalizing a code review, verify:

- [ ] All security issues identified (especially for password managers)
- [ ] All critical bugs flagged (crashes, errors, data loss)
- [ ] Performance issues noted with user impact
- [ ] Best practice violations documented
- [ ] Solutions provided for all issues (not just identifying problems)
- [ ] Code examples are correct and tested mentally
- [ ] Changes are minimal and focused (not over-engineering)
- [ ] Explanations are clear and reference materials provided
- [ ] Issues prioritized correctly (CRITICAL → IMPORTANT → MINOR)
- [ ] Android/platform-specific concerns addressed
- [ ] Dart language patterns reviewed (null safety, async, etc.)
- [ ] Silent bugs considered (ignored futures, uncaught errors, logic errors)
- [ ] Resource cleanup verified (streams, listeners, controllers)
- [ ] Error handling paths covered
- [ ] State management patterns followed

### Review Completeness

- [ ] All files reviewed (not just obvious ones)
- [ ] All code paths tested mentally (success and error paths)
- [ ] Edge cases considered (null, empty, invalid input)
- [ ] Integration points checked (APIs, platform channels, state)
- [ ] Dependencies reviewed (no unknown or suspicious libraries)

### Presentation Quality

- [ ] Issues clearly explained (not cryptic)
- [ ] Solutions are actionable (developer can implement immediately)
- [ ] Code examples compile and work (tested mentally)
- [ ] Suggestions are constructive (not just criticism)
- [ ] Feedback is encouraging while maintaining standards
