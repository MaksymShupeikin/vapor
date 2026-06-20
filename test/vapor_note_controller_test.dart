import 'package:flutter_test/flutter_test.dart';
import 'package:vapor/features/vapor_note/application/vapor_note_controller.dart';

void main() {
  group('VaporNoteController', () {
    test('commits words on spaces and compiles the sentence on completion', () {
      final controller = VaporNoteController();

      expect(controller.handleTextInput('quiet').action, VaporInputAction.none);
      expect(controller.currentWord, 'quiet');
      expect(controller.words, isEmpty);

      final commitResult = controller.handleTextInput('quiet ');
      expect(commitResult.action, VaporInputAction.wordCommitted);
      expect(commitResult.replacementText, '');
      expect(controller.currentWord, isEmpty);
      expect(controller.words, ['quiet']);

      controller.handleTextInput('signal');
      expect(controller.completeSentence(), isTrue);
      expect(controller.compiledSentence, 'quiet signal');
    });

    test(
      'keeps the trailing pasted word editable after committing prior words',
      () {
        final controller = VaporNoteController();

        final result = controller.handleTextInput('one two three');

        expect(result.action, VaporInputAction.wordCommitted);
        expect(result.replacementText, 'three');
        expect(controller.words, ['one', 'two']);
        expect(controller.currentWord, 'three');
      },
    );

    test('resets the hidden buffer and compiled sentence', () {
      final controller = VaporNoteController();

      controller.handleTextInput('private ');
      controller.handleTextInput('note');
      controller.completeSentence();
      controller.reset();

      expect(controller.words, isEmpty);
      expect(controller.currentWord, isEmpty);
      expect(controller.compiledSentence, isEmpty);
      expect(controller.hasCompiledSentence, isFalse);
    });

    test('restores the previously committed word for editing', () {
      final controller = VaporNoteController();

      controller.handleTextInput('quiet ');
      controller.handleTextInput('signal ');

      expect(controller.restorePreviousWord(), 'signal');
      expect(controller.words, ['quiet']);
      expect(controller.currentWord, 'signal');
    });

    test('loads a compiled sentence from history', () {
      final controller = VaporNoteController();

      controller.loadCompiledSentence('saved sentence');

      expect(controller.compiledSentence, 'saved sentence');
      expect(controller.hasCompiledSentence, isTrue);
      expect(controller.words, isEmpty);
      expect(controller.currentWord, isEmpty);
    });
  });
}
