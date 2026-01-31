# Claude Skills by Focused Hunts

Quality Claude Code skills for real-world problems.

## Available Skills

### 🔍 [Dart Detective](./DART_DETECTIVE.md)

Expert code review and troubleshooting for Flutter Android apps. Finds bugs that other tools miss—both the visible crashes and the silent logic errors that silently corrupt data or cause unexpected behavior.

**What it does:**
- Dart language-first review (the foundation of most issues)
- Finds visible bugs (crashes, null safety errors) AND silent bugs (logic errors, routing issues, state inconsistencies)
- Security audits for password managers and sensitive apps
- Performance analysis with actionable optimizations

[View Dart Detective →](./DART_DETECTIVE_SKILL_README.md)

---

## Installation

### Quick Start

1. **Clone or download this repository**
   ```bash
   git clone https://github.com/yourusername/claude-skills-focusedhunts.git
   cd claude-skills-focusedhunts
   ```

2. **Install a skill into Claude Code**
   - Open Claude Code
   - Use the skill loader to add `dart-detective` from your local copy
   - Or reference the SKILL.md file directly in your Claude Code environment

3. **Start using the skill**
   - Submit Flutter code for review
   - Ask for security audits, performance analysis, or bug hunting
   - Use automation scripts for diagnostics

### For Each Skill

Each skill directory is self-contained:
```
dart-detective/
├── SKILL.md              # Core skill definition (load this into Claude Code)
├── references/           # Reference materials (loaded as needed)
└── scripts/              # Automation tools (optional helpers)
```

---

## How to Use

### Specific example from VS Code Skill execution with association to Flutter expert skills by Claude
Perform a review of this project using the @.github/skills/dart-detective/SKILL.md and aligning with best practices of @.github/skills/flutter-expert/SKILL.md  

### Reactive Troubleshooting
*"I'm getting a null pointer exception in my authentication code"*
→ Submit your code and the error. Dart Detective analyzes, identifies root cause, and provides fix.

### Proactive Code Review
*"Please review my password manager's credential storage implementation"*
→ Submit code. Get comprehensive security and best-practice review across Dart language, Flutter framework, and Android platform.

### Focused Reviews
- **Security-only**: Password manager security patterns, credential handling, encryption
- **Performance**: Memory optimization, list rendering, network efficiency
- **Bug hunting**: Find logic errors, ignored futures, state inconsistencies
- **Architecture**: State management patterns, dependency injection, scalability

### Automation
Use included scripts for deterministic diagnostics:
- `flutter_diagnostics` - Environment and SDK validation
- `analyze_logs.py` - Error pattern detection from Flutter logs
- `dependency_check` - Dependency analysis and vulnerability scanning
- `detect_silent_bugs.dart` - Static analysis for logic errors

---

## License

Copyright (c) 2026 Focused Hunts

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Support & Questions

- **Issues with a skill?** Open an issue in this repository
- **Feature requests?** We listen, but quality matters more than quantity
- **Questions about installation?** Check the individual skill README

---
