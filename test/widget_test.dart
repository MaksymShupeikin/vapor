import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vapor/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows a quiet starter hint before typing', (tester) async {
    await tester.pumpWidget(const VaporApp());

    expect(find.text('space hides words  ·  enter reveals'), findsOneWidget);
  });

  testWidgets('compiles discreet words into an editable note', (tester) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    expect(input, findsOneWidget);

    await tester.enterText(input, 'quiet ');
    await tester.pump(const Duration(milliseconds: 220));

    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const ValueKey('compiled-note-title-input')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compiled-note-text-input')),
      findsOneWidget,
    );
    expect(find.text('quiet signal'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('compiled-note-title-input')),
      'Public thought',
    );
    await tester.enterText(
      find.byKey(const ValueKey('compiled-note-text-input')),
      'quiet signal edited',
    );
    await tester.pump();

    expect(find.text('Public thought'), findsWidgets);
    expect(find.text('quiet signal edited'), findsWidgets);
  });

  testWidgets('saves a compiled note and shows it in history', (tester) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    await tester.enterText(input, 'quiet ');
    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('quiet signal'), findsNWidgets(2));
    expect(
      find.textContaining(RegExp(r'\d{1,2} [а-я]+, \d{2}:\d{2}')),
      findsOneWidget,
    );
  });

  testWidgets('asks for confirmation before deleting a saved note', (
    tester,
  ) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    await tester.enterText(input, 'quiet ');
    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();

    expect(find.text('Delete note?'), findsOneWidget);
    expect(find.text('quiet signal'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete note?'), findsNothing);
    expect(find.text('quiet signal'), findsWidgets);

    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Delete note?'), findsNothing);
    expect(find.text('quiet signal'), findsOneWidget);
  });

  testWidgets('shows note actions when compiled editor is not focused', (
    tester,
  ) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    await tester.enterText(input, 'quiet ');
    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });

  testWidgets('opens improvement tone picker from the AI action', (
    tester,
  ) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    await tester.enterText(input, 'quiet ');
    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('tone-cards-list')), findsNothing);

    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tone-cards-list')), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Formal'), findsOneWidget);

    await tester.tapAt(const Offset(20, 240));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tone-cards-list')), findsNothing);
  });

  testWidgets('theme picker is separate from history', (tester) async {
    await tester.pumpWidget(const VaporApp());

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-cards-list')), findsOneWidget);
    expect(find.text('Graphite'), findsOneWidget);
    expect(find.text('Charcoal'), findsOneWidget);

    await tester.tap(find.byTooltip('Close theme picker'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Graphite'), findsNothing);
  });

  testWidgets('searches saved notes from history header', (tester) async {
    await tester.pumpWidget(const VaporApp());

    final input = find.byKey(const ValueKey('vapor-hidden-input'));
    await tester.enterText(input, 'quiet ');
    await tester.enterText(input, 'signal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const ValueKey('compiled-note-title-input')),
      'Public thought',
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsNothing);
    expect(find.byKey(const ValueKey('history-search-input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('history-search-input')),
      'public',
    );
    await tester.pumpAndSettle();

    expect(find.text('Public thought'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('history-search-input')),
      'missing',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching notes.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-search-input')), findsNothing);
  });
}
