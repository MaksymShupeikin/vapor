import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vapor/features/vapor_note/application/vapor_notes_history.dart';

void main() {
  group('VaporNotesHistory', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('saves notes in most-recent-first order', () {
      final history = VaporNotesHistory();

      history.save('first');
      history.save('second');

      expect(history.notes.map((note) => note.text), ['second', 'first']);
    });

    test('deduplicates saved note text and moves it to the top', () {
      final history = VaporNotesHistory();

      history.save('first');
      history.save('second');
      history.save('first');

      expect(history.notes.length, 2);
      expect(history.notes.first.text, 'first');
    });

    test('deletes a saved note by id', () {
      final history = VaporNotesHistory();
      final note = history.save('temporary');

      history.delete(note!.id);

      expect(history.notes, isEmpty);
    });

    test('persists notes and loads them into a new history', () async {
      final history = VaporNotesHistory();

      history.save('stored note', title: 'Private');
      await history.pendingWrite;

      final restoredHistory = VaporNotesHistory();
      await restoredHistory.load();

      expect(restoredHistory.notes, hasLength(1));
      expect(restoredHistory.notes.first.title, 'Private');
      expect(restoredHistory.notes.first.text, 'stored note');
    });

    test('persists note updates and deletes', () async {
      final history = VaporNotesHistory();
      final firstNote = history.save('first');
      final secondNote = history.save('second');
      history.update(id: firstNote!.id, title: 'Edited', text: 'first edited');
      history.delete(secondNote!.id);
      await history.pendingWrite;

      final restoredHistory = VaporNotesHistory();
      await restoredHistory.load();

      expect(restoredHistory.notes, hasLength(1));
      expect(restoredHistory.notes.single.title, 'Edited');
      expect(restoredHistory.notes.single.text, 'first edited');
    });

    test('ignores invalid local storage payloads', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        VaporNotesHistory.storageKey: 'not json',
      });
      final history = VaporNotesHistory();

      await history.load();

      expect(history.notes, isEmpty);
    });
  });
}
