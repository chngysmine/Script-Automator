import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/data_structures/rope.dart';

/// Controller for the CodeForge Editor.
/// Manages the [Rope] data structure and the current [TextSelection].
/// Acts as a replacement for [TextEditingController] but optimized for large files.
class CodeForgeController extends ChangeNotifier
    implements ValueListenable<TextEditingValue> {
  Rope _rope;
  TextSelection _selection;

  /// Creates a controller with initial text.
  CodeForgeController({String text = ''})
    : _rope = Rope.fromString(text),
      _selection = const TextSelection.collapsed(offset: 0) {
    _recalculateLineStarts();
  }

  // --- Getters ---

  /// Total length of the text.
  int get length => _rope.length;

  /// The current text as a String.
  /// WARNING: Accessing this on very large files (>10MB) might cause jank on main thread.
  /// For rendering, use [getLine] or [getTextInRange].
  String get text => _rope.toString();

  /// The current cursor selection.
  TextSelection get selection => _selection;

  @override
  TextEditingValue get value => TextEditingValue(
    text: text, // This is expensive, but required for interface.
    selection: selection,
    composing: TextRange.empty,
  );

  // --- Ghost Text (AI Suggestions) ---
  String? _ghostText;
  String? get ghostText => _ghostText;

  void setGhostText(String? value) {
    if (_ghostText != value) {
      _ghostText = value;
      notifyListeners();
    }
  }

  void applyGhostText() {
    if (_ghostText != null && _ghostText!.isNotEmpty) {
      insert(_ghostText!);
      _ghostText = null;
    }
  }

  // --- Core Operations ---

  /// Sets the selection (cursor position).
  set selection(TextSelection newSelection) {
    if (_selection != newSelection) {
      // Validate bounds
      final validStart = newSelection.baseOffset.clamp(0, length);
      final validEnd = newSelection.extentOffset.clamp(0, length);
      _selection = newSelection.copyWith(
        baseOffset: validStart,
        extentOffset: validEnd,
      );
      notifyListeners();
    }
  }

  /// Inserts text at the current cursor position.
  /// If there is a selection, it overwrites it.
  void insert(String textToInsert) {
    if (textToInsert.isEmpty) return;

    if (!_selection.isCollapsed) {
      // Delete selected text first
      _deleteSelection();
    }

    final index = _selection.baseOffset;
    _rope = _rope.insert(index, textToInsert);

    // Move cursor to end of inserted text
    final newOffset = index + textToInsert.length;
    _selection = TextSelection.collapsed(offset: newOffset);

    notifyListeners();
  }

  /// Deletes text.
  /// If selection is non-empty, deletes selection.
  /// If collapsed, deletes [count] characters backwards (backspace).
  void delete({int count = 1}) {
    if (!_selection.isCollapsed) {
      _deleteSelection();
      return;
    }

    final index = _selection.baseOffset;
    if (index == 0) return; // Nothing to delete

    final start = (index - count).clamp(0, index);
    _rope = _rope.delete(start, index);

    // Cursor moves back
    _selection = TextSelection.collapsed(offset: start);

    notifyListeners();
  }

  /// Internal helper to delete current selection.
  void _deleteSelection() {
    final start = _selection.start;
    final end = _selection.end;
    _rope = _rope.delete(start, end);
    _selection = TextSelection.collapsed(offset: start);
  }

  // --- Line Management ---
  List<int> _lineStarts = [0];

  /// Returns the number of lines.
  int get lineCount => _lineStarts.length;

  /// Efficiently retrieves text for a specific line index (0-based).
  String getLine(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= lineCount) return "";

    final start = _lineStarts[lineIndex];
    // final end = (lineIndex == lineCount - 1) ? length : _lineStarts[lineIndex + 1] - 1;
    // Unused variable removed.
    // -1 to exclude newline, or keeping it? Code editors usually keeping it or handling it implicitly.
    // Let's include the newline in the line text so TextPainter handles it,
    // BUT we usually strip it for drawing width calculations if we want to draw line number background?
    // Standard approach: return content including \n (if distinct line).

    // Wait, simple calculation: substring from start to next start.
    final nextStart = (lineIndex == lineCount - 1)
        ? length
        : _lineStarts[lineIndex + 1];

    // Safety check
    if (start >= length) return "";

    // Optimized with Rope.substring
    return _rope.substring(start, nextStart);
  }

  /// Recalculates line start indices.
  /// Should be called after every edit.
  /// Optimization: Only rescan from modified point.
  void _recalculateLineStarts() {
    _lineStarts = [0];
    // We have to iterate the rope to find newlines.
    // Accessing by index is O(N log N).
    // Faster: Recursive traversal of Rope nodes?
    // For MVP Sprint 4.1, simple iteration is acceptable.
    for (int i = 0; i < length; i++) {
      if (_rope[i] == '\n') {
        _lineStarts.add(i + 1);
      }
    }
  }

  /// Returns the (lineIndex, columnIndex) for a given character offset.
  /// Uses binary search on _lineStarts for efficiency O(log L).
  (int line, int col) getLineAndCol(int offset) {
    if (offset < 0) return (0, 0);
    if (offset >= length) {
      if (lineCount == 0) return (0, 0);
      // Return end of last line
      final lastLineStart = _lineStarts.last;
      return (lineCount - 1, length - lastLineStart);
    }

    // Binary search for line index
    int low = 0;
    int high = lineCount - 1;
    int foundLine = 0;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (_lineStarts[mid] <= offset) {
        foundLine = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return (foundLine, offset - _lineStarts[foundLine]);
  }

  /// Replaces the entire text content (e.g. file load).
  void setText(String newText) {
    _rope = Rope.fromString(newText);
    _selection = const TextSelection.collapsed(offset: 0);
    notifyListeners();
  }

  // Dispose handled by super
}
