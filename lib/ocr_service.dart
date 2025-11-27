import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_test_with_ml/weight_item_model.dart';

class OcrService {
  final TextRecognizer recognizer = TextRecognizer();

  Future<RecognizedText> processImage(InputImage image) async {
    return await recognizer.processImage(image);
  }

  /// Attempt to parse each line robustly. Handles split tokens like "110 7.0 lb".
  List<WeightItem> parseWeightsFromRecognizedText(RecognizedText rt) {
    final List<WeightItem> list = [];

    // Regex to quickly match a well-formed line: "1. 110.7 lb"
    final rowRegex =
        RegExp(r'^\s*(\d+)\.?\s+(-?\d+(\.\d+)?|\d+)\s*(lb|kg|ton)\b', caseSensitive: false);

    for (final block in rt.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        // Quick attempt using the full line string
        final m = rowRegex.firstMatch(lineText);
        if (m != null) {
          final no = int.tryParse(m.group(1)!) ?? 0;
          final weight = double.tryParse(m.group(2)!) ?? 0.0;
          final unit = m.group(4)!.toLowerCase();
          list.add(WeightItem(no: no, weight: weight, unit: unit));
          // debug
          // print('[debug] matched direct: $no -> $weight $unit');
          continue;
        }

        // If simple regex didn't match, try element-level parsing:
        final items = _parseLineElements(line);
        if (items != null) {
          list.add(items);
        }
      }
    }

    // Sort by no just in case
    list.sort((a, b) => a.no.compareTo(b.no));
    return list;
  }

  /// Parse totals like "T: 1661.6 lb" or "TOTAL 1661.6 lb" possibly split
  Map<String, dynamic>? parseTotalFromRecognizedText(RecognizedText rt) {
    final totalRegex = RegExp(r'(?:T[:\s]|TOTAL[:\s])\s*([-\d\.]+)\s*(lb|kg|ton)\b',
        caseSensitive: false);

    for (final block in rt.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final m = totalRegex.firstMatch(text);
        if (m != null) {
          return {
            'total': double.tryParse(m.group(1)!) ?? 0.0,
            'unit': m.group(2)!.toLowerCase(),
          };
        }
      }
    }

    // If not found above, try element-level scanning to recover split tokens:
    for (final block in rt.blocks) {
      for (final line in block.lines) {
        final merged = _attemptParseTotalFromElements(line);
        if (merged != null) return merged;
      }
    }

    return null;
  }

  /// Parse using line.elements - robust merging of numeric parts
  WeightItem? _parseLineElements(TextLine line) {
    final tokens = line.elements.map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    // find token that looks like "1." or digit then a dot or standalone index
    int? indexPos;
    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (RegExp(r'^\d+\.$').hasMatch(t) || RegExp(r'^\d+$').hasMatch(t)) {
        // check if token is position-like and likely at start
        // also ensure next tokens contain numeric weight and unit
        indexPos = i;
        break;
      }
    }

    if (indexPos == null) return null;

    // Find unit token position (lb/kg/ton)
    int? unitPos;
    for (int i = indexPos + 1; i < tokens.length; i++) {
      final t = tokens[i].toLowerCase();
      if (t.contains('lb') || t.contains('kg') || t.contains('ton')) {
        unitPos = i;
        break;
      }
    }

    if (unitPos == null) return null;

    // Compose index
    final idxToken = tokens[indexPos];
    final no = int.tryParse(idxToken.replaceAll('.', '')) ?? 0;

    // Tokens between indexPos and unitPos are parts of weight (may be split)
    final weightParts = tokens.sublist(indexPos + 1, unitPos);
    final mergedWeight = _mergeWeightParts(weightParts);
    final unit = tokens[unitPos].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    if (mergedWeight == null) return null;

    return WeightItem(no: no, weight: mergedWeight, unit: unit);
  }

  /// If element-level parse fails, attempt to reconstruct from the line text using heuristics
  WeightItem? parseLineWithHeuristics(String lineText) {
    // remove commas
    final s = lineText.replaceAll(',', ' ');
    // try to find index dot pattern
    final rx = RegExp(r'(\d+)\.?\s+([-\d\s\.]+)\s*(lb|kg|ton)', caseSensitive: false);
    final m = rx.firstMatch(s);
    if (m == null) return null;

    final no = int.tryParse(m.group(1)!) ?? 0;
    final weightRaw = m.group(2)!.trim();
    final unit = m.group(3)!.toLowerCase();

    // split on spaces and merge numeric parts
    final parts = weightRaw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final merged = _mergeWeightParts(parts);
    if (merged == null) return null;
    return WeightItem(no: no, weight: merged, unit: unit);
  }

  /// Try to parse Total from elements when the total line is split into tokens
  Map<String, dynamic>? _attemptParseTotalFromElements(TextLine line) {
    final tokens = line.elements.map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    // Find spot that has T or TOTAL
    int? tPos;
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].toUpperCase().startsWith('T') || tokens[i].toUpperCase().startsWith('TOTAL')) {
        tPos = i;
        break;
      }
    }

    if (tPos == null) return null;

    // Find unit token after tPos
    int? unitPos;
    for (int i = tPos + 1; i < tokens.length; i++) {
      final t = tokens[i].toLowerCase();
      if (t.contains('lb') || t.contains('kg') || t.contains('ton')) {
        unitPos = i;
        break;
      }
    }

    if (unitPos == null) return null;

    final weightParts = tokens.sublist(tPos + 1, unitPos);
    final mergedWeight = _mergeWeightParts(weightParts);
    if (mergedWeight == null) return null;

    final unit = tokens[unitPos].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return {'total': mergedWeight, 'unit': unit};
  }

  /// Merge tokens that represent a split weight.
  /// Examples:
  ///  - ["110", "7.0"]  -> 110.7
  ///  - ["1661", "6.0"] -> 1661.6
  ///  - ["110.7"]       -> 110.7
  ///  - ["110","6"]     -> 110.6
  double? _mergeWeightParts(List<String> parts) {
    if (parts.isEmpty) return null;

    // Clean parts: remove non-numeric except dot and minus
    final cleaned = parts.map((p) => p.replaceAll(RegExp(r'[^0-9\.\-]'), '')).where((s) => s.isNotEmpty).toList();
    if (cleaned.isEmpty) return null;

    // If single part and parseable -> done
    if (cleaned.length == 1) {
      final val = double.tryParse(cleaned[0]);
      return val;
    }

    // If first has a decimal already, try concatenating trimmed parts
    if (cleaned[0].contains('.')) {
      // e.g. ["110.","7.0"] -> try to take fractional from next
      final first = cleaned[0];
      final second = cleaned[1];
      final frac = second.split('.').first; // take integer part of second as fractional
      final merged = '$first$frac';
      final v = double.tryParse(merged);
      if (v != null) return v;
    }

    // General heuristic:
    // If first looks like integer (no dot) and second looks like number with optional .0
    // combine as first + '.' + digits of second before decimal (or whole second if short)
    final first = cleaned[0];
    final second = cleaned[1];

    final firstIsInt = !first.contains('.');
    final secondIsNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(second);

    if (firstIsInt && secondIsNumeric) {
      // get fractional digits from second (part before decimal or first digit)
      String frac;
      if (second.contains('.')) {
        frac = second.split('.').first;
      } else {
        // if second length >=2 take all, else take as is
        frac = (second.length <= 3) ? second : second.substring(0, 2);
      }

      // keep only first 3 digits of integer portion to avoid huge decimals; but we want full integer as-is
      final mergedStr = '$first.$frac';
      final v = double.tryParse(mergedStr);
      if (v != null) return v;
    }

    // Fallback: join all digits and attempt to parse as decimal by inserting a dot before last digit group
    final joined = cleaned.join();
    if (joined.length >= 2) {
      // try to put a dot before last 1-3 digits and see if plausible
      for (int fracLen = 1; fracLen <= 3; fracLen++) {
        if (joined.length > fracLen) {
          final cand = '${joined.substring(0, joined.length - fracLen)}.${joined.substring(joined.length - fracLen)}';
          final v = double.tryParse(cand);
          if (v != null) return v;
        }
      }
    }

    // As last resort try to parse first only
    return double.tryParse(cleaned[0]);
  }
}
