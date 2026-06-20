import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vapor/features/vapor_note/application/vapor_text_improver.dart';

void main() {
  group('VaporTextImprover', () {
    tearDown(dotenv.clean);

    test('returns improved text from an injected OpenAI client', () async {
      final fakeClient = _FakeTextImprovementClient('Quiet signal.');
      final improver = VaporTextImprover(client: fakeClient);

      final improvedText = await improver.improve(text: 'quiet signal');

      expect(improvedText, 'Quiet signal.');
      expect(fakeClient.lastText, 'quiet signal');
      improver.dispose();
      expect(fakeClient.closed, isTrue);
    });

    test('throws unavailable when OPENAI_API_KEY is not configured', () async {
      dotenv.loadFromString(envString: '', isOptional: true);
      final improver = VaporTextImprover();

      expect(
        () => improver.improve(text: 'quiet signal'),
        throwsA(isA<VaporTextImproverUnavailable>()),
      );
      improver.dispose();
    });
  });
}

class _FakeTextImprovementClient implements VaporTextImprovementClient {
  _FakeTextImprovementClient(this.improvedText);

  final String improvedText;
  String? lastText;
  bool closed = false;

  @override
  Future<String> improve({
    required String text,
    required String title,
    required String style,
  }) async {
    lastText = text;
    return improvedText;
  }

  @override
  void close() {
    closed = true;
  }
}
