#!/usr/bin/env python3
"""
Flutter Log Analysis Script
Parses Flutter/Android logs and identifies error patterns, stack traces, and anomalies.
Usage: python3 analyze_logs.py [log_file] [--export json|txt]
"""

import sys
import re
from pathlib import Path
from collections import defaultdict
from datetime import datetime

class LogAnalyzer:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.stack_traces = []
        self.patterns = defaultdict(int)
        self.security_issues = []
        self.performance_issues = []

    def analyze_file(self, filepath):
        """Analyze a log file for errors and patterns"""
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except FileNotFoundError:
            print(f"Error: File not found: {filepath}")
            return False

        lines = content.split('\n')
        for i, line in enumerate(lines):
            self._process_line(line, i, lines)

        return True

    def analyze_stdin(self):
        """Analyze log from stdin"""
        lines = sys.stdin.readlines()
        for i, line in enumerate(lines):
            self._process_line(line.strip(), i, lines)

    def _process_line(self, line, index, all_lines):
        """Process individual log line"""
        if not line.strip():
            return

        # Check for various error patterns
        self._check_error_patterns(line)
        self._check_null_safety_issues(line)
        self._check_async_errors(line)
        self._check_security_issues(line)
        self._check_performance_issues(line)
        self._check_stack_traces(line, index, all_lines)

    def _check_error_patterns(self, line):
        """Detect common error patterns"""
        error_patterns = {
            r'(NullPointerException|null pointer)': 'Null Pointer Exception',
            r'(NoSuchMethodError)': 'No Such Method Error',
            r'(ClassCastException)': 'Type Cast Error',
            r'(OutOfMemoryError)': 'Out of Memory',
            r'(StackOverflowError)': 'Stack Overflow',
            r'(IOException|File not found)': 'File I/O Error',
            r'(NetworkError|Connection refused)': 'Network Error',
            r'(TimeoutException)': 'Timeout Error',
            r'(FormatException|JSON parsing)': 'Format/JSON Parse Error',
            r'(StateError|Invalid state)': 'State Error',
        }

        for pattern, name in error_patterns.items():
            if re.search(pattern, line, re.IGNORECASE):
                self.errors.append({
                    'type': name,
                    'line': line.strip()
                })
                self.patterns[name] += 1

    def _check_null_safety_issues(self, line):
        """Detect null safety violations"""
        null_patterns = [
            r'null safety',
            r'nullable type',
            r'null propagation',
            r'Unhandled Exception.*null',
            r'accessing.*null',
        ]

        for pattern in null_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                self.warnings.append({
                    'type': 'Null Safety Issue',
                    'line': line.strip()
                })
                self.patterns['Null Safety Issue'] += 1

    def _check_async_errors(self, line):
        """Detect async/await and Future-related issues"""
        async_patterns = [
            r'(uncaught|unhandled).*(future|async|await)',
            r'future.*failed',
            r'(bad state|invalid async)',
            r'stream.*closed',
            r'subscript.*cancelled',
            r'(MissingPluginException)',
        ]

        for pattern in async_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                self.errors.append({
                    'type': 'Async/Future Error',
                    'line': line.strip()
                })
                self.patterns['Async Error'] += 1

    def _check_security_issues(self, line):
        """Detect potential security issues"""
        security_patterns = [
            (r'(password|secret|token|api.*key).*(stored|saved|hardcoded)', 'Credential Storage'),
            (r'(ssl|certificate|tls).*verification.*(disabled|false)', 'SSL Verification Disabled'),
            (r'(sql.*injection|command.*injection)', 'Injection Vulnerability'),
            (r'(xss|cross.*site.*scripting)', 'XSS Vulnerability'),
            (r'debug.*(enabled|true).*production', 'Debug Enabled in Production'),
            (r'log.*password|password.*log', 'Password in Logs'),
        ]

        for pattern, issue_type in security_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                self.security_issues.append({
                    'type': issue_type,
                    'line': line.strip()
                })
                self.patterns[f'Security: {issue_type}'] += 1

    def _check_performance_issues(self, line):
        """Detect potential performance issues"""
        perf_patterns = [
            (r'ANR.*application not responding', 'ANR (App Not Responding)'),
            (r'(jank|frame.*drop|dropped.*frame)', 'Dropped Frames'),
            (r'(memory.*pressure|low.*memory)', 'Memory Pressure'),
            (r'(OutOfMemory|heap.*size)', 'Memory Issues'),
            (r'(garbage.*collect|GC)', 'Garbage Collection'),
            (r'(disk.*full|storage.*full)', 'Disk Full'),
        ]

        for pattern, issue_type in perf_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                self.performance_issues.append({
                    'type': issue_type,
                    'line': line.strip()
                })
                self.patterns[f'Performance: {issue_type}'] += 1

    def _check_stack_traces(self, line, index, all_lines):
        """Extract and parse stack traces"""
        if 'at ' in line or 'File' in line and 'Line' in line:
            # Collect multi-line stack trace
            trace = [line]
            i = index + 1
            while i < len(all_lines) and (all_lines[i].startswith('at ') or
                                          all_lines[i].startswith('  ') or
                                          'File' in all_lines[i]):
                trace.append(all_lines[i])
                i += 1
            if len(trace) > 1:
                self.stack_traces.append('\n'.join(trace))

    def print_report(self):
        """Print formatted analysis report"""
        print("\n" + "="*60)
        print("FLUTTER LOG ANALYSIS REPORT")
        print("="*60 + "\n")

        # Summary
        print(f"Total Issues Found: {len(self.errors) + len(self.warnings)}")
        print(f"  - Critical Errors: {len(self.errors)}")
        print(f"  - Warnings: {len(self.warnings)}")
        print(f"  - Security Issues: {len(self.security_issues)}")
        print(f"  - Performance Issues: {len(self.performance_issues)}")
        print()

        # Error Patterns
        if self.patterns:
            print("ERROR PATTERNS DETECTED:")
            print("-" * 60)
            for pattern, count in sorted(self.patterns.items(), key=lambda x: x[1], reverse=True):
                print(f"  • {pattern}: {count} occurrence(s)")
            print()

        # Critical Errors
        if self.errors:
            print("CRITICAL ERRORS:")
            print("-" * 60)
            for i, error in enumerate(self.errors[:10], 1):  # Show first 10
                print(f"  {i}. [{error['type']}]")
                print(f"     {error['line'][:80]}...")
            if len(self.errors) > 10:
                print(f"  ... and {len(self.errors) - 10} more")
            print()

        # Security Issues
        if self.security_issues:
            print("SECURITY ISSUES:")
            print("-" * 60)
            for i, issue in enumerate(self.security_issues[:10], 1):
                print(f"  {i}. [{issue['type']}]")
                print(f"     {issue['line'][:80]}...")
            if len(self.security_issues) > 10:
                print(f"  ... and {len(self.security_issues) - 10} more")
            print()

        # Performance Issues
        if self.performance_issues:
            print("PERFORMANCE ISSUES:")
            print("-" * 60)
            for i, issue in enumerate(self.performance_issues[:5], 1):
                print(f"  {i}. [{issue['type']}]")
                print(f"     {issue['line'][:80]}...")
            if len(self.performance_issues) > 5:
                print(f"  ... and {len(self.performance_issues) - 5} more")
            print()

        # Stack Traces
        if self.stack_traces:
            print("STACK TRACES:")
            print("-" * 60)
            for i, trace in enumerate(self.stack_traces[:3], 1):  # Show first 3
                print(f"\nTrace {i}:")
                print(trace[:500] + ("..." if len(trace) > 500 else ""))
            if len(self.stack_traces) > 3:
                print(f"\n... and {len(self.stack_traces) - 3} more stack traces")
            print()

        print("="*60)
        print("RECOMMENDATIONS:")
        print("-" * 60)
        if self.errors:
            print("  1. Address critical errors immediately (NullPointerException, etc.)")
        if self.async_errors:
            print("  2. Review async/await code for proper error handling")
        if self.security_issues:
            print("  3. Address security issues before release")
        if self.performance_issues:
            print("  4. Investigate performance issues (ANRs, memory usage)")
        print("  5. Run 'flutter doctor -v' to verify environment")
        print("="*60 + "\n")

def main():
    if len(sys.argv) < 2:
        # Read from stdin if no file provided
        analyzer = LogAnalyzer()
        print("Reading logs from stdin (Ctrl+D to end)...")
        analyzer.analyze_stdin()
    else:
        logfile = sys.argv[1]
        analyzer = LogAnalyzer()

        if not analyzer.analyze_file(logfile):
            sys.exit(1)

    analyzer.print_report()

    # Return error code if issues found
    if analyzer.errors or analyzer.security_issues:
        sys.exit(1)

if __name__ == '__main__':
    main()
