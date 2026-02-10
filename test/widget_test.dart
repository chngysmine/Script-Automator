import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/core/data_structures/rope.dart';
import 'package:script_automator/features/editor/presentation/widgets/console_log_widget.dart';

void main() {
  group('Rope Data Structure (Immutable)', () {
    test('should initialize with empty content', () {
      final rope = Rope.fromString('');
      expect(rope.length, 0);
      expect(rope.toString(), '');
    });

    test('should initialize with initial content', () {
      final rope = Rope.fromString('Hello World');
      expect(rope.length, 11);
      expect(rope.toString(), 'Hello World');
    });

    test('should insert text at beginning', () {
      var rope = Rope.fromString('World');
      rope = rope.insert(0, 'Hello ');
      expect(rope.toString(), 'Hello World');
    });

    test('should insert text at end', () {
      var rope = Rope.fromString('Hello');
      rope = rope.insert(5, ' World');
      expect(rope.toString(), 'Hello World');
    });

    test('should insert text in middle', () {
      var rope = Rope.fromString('Helo World');
      rope = rope.insert(3, 'l');
      expect(rope.toString(), 'Hello World');
    });

    test('should delete text', () {
      var rope = Rope.fromString('Hello World');
      rope = rope.delete(5, 6);
      expect(rope.toString(), 'HelloWorld');
    });

    test('should replace text (delete + insert)', () {
      var rope = Rope.fromString('Hello World');
      rope = rope.delete(6, 11);
      rope = rope.insert(6, 'Flutter');
      expect(rope.toString(), 'Hello Flutter');
    });

    test('should get substring', () {
      final rope = Rope.fromString('Hello World');
      expect(rope.substring(0, 5), 'Hello');
      expect(rope.substring(6, 11), 'World');
    });

    test('should throw on invalid index', () {
      final rope = Rope.fromString('Hello');
      expect(() => rope.insert(-1, 'X'), throwsA(isA<RangeError>()));
      expect(() => rope.insert(10, 'X'), throwsA(isA<RangeError>()));
    });

    test('should handle large text', () {
      var rope = Rope.fromString('');
      final largeText = 'A' * 1000;
      rope = rope.insert(0, largeText);
      expect(rope.length, 1000);

      rope = rope.insert(500, 'B');
      expect(rope.length, 1001);
      expect(rope.substring(499, 502), 'ABA');
    });
  });

  group('ConsoleLogEntry', () {
    test('should parse INFO log', () {
      final entry = ConsoleLogEntry.fromRawLog('[INFO] Server started');
      expect(entry.level, LogLevel.info);
      expect(entry.message, 'Server started');
    });

    test('should parse ERROR log', () {
      final entry = ConsoleLogEntry.fromRawLog('[ERROR] Connection failed');
      expect(entry.level, LogLevel.error);
      expect(entry.message, 'Connection failed');
    });

    test('should parse SUCCESS log', () {
      final entry = ConsoleLogEntry.fromRawLog('[SUCCESS] Success!');
      expect(entry.level, LogLevel.success);
      expect(entry.message, 'Success!');
    });

    test('should detect error keyword', () {
      final entry = ConsoleLogEntry.fromRawLog('critical error occurred');
      expect(entry.level, LogLevel.error);
    });

    test('should detect success symbol', () {
      final entry = ConsoleLogEntry.fromRawLog('Task done ✓');
      expect(entry.level, LogLevel.success);
    });

    test('should include timestamp', () {
      final entry = ConsoleLogEntry(message: 'Test');
      expect(entry.timestamp, isNotNull);
    });
  });
}
