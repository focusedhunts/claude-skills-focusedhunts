# 🔍 Dart Detective

**Expert code review and troubleshooting for Flutter Android applications—Dart language focused**

Finds bugs that other tools miss. Both the visible crashes AND the silent logic errors that silently corrupt data or cause incorrect behavior without throwing exceptions.

---

## What It Does

Dart Detective is a comprehensive code review skill that analyzes Flutter Android apps from the ground up:

1. **Dart Language Foundation** (the root of most issues)
   - Null safety violations and improper nullable type handling
   - Type system errors and unsafe casting
   - Async/await anti-patterns and ignored futures
   - Collection handling and immutability violations
   - Performance issues and inefficient code patterns

2. **Security Analysis**
   - Credential storage and encryption validation
   - API/network security and certificate handling
   - Authentication and authorization patterns
   - Sensitive data handling in memory
   - Android Keystore integration
   - Third-party library vetting

3. **Bug Detection (Visible + Silent)**
   - **Visible**: Null pointer exceptions, type errors, runtime crashes, resource leaks
   - **Silent**: Logic errors, routing issues, state inconsistencies, ignored futures, missing error handling, data validation gaps

4. **Performance & Architecture**
   - Memory leaks and inefficient resource management
   - List/scroll performance optimization
   - State management patterns (Riverpod, Bloc)
   - Navigation structure and dependency injection
   - Over-engineering detection

5. **Android Integration**
   - Lifecycle management and resource cleanup
   - Permission handling patterns
   - Platform channel safety and communication
   - Service management and background execution

---

## Who Should Use This

- **Password Managers & Security Apps** - Enhanced scrutiny for credential handling
- **Performance-Critical Apps** - Battery optimization, responsiveness requirements
- **Teams** - Systematic code quality and architectural validation
- **Solo Developers** - Expert guidance for all code decisions
- **Android Specialists** - Deep Flutter/Android integration expertise

---

## How to Use

### Proactive Code Review
*"Please review my Flutter authentication module for security and best practices"*

Submit code → Get comprehensive analysis across language, framework, platform, and security layers → Implement recommendations

### Troubleshooting Specific Issues
*"Users report the app crashes when opening certain saved passwords"*

Describe the issue → Dart Detective identifies root cause → Provides corrected implementation

### Security Audits
*"Audit my password manager's credential storage and API communication"*

Get focused security review with verification of encryption, secure storage, memory clearing, and API security

### Performance Analysis
*"The app is sluggish when scrolling through large lists"*

Get optimization suggestions for list rendering, memory management, and efficient patterns

---

## What Gets Reviewed

✓ Null safety violations and nullable type handling
✓ Type system errors and unsafe operations
✓ Async/await anti-patterns and uncaught exceptions
✓ Ignored futures and missing error handlers
✓ Logic errors and unreachable code
✓ Routing issues and security bypasses
✓ State management correctness and memory leaks
✓ Credential storage and encryption
✓ API security and network handling
✓ Permission patterns and Android security
✓ Resource cleanup and lifecycle management
✓ Over-engineering and custom workarounds
✓ Performance inefficiencies and memory issues

---

## Installation

1. **Add to Claude Code**
   - Import the `dart-detective` skill from this repository
   - Load the `SKILL.md` file into your Claude Code environment

2. **Use immediately**
   - Submit Flutter code for review
   - Ask focused questions about specific issues
   - Use automation scripts for diagnostics

3. **Optional: Use automation scripts**
   - `flutter_diagnostics` - Environment and SDK validation
   - `analyze_logs.py` - Error pattern detection from logs
   - `dependency_check` - Dependency vulnerability scanning
   - `detect_silent_bugs.dart` - Static analysis for logic errors

---

## Example Use Cases

### Security Audit: Password Manager
*"Please perform a comprehensive security review of my Flutter password manager, focusing on credential storage, API communication, and memory handling."*

→ Receives detailed analysis of encryption, storage validation, API security, memory management, and Dart-level security issues

### Performance Troubleshooting
*"Users report lag when scrolling through 1000+ saved passwords. Can you identify the bottleneck?"*

→ Receives list rendering analysis, const optimization suggestions, caching patterns, and Dart performance improvements

### Architecture Validation
*"I've implemented state management with Riverpod. Is my architecture scalable and following best practices?"*

→ Receives review of provider patterns, immutability, lifecycle management, error handling, and Dart language usage

### Android Integration Review
*"Can you review my platform channel implementation and permissions handling?"*

→ Receives platform channel safety analysis, error handling verification, permissions flow review, and Dart async integration

---

## Key Features

- **Layered Approach**: Review from Dart language foundation → Flutter framework → Android platform
- **Silent Bug Detection**: Finds logic errors and state issues that don't throw exceptions
- **Security-First**: Prioritizes security vulnerabilities in all reviews
- **Actionable Results**: Each finding includes ready-to-implement solutions, not just problems
- **Automation Included**: Scripts for diagnostics, log analysis, and dependency checking
- **Modular**: Load only the reference materials relevant to your review focus
- **Password Manager Expertise**: Enhanced scrutiny for credential storage and sensitive apps

---

## Review Output

Each code review provides:

1. **Executive Summary** - Overall health, critical findings, recommended actions
2. **Detailed Findings** - Issues organized by severity, with impact analysis
3. **Code Examples** - Incorrect vs. corrected implementations
4. **Action Items** - Prioritized list with effort estimates

---

## Technology Support

- **Flutter Versions:** 3.0+
- **Dart Versions:** 3.0+
- **Android API Level:** 21+ (Android 5.0+)
- **State Management:** Riverpod 2.0+, Bloc 8.0+
- **Navigation:** GoRouter, Navigator

---

## Getting Started

1. Load the skill into Claude Code
2. Submit Flutter code with context about your app
3. Specify the review focus (security, performance, bug hunting, architecture, etc.)
4. Receive comprehensive analysis with explanations and solutions
5. Implement recommendations or iterate with follow-up questions

---

**Finds the bugs in your Dart code that other tools miss.**
