import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_automator/features/editor/domain/code_forge_controller.dart';

void main() {
  group('CodeForgeController Tests', () {
    late CodeForgeController controller;

    setUp(() {
      controller = CodeForgeController(text: "Hello");
    });

    test('Initial State', () {
      expect(controller.text, "Hello");
      expect(controller.selection.baseOffset, 0);
      expect(controller.value.text, "Hello");
    });

    test('Insert Text at Start', () {
      controller.insert("Hi ");
      expect(controller.text, "Hi Hello");
      expect(controller.selection.baseOffset, 3);
    });

    test('Insert Text in Middle', () {
      controller.selection = const TextSelection.collapsed(
        offset: 5,
      ); // After "Hello"
      controller.insert(" World");
      expect(controller.text, "Hello World");
      expect(controller.selection.baseOffset, 11);
    });

    test('Backspace Delete', () {
      controller.selection = const TextSelection.collapsed(offset: 5);
      controller.delete(); // Delete 'o'
      expect(controller.text, "Hell");
      expect(controller.selection.baseOffset, 4);
    });

    test('Delete Selection', () {
      // "Hello", Select "ell" (1-4)
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      controller.delete();
      expect(controller.text, "Ho"); // H + o
      expect(controller.selection.baseOffset, 1);
    });

    test('Overtype Selection', () {
      // "Hello", Select "ell" (1-4), Type "ipp"
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      controller.insert("ipp");
      expect(controller.text, "Hippo");
      expect(controller.selection.baseOffset, 4);
    });

    test('Set Text', () {
      controller.setText("New World");
      expect(controller.text, "New World");
      expect(controller.selection.baseOffset, 0);
    });
  });
}
