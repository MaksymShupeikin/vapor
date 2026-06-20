import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

class VaporTextImproverUnavailable implements Exception {
  const VaporTextImproverUnavailable();
}

class VaporTextImproveException implements Exception {
  const VaporTextImproveException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class VaporTextImprovementClient {
  Future<String> improve({
    required String text,
    required String title,
    required String style,
  });

  void close();
}

class OpenAIVaporTextImprovementClient implements VaporTextImprovementClient {
  OpenAIVaporTextImprovementClient({
    required String apiKey,
    this.model = 'gpt-5.4-nano',
    OpenAIClient? client,
  }) : _client = client ?? OpenAIClient.withApiKey(apiKey),
       _ownsClient = client == null;

  final String model;
  final OpenAIClient _client;
  final bool _ownsClient;

  @override
  Future<String> improve({
    required String text,
    required String title,
    required String style,
  }) async {
    final response = await _client.responses.create(
      CreateResponseRequest(
        model: model,
        instructions: [
          'You improve short private notes.',
          'Preserve the user meaning, language, names, facts, and intent.',
          'Do not add new facts, explanations, headings, quotes, markdown, or commentary.',
          'Return only the improved note text.',
        ].join(' '),
        input: ResponseInput.text(
          [
            'Style: $style',
            if (title.trim().isNotEmpty) 'Title: ${title.trim()}',
            'Text:',
            text,
          ].join('\n'),
        ),
        maxOutputTokens: 500,
      ),
    );

    final improvedText = response.outputText.trim();
    if (improvedText.isEmpty) {
      throw const VaporTextImproveException('OpenAI returned empty text');
    }

    return improvedText;
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class VaporTextImprover {
  VaporTextImprover({VaporTextImprovementClient? client})
    : _client = client ?? _createOpenAIClient();

  final VaporTextImprovementClient? _client;

  bool get isConfigured => _client != null;

  Future<String> improve({
    required String text,
    String title = '',
    String style = 'clear',
  }) async {
    final client = _client;
    if (client == null) {
      throw const VaporTextImproverUnavailable();
    }

    return client.improve(text: text, title: title, style: style);
  }

  void dispose() {
    _client?.close();
  }

  static VaporTextImprovementClient? _createOpenAIClient() {
    if (!dotenv.isInitialized) {
      return null;
    }

    final apiKey = dotenv.maybeGet('OPENAI_API_KEY')?.trim() ?? '';
    if (apiKey.isEmpty) {
      return null;
    }

    final model = dotenv.maybeGet('OPENAI_MODEL')?.trim();
    return OpenAIVaporTextImprovementClient(
      apiKey: apiKey,
      model: model == null || model.isEmpty ? 'gpt-5.4-nano' : model,
    );
  }
}
