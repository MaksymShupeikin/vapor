import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedVaporNote {
  const SavedVaporNote({
    required this.id,
    this.title = '',
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static SavedVaporNote? fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }

    final id = value['id'];
    final title = value['title'];
    final text = value['text'];
    final createdAt = value['createdAt'];
    if (id is! String || text is! String || text.trim().isEmpty) {
      return null;
    }

    final parsedCreatedAt = createdAt is String
        ? DateTime.tryParse(createdAt)
        : null;

    return SavedVaporNote(
      id: id,
      title: title is String ? title : '',
      text: text,
      createdAt: parsedCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  SavedVaporNote copyWith({String? title, String? text, DateTime? createdAt}) {
    return SavedVaporNote(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VaporNotesHistory extends ChangeNotifier {
  @visibleForTesting
  static const storageKey = 'vapor.saved_notes.v1';

  final List<SavedVaporNote> _notes = <SavedVaporNote>[];
  SharedPreferences? _preferences;
  Future<void>? _loadFuture;
  Future<void> _pendingWrite = Future<void>.value();
  int _mutationVersion = 0;
  bool _isDisposed = false;

  UnmodifiableListView<SavedVaporNote> get notes =>
      UnmodifiableListView(_notes);

  Future<void> get pendingWrite => _pendingWrite;

  Future<void> load() {
    return _loadFuture ??= _loadFromStorage();
  }

  bool containsText(String text) {
    final normalizedText = text.trim();
    return _notes.any((note) => note.text == normalizedText);
  }

  SavedVaporNote? save(String text, {String title = ''}) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return null;
    }
    final normalizedTitle = title.trim();

    final existingIndex = _notes.indexWhere(
      (note) => note.text == normalizedText,
    );
    if (existingIndex != -1) {
      final existing = _notes
          .removeAt(existingIndex)
          .copyWith(title: normalizedTitle.isEmpty ? null : normalizedTitle);
      _notes.insert(0, existing);
      _didMutate();
      notifyListeners();
      return existing;
    }

    final note = SavedVaporNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: normalizedTitle,
      text: normalizedText,
      createdAt: DateTime.now(),
    );
    _notes.insert(0, note);
    _didMutate();
    notifyListeners();
    return note;
  }

  void update({
    required String id,
    required String title,
    required String text,
  }) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      return;
    }

    final normalizedTitle = title.trim();
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      delete(id);
      return;
    }

    _notes[index] = _notes[index].copyWith(
      title: normalizedTitle,
      text: normalizedText,
    );
    _didMutate();
    notifyListeners();
  }

  void delete(String id) {
    final originalLength = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    if (_notes.length != originalLength) {
      _didMutate();
      notifyListeners();
    }
  }

  Future<void> _loadFromStorage() async {
    final versionAtStart = _mutationVersion;
    final preferences = await _getPreferences();
    final savedNotes = _decodeNotes(preferences.getString(storageKey));

    if (versionAtStart != _mutationVersion) {
      return;
    }

    _notes
      ..clear()
      ..addAll(savedNotes);
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<SharedPreferences> _getPreferences() async {
    final existingPreferences = _preferences;
    if (existingPreferences != null) {
      return existingPreferences;
    }

    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    return preferences;
  }

  void _didMutate() {
    _mutationVersion++;
    final snapshot = List<SavedVaporNote>.unmodifiable(_notes);
    _pendingWrite = _pendingWrite
        .then((_) => _persistSnapshot(snapshot))
        .catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'vapor notes history',
              context: ErrorDescription('while persisting saved notes'),
            ),
          );
        });
  }

  Future<void> _persistSnapshot(List<SavedVaporNote> snapshot) async {
    final preferences = await _getPreferences();
    final encodedNotes = jsonEncode(
      snapshot.map((note) => note.toJson()).toList(growable: false),
    );
    await preferences.setString(storageKey, encodedNotes);
  }

  List<SavedVaporNote> _decodeNotes(String? rawNotes) {
    if (rawNotes == null || rawNotes.isEmpty) {
      return <SavedVaporNote>[];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawNotes);
    } on FormatException {
      return <SavedVaporNote>[];
    }

    if (decoded is! List<Object?>) {
      return <SavedVaporNote>[];
    }

    return decoded
        .map(SavedVaporNote.fromJson)
        .nonNulls
        .toList(growable: false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
