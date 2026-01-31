#!/usr/bin/env dart
/// Silent Bug Detection Script
/// Analyzes Dart code for silent bugs: logic errors, unreachable code,
/// ignored futures, state inconsistencies, etc.
/// Usage: dart detect_silent_bugs.dart [directory_or_file]

import 'dart:io';
import 'dart:convert';

class SilentBugDetector {
  final List<String> filesAnalyzed = [];
  final List<Issue> issues = [];

  int totalLines = 0;
  int codeLines = 0;

  Future<void> analyze(String path) async {
    final entity = FileSystemEntity.typeSync(path);

    if (entity == FileSystemEntityType.directory) {
      await _analyzeDirectory(path);
    } else if (entity == FileSystemEntityType.file && path.endsWith('.dart')) {
      await _analyzeFile(path);
    } else {
      print('Error: Must be a .dart file or directory containing .dart files');
      exit(1);
    }
  }

  Future<void> _analyzeDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (dartFiles.isEmpty) {
      print('No .dart files found in $dirPath');
      return;
    }

    for (final file in dartFiles) {
      await _analyzeFile(file.path);
    }
  }

  Future<void> _analyzeFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final lines = content.split('\n');

    filesAnalyzed.add(filePath);
    totalLines += lines.length;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isNotEmpty && !line.trim().startsWith('//')) {
        codeLines++;
      }

      _checkLine(line, i + 1, filePath, lines);
    }
  }

  void _checkLine(String line, int lineNum, String filePath, List<String> allLines) {
    // Check for ignored futures (unawaited calls)
    _checkIgnoredFutures(line, lineNum, filePath);

    // Check for unreachable code
    _checkUnreachableCode(line, lineNum, filePath, allLines);

    // Check for missing error handling
    _checkAsyncErrors(line, lineNum, filePath);

    // Check for incorrect equality
    _checkEqualityIssues(line, lineNum, filePath);

    // Check for potential null reference errors
    _checkNullSafetyIssues(line, lineNum, filePath);

    // Check for state inconsistencies
    _checkStateIssues(line, lineNum, filePath);

    // Check for logic errors
    _checkLogicErrors(line, lineNum, filePath);
  }

  void _checkIgnoredFutures(String line, int lineNum, String filePath) {
    // Pattern: function call that returns Future but not awaited
    final patterns = [
      RegExp(r'\b(api\.\w+|fetch\w+|load\w+|save\w+|delete\w+)\s*\(\s*\);'),
      RegExp(r'\.then\(.*\);\s*$'),
      RegExp(r'\.catchError.*;\s*$'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(line)) {
        // Exception: if line starts with 'await' or 'unawaited', it's OK
        if (!line.contains('await') && !line.contains('unawaited')) {
          issues.add(Issue(
            severity: 'HIGH',
            type: 'Ignored Future',
            message: 'Future created but not awaited or unawaited()',
            file: filePath,
            line: lineNum,
            code: line.trim(),
          ));
        }
      }
    }
  }

  void _checkUnreachableCode(String line, int lineNum, String filePath, List<String> allLines) {
    // Check for return/throw followed by code
    if (line.trim().startsWith('return ') || line.trim().startsWith('throw ')) {
      if (lineNum < allLines.length) {
        final nextLine = allLines[lineNum].trim();
        if (nextLine.isNotEmpty &&
            !nextLine.startsWith('}') &&
            !nextLine.startsWith('//') &&
            !nextLine.startsWith('*/')) {
          issues.add(Issue(
            severity: 'MEDIUM',
            type: 'Unreachable Code',
            message: 'Code after return/throw statement will never execute',
            file: filePath,
            line: lineNum,
            code: line.trim(),
          ));
        }
      }
    }
  }

  void _checkAsyncErrors(String line, int lineNum, String filePath) {
    // Check for uncaught async errors
    if (line.contains('async {') && !line.contains('try')) {
      issues.add(Issue(
        severity: 'HIGH',
        type: 'Missing Error Handling',
        message: 'Async function without try-catch for error handling',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }

    // Check for missing await on async calls
    if (line.contains('Future<') && line.contains('();') && !line.contains('await')) {
      issues.add(Issue(
        severity: 'HIGH',
        type: 'Unawaited Async Call',
        message: 'Async function called without await',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }
  }

  void _checkEqualityIssues(String line, int lineNum, String filePath) {
    // Check for using == instead of identical for reference comparison
    if (line.contains('==') && (line.contains('this') || line.contains('self'))) {
      issues.add(Issue(
        severity: 'MEDIUM',
        type: 'Equality Issue',
        message: 'Use identical() for reference comparison, not ==',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }
  }

  void _checkNullSafetyIssues(String line, int lineNum, String filePath) {
    // Check for unchecked null access
    if (line.contains('!.') && !line.contains('if (') && !line.contains('?')) {
      issues.add(Issue(
        severity: 'MEDIUM',
        type: 'Null Safety Issue',
        message: 'Using ! operator without prior null check',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }
  }

  void _checkStateIssues(String line, int lineNum, String filePath) {
    // Check for uninitialized late variables
    if (line.contains('late ') && !line.contains('=') && !line.contains('{')) {
      issues.add(Issue(
        severity: 'MEDIUM',
        type: 'Uninitialized Late Variable',
        message: 'Late variable declared without initialization',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }
  }

  void _checkLogicErrors(String line, int lineNum, String filePath) {
    // Check for suspicious conditions
    if (line.contains('if (true)') || line.contains('if (false)')) {
      issues.add(Issue(
        severity: 'HIGH',
        type: 'Logic Error',
        message: 'Suspicious hardcoded boolean condition',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }

    // Check for assignment in condition
    if (RegExp(r'if\s*\(\s*\w+\s*=\s*').hasMatch(line)) {
      issues.add(Issue(
        severity: 'MEDIUM',
        type: 'Logic Error',
        message: 'Assignment in condition (should be comparison?)',
        file: filePath,
        line: lineNum,
        code: line.trim(),
      ));
    }
  }

  void printReport() {
    print('\n${'='*60}');
    print('SILENT BUG DETECTION REPORT');
    print('${'='*60}\n');

    print('Analysis Summary:');
    print('  Files analyzed: ${filesAnalyzed.length}');
    print('  Total lines: $totalLines');
    print('  Code lines: $codeLines');
    print('  Issues found: ${issues.length}\n');

    if (issues.isEmpty) {
      print('✓ No silent bugs detected!');
      print('${'='*60}\n');
      return;
    }

    // Group by severity
    final byS everity = <String, List<Issue>>{};
    for (final issue in issues) {
      (bySeverity[issue.severity] ??= []).add(issue);
    }

    // Print by severity
    const severities = ['HIGH', 'MEDIUM', 'LOW'];
    for (final severity in severities) {
      final sevIssues = bySeverity[severity];
      if (sevIssues == null || sevIssues.isEmpty) continue;

      print('$severity SEVERITY (${sevIssues.length})');
      print('-' * 60);

      for (int i = 0; i < min(5, sevIssues.length); i++) {
        final issue = sevIssues[i];
        print('  ${i + 1}. ${issue.type}');
        print('     File: ${issue.file}:${issue.line}');
        print('     ${issue.message}');
        print('     Code: ${issue.code}');
        print('');
      }

      if (sevIssues.length > 5) {
        print('  ... and ${sevIssues.length - 5} more\n');
      }
    }

    print('${'='*60}');
    print('RECOMMENDATIONS:');
    print('${'='*60}');
    print('''
  1. Fix HIGH severity issues immediately
  2. Use 'flutter analyze' for comprehensive static analysis
  3. Enable strict linting rules in analysis_options.yaml
  4. Use 'unawaited()' for intentionally ignored futures
  5. Implement proper error handling in async functions
  6. Use null-aware operators (?.) instead of force unwrapping (!)
  7. Verify all Future-based operations are properly awaited
''');
  }

  int min(int a, int b) => a < b ? a : b;
}

class Issue {
  final String severity;
  final String type;
  final String message;
  final String file;
  final int line;
  final String code;

  Issue({
    required this.severity,
    required this.type,
    required this.message,
    required this.file,
    required this.line,
    required this.code,
  });
}

Future<void> main(List<String> args) async {
  String path = 'lib';

  if (args.isNotEmpty) {
    path = args[0];
  }

  print('Starting silent bug detection...');
  print('Analyzing: $path\n');

  final detector = SilentBugDetector();
  await detector.analyze(path);
  detector.printReport();

  exit(detector.issues.isEmpty ? 0 : 1);
}
