import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/data_structures/rope.dart';

void main() {
  group('Rope Data Structure Tests', () {
    test('Initialization from String', () {
      final rope = Rope.fromString("Hello World");
      expect(rope.toString(), "Hello World");
      expect(rope.length, 11);
    });

    test('Indexing', () {
      final rope = Rope.fromString("0123456789");
      expect(rope[0], '0');
      expect(rope[9], '9');
      expect(rope[5], '5');
      expect(() => rope[10], throwsRangeError);
    });

    test('Insertion (Leaf Split)', () {
      final rope = Rope.fromString("Hello!");
      final newRope = rope.insert(5, " World");
      expect(newRope.toString(), "Hello World!");
      expect(newRope.length, 12);
    });

    test('Insertion (Deep Tree)', () {
      // Force tree structure
      var rope = Rope.fromString("A");
      final iterations = 100;
      for (int i = 0; i < iterations; i++) {
        rope = rope + Rope.fromString("B");
      }
      expect(rope.length, iterations + 1);
      final inserted = rope.insert(50, "XYZ");
      expect(inserted.toString().contains("BXYZB"), isTrue);
      expect(inserted.length, iterations + 4);
    });

    test('Deletion (Simple)', () {
      final rope = Rope.fromString("Hello World!");
      final deleted = rope.delete(5, 11); // Delete " World"
      expect(deleted.toString(), "Hello!");
    });

    test('Deletion (Spanning Nodes)', () {
      final root =
          Rope.fromString("Left") + Rope.fromString("Right"); // Length 8
      // "LeftRight"
      // Delete "ftRi" (Indices 2 to 6)
      final deleted = root.delete(2, 6);
      expect(deleted.toString(), "Leght");
    });

    test('Large Scale Performance Mock', () {
      // Construct a moderately large rope
      Rope rope = Rope.fromString("Start");
      for (int i = 0; i < 1000; i++) {
        rope = rope + Rope.fromString(".$i");
      }
      // Should handle thousands of nodes without recursion stack overflow (if reasonably balanced)
      // Note: Our naive implementation isn't balanced, so depth might be high (1000).
      // Dart stack can handle ~1000-2000 deep recursion locally usually.
      // Just verifying correctness of output logic.
      final str = rope.toString();
      expect(str.startsWith("Start.0.1"), isTrue);
      expect(str.length > 3000, isTrue);

      final edit = rope.insert(100, "INSERTED");
      expect(edit.toString().substring(100, 108), "INSERTED");
    });

    test('Substring', () {
      final rope = Rope.fromString("Hello World");
      expect(rope.substring(0, 5), "Hello");
      expect(rope.substring(6, 11), "World");
      expect(rope.substring(0, 11), "Hello World");
      expect(() => rope.substring(-1, 5), throwsRangeError);
    });
  });
}
