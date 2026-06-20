import 'dart:collection';

import 'package:flutter/foundation.dart';

enum VaporInputAction { none, wordCommitted, sentenceCompleted }

class VaporInputResult {
  const VaporInputResult({
    this.action = VaporInputAction.none,
    this.replacementText,
  });

  final VaporInputAction action;
  final String? replacementText;
}

class VaporNoteController extends ChangeNotifier {
  final List<String> _words = <String>[];
  String _currentWord = '';
  String _compiledSentence = '';
  bool _isCompiled = false;

  UnmodifiableListView<String> get words => UnmodifiableListView(_words);
  String get currentWord => _currentWord;
  String get compiledSentence => _compiledSentence;
  bool get hasCompiledSentence => _isCompiled;
  bool get canRestorePreviousWord => !hasCompiledSentence && _words.isNotEmpty;

  VaporInputResult handleTextInput(String rawValue) {
    if (hasCompiledSentence) {
      return const VaporInputResult(replacementText: '');
    }

    final completionIndex = rawValue.indexOf(RegExp(r'[\r\n]'));
    final shouldComplete = completionIndex != -1;
    final editableText = shouldComplete
        ? rawValue.substring(0, completionIndex)
        : rawValue;

    final tokens = editableText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    final containsDelimiter = RegExp(r'\s').hasMatch(editableText);
    final endsWithDelimiter = RegExp(r'\s$').hasMatch(editableText);

    if (tokens.isEmpty) {
      final changed = _setCurrentWord('', notify: false);
      if (changed) {
        notifyListeners();
      }

      if (shouldComplete) {
        final completed = completeSentence();
        return VaporInputResult(
          action: completed
              ? VaporInputAction.sentenceCompleted
              : VaporInputAction.none,
          replacementText: '',
        );
      }

      return VaporInputResult(replacementText: containsDelimiter ? '' : null);
    }

    final wordsToCommit = <String>[];
    late final String remainingWord;

    if (endsWithDelimiter) {
      wordsToCommit.addAll(tokens);
      remainingWord = '';
    } else if (tokens.length > 1) {
      wordsToCommit.addAll(tokens.take(tokens.length - 1));
      remainingWord = tokens.last;
    } else {
      remainingWord = tokens.first;
    }

    final committedWord = wordsToCommit.isNotEmpty;
    if (committedWord) {
      _words.addAll(wordsToCommit);
    }

    final currentChanged = _setCurrentWord(remainingWord, notify: false);
    if (committedWord || currentChanged) {
      notifyListeners();
    }

    if (shouldComplete) {
      final completed = completeSentence();
      return VaporInputResult(
        action: completed
            ? VaporInputAction.sentenceCompleted
            : VaporInputAction.none,
        replacementText: '',
      );
    }

    if (committedWord || (containsDelimiter && editableText != remainingWord)) {
      return VaporInputResult(
        action: committedWord
            ? VaporInputAction.wordCommitted
            : VaporInputAction.none,
        replacementText: remainingWord,
      );
    }

    return const VaporInputResult();
  }

  bool completeSentence() {
    if (hasCompiledSentence) {
      return true;
    }

    _commitCurrentWord();
    final sentence = _words.join(' ').trim();
    if (sentence.isEmpty) {
      return false;
    }

    _compiledSentence = sentence;
    _isCompiled = true;
    notifyListeners();
    return true;
  }

  String? restorePreviousWord() {
    if (!canRestorePreviousWord) {
      return null;
    }

    _currentWord = _words.removeLast();
    notifyListeners();
    return _currentWord;
  }

  void loadCompiledSentence(String sentence) {
    final trimmedSentence = sentence.trim();
    if (trimmedSentence.isEmpty) {
      return;
    }

    _words.clear();
    _currentWord = '';
    _compiledSentence = trimmedSentence;
    _isCompiled = true;
    notifyListeners();
  }

  void updateCompiledSentence(String sentence) {
    if (_compiledSentence == sentence && _isCompiled) {
      return;
    }

    _words.clear();
    _currentWord = '';
    _compiledSentence = sentence;
    _isCompiled = true;
    notifyListeners();
  }

  void reset() {
    if (_words.isEmpty &&
        _currentWord.isEmpty &&
        _compiledSentence.isEmpty &&
        !_isCompiled) {
      return;
    }

    _words.clear();
    _currentWord = '';
    _compiledSentence = '';
    _isCompiled = false;
    notifyListeners();
  }

  void _commitCurrentWord() {
    final word = _currentWord.trim();
    if (word.isEmpty) {
      return;
    }

    _words.add(word);
    _currentWord = '';
  }

  bool _setCurrentWord(String word, {required bool notify}) {
    if (_currentWord == word) {
      return false;
    }

    _currentWord = word;
    if (notify) {
      notifyListeners();
    }
    return true;
  }
}
