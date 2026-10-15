// Scans lib/ for user-facing copy and writes it to
// assets/i18n/source_phrases.json.
//
// TranslatorService.warmUp can only translate phrases it knows about. Left to
// discover them at runtime it only ever learns the screens you have already
// opened, so a language switch leaves every unvisited page in English until
// its own network round-trip lands — the text visibly changes after the page
// is open. Shipping the full list as an asset means one warm-up covers the
// whole app.
//
// Run after adding or changing UI copy:
//   dart run tool/extract_translation_phrases.dart

import 'dart:convert';
import 'dart:io';

/// Widget/helper arguments that end up rendered through AppText.
const _namedArgCallers = <String, String>{
  'AppText': 'text',
  'TranslatedBuilder': 'text',
  'AppButton': 'text',
  'AppTextFeild': 'text',
  'AppFilterDropDown': 'hint',
  'AppDropDown': 'hint',
  // Fallback copy handed to the error helpers, which services pass inline.
  'friendlyErrorMessage': 'fallback',
  'statusCodeMessage': 'fallback',
};

/// Snack helpers whose message is a positional argument.
const _positionalCallers = <String, int>{
  'showSuccessSnack': 1,
  'showErrorSnack': 1,
  'showInfoSnack': 1,
  'showAppSnack': 1,
  'showStatusSnack': 2,
  // Screen-local wrappers around the helpers above.
  '_showSnack': 0,
  '_showSnackBar': 0,
  '_showErrorSnackBar': 0,
};

final _identifierChar = RegExp(r'[A-Za-z0-9_$]');
final _namedArgStart = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\s*:');
final _hasLetter = RegExp(r'[A-Za-z]');
final _assetExtension = RegExp(r'\.(png|jpe?g|svg|gif|webp|json|ttf|otf)$');

/// `offer_range`, `username`, ... — API keys picked up from `List<String>`
/// declarations. UI copy is capitalised or multi-word, so this is safe, and
/// anything mislabelled is still learned at runtime when it renders.
final _identifierLike = RegExp(r'^[a-z]+(_[a-z0-9]+)*$');

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Run this from the package root.');
    exit(1);
  }

  final phrases = <String>{};
  var fileCount = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    fileCount++;
    final source = _stripComments(entity.readAsStringSync());

    _namedArgCallers.forEach((caller, argName) {
      for (final args in _callArguments(source, caller)) {
        final expr = _namedArgument(args, argName);
        if (expr != null) phrases.addAll(_stringLiterals(expr));
      }
    });

    _positionalCallers.forEach((caller, index) {
      for (final args in _callArguments(source, caller)) {
        final expr = _positionalArgument(args, index);
        if (expr != null) phrases.addAll(_stringLiterals(expr));
      }
    });

    // Copy held in `List<String>` constants (filter options, tab labels,
    // cancel reasons) reaches AppText through a variable, so the call-site
    // scan above cannot see it.
    for (final literal in _stringListLiterals(source)) {
      phrases.addAll(_stringLiterals(literal));
    }

    // error_messages.dart hands its copy back as a return value, so no call
    // site mentions it — including the "no internet" sentence a user is most
    // likely to see. Only `return` statements are harvested: the diagnostic
    // needles matched with `.contains()` are not shown to anyone.
    if (_normalisePath(entity.path).endsWith('utils/error_messages.dart')) {
      phrases.addAll(_returnedStrings(source));
    }
  }

  final sorted = phrases.where(_looksLikeCopy).toList()..sort();

  final outFile = File('assets/i18n/source_phrases.json');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );

  stdout.writeln('Scanned $fileCount files -> ${sorted.length} phrases');
  stdout.writeln('Wrote ${outFile.path}');
}

/// Removes line and block comments so commented-out widgets are not harvested.
String _stripComments(String source) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (c == '/' && i + 1 < source.length) {
      final next = source[i + 1];
      if (next == '/') {
        while (i < source.length && source[i] != '\n') {
          i++;
        }
        continue;
      }
      if (next == '*') {
        i += 2;
        while (i + 1 < source.length &&
            !(source[i] == '*' && source[i + 1] == '/')) {
          i++;
        }
        i += 2;
        continue;
      }
    }
    if (c == "'" || c == '"') {
      final end = _skipString(source, i);
      buffer.write(source.substring(i, end));
      i = end;
      continue;
    }
    buffer.write(c);
    i++;
  }
  return buffer.toString();
}

/// Index just past the string literal starting at [start].
int _skipString(String source, int start) {
  final quote = source[start];
  final tripleQuote = quote * 3;
  final isTriple = source.startsWith(tripleQuote, start);
  var i = start + (isTriple ? 3 : 1);
  while (i < source.length) {
    if (source.codeUnitAt(i) == 0x5C) {
      i += 2;
      continue;
    }
    if (isTriple && source.startsWith(tripleQuote, i)) return i + 3;
    if (!isTriple && source[i] == quote) return i + 1;
    if (!isTriple && source[i] == '\n') return i;
    i++;
  }
  return source.length;
}

/// Every argument list belonging to a `caller(...)` invocation.
Iterable<String> _callArguments(String source, String caller) sync* {
  var from = 0;
  while (true) {
    final at = source.indexOf(caller, from);
    if (at == -1) return;
    from = at + caller.length;

    // Reject partial matches such as `MyAppText` or `AppTextFeild`.
    if (at > 0 && _identifierChar.hasMatch(source[at - 1])) continue;

    var j = from;
    while (j < source.length && (source[j] == ' ' || source[j] == '\n')) {
      j++;
    }
    if (j >= source.length || source[j] != '(') continue;

    final close = _matchingParen(source, j);
    if (close != -1) yield source.substring(j + 1, close);
  }
}

int _matchingParen(String source, int open) {
  var depth = 0;
  var i = open;
  while (i < source.length) {
    final c = source[i];
    if (c == "'" || c == '"') {
      i = _skipString(source, i);
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) return i;
    }
    i++;
  }
  return -1;
}

/// Splits an argument list on top-level commas.
List<String> _splitArguments(String args) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  var i = 0;
  while (i < args.length) {
    final c = args[i];
    if (c == "'" || c == '"') {
      i = _skipString(args, i);
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ',' && depth == 0) {
      parts.add(args.substring(start, i));
      start = i + 1;
    }
    i++;
  }
  parts.add(args.substring(start));
  return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
}

String? _namedArgument(String args, String name) {
  for (final part in _splitArguments(args)) {
    final match = RegExp('^$name' r'\s*:').firstMatch(part);
    if (match != null) return part.substring(match.end).trim();
  }
  return null;
}

String? _positionalArgument(String args, int index) {
  final parts = _splitArguments(
    args,
  ).where((p) => !_namedArgStart.hasMatch(p)).toList();
  return index < parts.length ? parts[index] : null;
}

/// Plain string literals inside an expression, skipping interpolated ones —
/// those carry runtime values and cannot be pre-translated.
Set<String> _stringLiterals(String expression) {
  final found = <String>{};
  var i = 0;
  while (i < expression.length) {
    final c = expression[i];
    if (c != "'" && c != '"') {
      i++;
      continue;
    }

    final end = _skipString(expression, i);
    final raw = expression.substring(i, end);
    i = end;

    final tripleQuote = c * 3;
    final isTriple = raw.length >= 6 && raw.startsWith(tripleQuote);
    final openLength = isTriple ? 3 : 1;
    final closeLength = raw.endsWith(isTriple ? tripleQuote : c)
        ? openLength
        : 0;
    if (raw.length <= openLength + closeLength) continue;

    final body = raw.substring(openLength, raw.length - closeLength);
    if (body.contains(r'$')) continue;

    final value = body
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"')
        .replaceAll(r'\n', ' ')
        .trim();
    if (value.isNotEmpty) found.add(value);
  }
  return found;
}

/// Windows hands back `\`-separated paths; compare on `/`.
String _normalisePath(String path) =>
    path.replaceAll(String.fromCharCode(92), '/');

/// Turns escaped quotes back into the characters the user sees.
String _unescapeQuotes(String value) {
  final backslash = String.fromCharCode(92);
  return value
      .replaceAll('$backslash' "'", "'")
      .replaceAll('$backslash"', '"');
}

/// Strings produced by `return` statements, joining Dart's adjacent-literal
/// concatenation so `'one ' 'two'` is recorded as the single phrase the user
/// actually sees.
Set<String> _returnedStrings(String source) {
  final found = <String>{};
  var from = 0;
  while (true) {
    final at = source.indexOf('return', from);
    if (at == -1) return found;
    from = at + 6;
    if (at > 0 && _identifierChar.hasMatch(source[at - 1])) continue;
    if (from < source.length && _identifierChar.hasMatch(source[from])) continue;

    final end = source.indexOf(';', from);
    if (end == -1) return found;
    final body = source.substring(from, end).trim();
    from = end + 1;

    final joined = _joinAdjacentLiterals(body);
    if (joined != null && joined.isNotEmpty) found.add(joined);
  }
}

/// The concatenation of [expression] when it is nothing but adjacent string
/// literals; null when it is any other expression.
String? _joinAdjacentLiterals(String expression) {
  final buffer = StringBuffer();
  var i = 0;
  var sawLiteral = false;

  while (i < expression.length) {
    final c = expression[i];
    if (c.trim().isEmpty) {
      i++;
      continue;
    }
    if (c != "'" && c != '"') return null;

    final end = _skipString(expression, i);
    final raw = expression.substring(i, end);
    i = end;

    final tripleQuote = c * 3;
    final isTriple = raw.length >= 6 && raw.startsWith(tripleQuote);
    final openLength = isTriple ? 3 : 1;
    final closeLength = raw.endsWith(isTriple ? tripleQuote : c) ? openLength : 0;
    if (raw.length <= openLength + closeLength) return null;

    final part = raw.substring(openLength, raw.length - closeLength);
    if (part.contains(r'$')) return null;
    buffer.write(_unescapeQuotes(part));
    sawLiteral = true;
  }

  return sawLiteral ? buffer.toString().trim() : null;
}

/// Bodies of `List<String>` / `<String>[...]` literals.
Iterable<String> _stringListLiterals(String source) sync* {
  const marker = 'List<String>';
  var from = 0;
  while (true) {
    final at = source.indexOf(marker, from);
    if (at == -1) break;
    from = at + marker.length;
    final open = _listLiteralStart(source, from);
    if (open == -1) continue;
    final close = _matchingParen(source, open);
    if (close != -1) yield source.substring(open + 1, close);
  }

  const inlineMarker = '<String>[';
  from = 0;
  while (true) {
    final at = source.indexOf(inlineMarker, from);
    if (at == -1) return;
    final open = at + inlineMarker.length - 1;
    from = at + inlineMarker.length;
    final close = _matchingParen(source, open);
    if (close != -1) yield source.substring(open + 1, close);
  }
}

/// The `[` opening a list literal assigned right after [from], or -1 when the
/// declaration has no initialiser (a bare field) or is a function signature.
int _listLiteralStart(String source, int from) {
  var i = from;
  while (i < source.length) {
    final c = source[i];
    if (c == '[') return i;
    if (c == ';' || c == '{' || c == '}' || c == '(') return -1;
    i++;
  }
  return -1;
}

/// Filters out identifiers, asset paths and other non-copy strings.
bool _looksLikeCopy(String value) {
  if (value.length < 2) return false;
  if (!_hasLetter.hasMatch(value)) return false;
  if (value.startsWith('assets/')) return false;
  if (value.startsWith('http://') || value.startsWith('https://')) return false;
  if (value.startsWith('/')) return false;
  if (_assetExtension.hasMatch(value)) return false;
  if (_identifierLike.hasMatch(value)) return false;
  return true;
}
