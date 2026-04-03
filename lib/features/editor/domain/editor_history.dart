/// Circular buffer-based undo/redo history for the code editor.
/// Stores text snapshots with cursor position.
/// Max 50 entries to cap memory (~2.5MB worst case for 50KB scripts).
class EditorHistory {
  static const int _maxEntries = 50;

  final List<EditorSnapshot> _undoStack = [];
  final List<EditorSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.length > 1; // >1 because current state is top
  bool get canRedo => _redoStack.isNotEmpty;

  /// Records the current state. Call on every debounced text change.
  void record(String text, int cursorPosition) {
    // Dedup: Don't record if identical to top
    if (_undoStack.isNotEmpty && _undoStack.last.text == text) return;

    _undoStack.add(EditorSnapshot(text: text, cursorPosition: cursorPosition));
    _redoStack.clear(); // New edit invalidates redo

    // Cap stack size
    if (_undoStack.length > _maxEntries) {
      _undoStack.removeAt(0);
    }
  }

  /// Returns the previous state, or null if at bottom.
  EditorSnapshot? undo() {
    if (!canUndo) return null;
    _redoStack.add(_undoStack.removeLast());
    return _undoStack.last;
  }

  /// Returns the next state, or null if at top.
  EditorSnapshot? redo() {
    if (!canRedo) return null;
    final snapshot = _redoStack.removeLast();
    _undoStack.add(snapshot);
    return snapshot;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

class EditorSnapshot {
  final String text;
  final int cursorPosition;

  const EditorSnapshot({required this.text, required this.cursorPosition});
}
