import 'dart:math' as math;

enum MathResultsMode {
  off,
  suggest,
  insert,
}

class MathNotesEngine {
  MathResultsMode mode;
  final Map<String, double> _variables = {};

  MathNotesEngine({this.mode = MathResultsMode.suggest});

  /// Evaluates an input line ending with '=' or containing an expression.
  /// Returns evaluated result as formatted string, or null if line is not a valid expression.
  String? evaluateLine(String line) {
    if (mode == MathResultsMode.off) return null;

    final trimmed = line.trim();
    if (!trimmed.endsWith('=')) return null;

    final expression = trimmed.substring(0, trimmed.length - 1).trim();
    if (expression.isEmpty) return null;

    try {
      // 1. Variable Assignment (e.g. tax = 18%, price = 50)
      if (expression.contains('=') && !expression.endsWith('=')) {
        final assignParts = expression.split('=');
        final varName = assignParts[0].trim();
        final varValExpr = assignParts[1].trim();
        final val = _computeSimple(varValExpr);
        if (val != null) {
          _variables[varName] = val;
          return _formatResult(val);
        }
      }

      // 2. Variable Replacement
      String resolved = expression;
      for (final entry in _variables.entries) {
        resolved = resolved.replaceAll(RegExp(r'\b' + entry.key + r'\b'), entry.value.toString());
      }

      // 3. Compute Expression
      final result = _computeSimple(resolved);
      if (result != null) {
        return _formatResult(result);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Calculates sum of numeric items in a list above 'Total ='
  double? calculateListTotal(List<String> listLines) {
    double total = 0.0;
    bool foundAny = false;
    for (final line in listLines) {
      final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+').allMatches(line);
      for (final m in match) {
        final val = double.tryParse(m.group(0) ?? '');
        if (val != null) {
          total += val;
          foundAny = true;
        }
      }
    }
    return foundAny ? total : null;
  }

  double? _computeSimple(String expr) {
    String sanitized = expr.replaceAll(' ', '');

    // Handle percentage (e.g. 1500 - 20% or 500 + 10%)
    final percentPattern = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-])\s*(\d+(?:\.\d+)?)%');
    final pMatch = percentPattern.firstMatch(sanitized);
    if (pMatch != null) {
      final base = double.tryParse(pMatch.group(1)!);
      final op = pMatch.group(2)!;
      final pct = double.tryParse(pMatch.group(3)!);
      if (base != null && pct != null) {
        final delta = base * (pct / 100.0);
        return op == '+' ? base + delta : base - delta;
      }
    }

    // Handle sqrt
    if (sanitized.startsWith('sqrt(') && sanitized.endsWith(')')) {
      final inner = sanitized.substring(5, sanitized.length - 1);
      final val = double.tryParse(inner);
      return val != null && val >= 0 ? math.sqrt(val) : null;
    }

    // Basic arithmetic (+, -, *, /)
    final tokens = _tokenize(sanitized);
    if (tokens.isEmpty) return null;
    return _parseAddSub(tokens);
  }

  List<String> _tokenize(String s) {
    final list = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      if ('+-*/()^'.contains(char)) {
        if (buffer.isNotEmpty) {
          list.add(buffer.toString());
          buffer.clear();
        }
        list.add(char);
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) list.add(buffer.toString());
    return list;
  }

  double? _parseAddSub(List<String> tokens) {
    double? left = _parseMulDiv(tokens);
    while (tokens.isNotEmpty && (tokens.first == '+' || tokens.first == '-')) {
      final op = tokens.removeAt(0);
      final right = _parseMulDiv(tokens);
      if (left == null || right == null) return null;
      left = op == '+' ? left + right : left - right;
    }
    return left;
  }

  double? _parseMulDiv(List<String> tokens) {
    double? left = _parsePrimary(tokens);
    while (tokens.isNotEmpty && (tokens.first == '*' || tokens.first == '/')) {
      final op = tokens.removeAt(0);
      final right = _parsePrimary(tokens);
      if (left == null || right == null) return null;
      if (op == '/' && right == 0) return null;
      left = op == '*' ? left * right : left / right;
    }
    return left;
  }

  double? _parsePrimary(List<String> tokens) {
    if (tokens.isEmpty) return null;
    final token = tokens.removeAt(0);
    if (token == '(') {
      final val = _parseAddSub(tokens);
      if (tokens.isNotEmpty && tokens.first == ')') tokens.removeAt(0);
      return val;
    }
    if (token == 'pi') return math.pi;
    if (token == 'e') return math.e;
    return double.tryParse(token);
  }

  String _formatResult(double val) {
    if (val == val.roundToDouble() && !val.isInfinite) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

