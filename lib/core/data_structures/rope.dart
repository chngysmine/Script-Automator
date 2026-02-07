import 'dart:math';

/// A heavy-weight internal node threshold to trigger rebalancing (optional optimization)
const int _rebalanceThreshold = 256;

/// Abstract base class for the Rope data structure.
/// Rope is a binary tree structure for storing strings, enabling O(log N) insertion and deletion.
abstract class Rope {
  int get length;
  int get depth;

  /// Extract a substring from the rope.
  String substring(int start, int end);

  /// Returns the character at [index].
  String operator [](int index);

  /// Inserts [text] at [index], returning a new Rope.
  Rope insert(int index, String text);

  /// Deletes the range [start] to [end], returning a new Rope.
  Rope delete(int start, int end);

  /// Concatenates this rope with [other].
  Rope operator +(Rope other);

  @override
  String toString();

  /// Factory to create a Rope from a String.
  factory Rope.fromString(String text) {
    if (text.isEmpty) return _RopeLeaf("");
    return _RopeLeaf(text);
  }
}

/// A Leaf node containing a raw string.
class _RopeLeaf implements Rope {
  final String _value;
  @override
  final int length;

  _RopeLeaf(this._value) : length = _value.length;

  @override
  int get depth => 0;

  @override
  String operator [](int index) {
    if (index < 0 || index >= length) throw RangeError.index(index, this);
    return _value[index];
  }

  @override
  Rope insert(int index, String text) {
    if (text.isEmpty) return this;
    if (index == 0) return _RopeLeaf(text) + this;
    if (index == length) return this + _RopeLeaf(text);

    // Split leaf and insert: Left + New + Right
    final left = _value.substring(0, index);
    final right = _value.substring(index);
    return _RopeConcat(
      _RopeConcat(_RopeLeaf(left), _RopeLeaf(text)),
      _RopeLeaf(right),
    );
  }

  @override
  String substring(int start, int end) {
    if (start < 0 || end > length || start > end) {
      throw RangeError("Invalid range: $start-$end");
    }
    return _value.substring(start, end);
  }

  @override
  Rope delete(int start, int end) {
    if (start < 0 || end > length || start > end) {
      throw RangeError("Invalid range: $start-$end");
    }
    if (start == 0 && end == length) return _RopeLeaf("");

    final newText = _value.substring(0, start) + _value.substring(end);
    return _RopeLeaf(newText);
  }

  @override
  Rope operator +(Rope other) {
    if (other is _RopeLeaf && length + other.length < _rebalanceThreshold) {
      // Merge small leaves to save memory/depth
      return _RopeLeaf(_value + other._value);
    }
    return _RopeConcat(this, other);
  }

  @override
  String toString() => _value;
}

/// An Internal node representing the concatenation of left and right children.
class _RopeConcat implements Rope {
  final Rope left;
  final Rope right;
  @override
  final int length;
  @override
  final int depth;

  _RopeConcat(this.left, this.right)
    : length = left.length + right.length,
      depth = max(left.depth, right.depth) + 1;

  @override
  String operator [](int index) {
    if (index < left.length) {
      return left[index];
    } else {
      return right[index - left.length];
    }
  }

  @override
  String substring(int start, int end) {
    if (start < 0 || end > length || start > end) {
      throw RangeError("Invalid range: $start-$end");
    }
    if (start == end) return "";

    // 1. Fully in left
    if (end <= left.length) {
      return left.substring(start, end);
    }
    // 2. Fully in right
    if (start >= left.length) {
      return right.substring(start - left.length, end - left.length);
    }
    // 3. Spanning both
    return left.substring(start, left.length) +
        right.substring(0, end - left.length);
  }

  @override
  Rope insert(int index, String text) {
    if (index < left.length) {
      // Insert in left child
      return _RopeConcat(left.insert(index, text), right);
    } else if (index > left.length) {
      // Insert in right child
      return _RopeConcat(left, right.insert(index - left.length, text));
    } else {
      // Insert exactly at boundary: could go either way.
      // Balance heuristic: put shorter side? Or simplify: append to left.
      // Let's insert at the start of right for consistency with logic.
      return _RopeConcat(left, right.insert(0, text));
    }
    // Note: Rebalancing logic would go here in a production immutable rope (AVL/RedBalance).
    // For this MVP, we verify structural correctness first.
  }

  @override
  Rope delete(int start, int end) {
    if (start < 0 || end > length || start > end) {
      throw RangeError("Invalid range");
    }

    // 1. Delete fully in left
    if (end <= left.length) {
      final newLeft = left.delete(start, end);
      return (newLeft.length == 0) ? right : _RopeConcat(newLeft, right);
    }

    // 2. Delete fully in right
    if (start >= left.length) {
      final newRight = right.delete(start - left.length, end - left.length);
      return (newRight.length == 0) ? left : _RopeConcat(left, newRight);
    }

    // 3. Delete spans across both
    final newLeft = left.delete(start, left.length);
    final newRight = right.delete(0, end - left.length);

    if (newLeft.length == 0) return newRight;
    if (newRight.length == 0) return newLeft;

    return _RopeConcat(newLeft, newRight);
  }

  @override
  Rope operator +(Rope other) {
    // Simple concatenation
    return _RopeConcat(this, other);
  }

  @override
  String toString() {
    // Inefficient for very large ropes, but OK for debugging/testing/export.
    // Ideally use a StringBuffer iterator.
    StringBuffer buffer = StringBuffer();
    _buildString(this, buffer);
    return buffer.toString();
  }

  void _buildString(Rope node, StringBuffer buffer) {
    if (node is _RopeLeaf) {
      buffer.write(node._value);
    } else if (node is _RopeConcat) {
      _buildString(node.left, buffer);
      _buildString(node.right, buffer);
    }
  }
}
