import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/vapor_note_controller.dart';
import '../application/vapor_notes_history.dart';
import '../application/vapor_text_improver.dart';
import 'vapor_visual_theme.dart';
import 'widgets/active_word_display.dart';
import 'widgets/frosted_panel.dart';
import 'widgets/history_drawer.dart';
import 'widgets/levitating_button.dart';
import 'widgets/vapor_background.dart';

class VaporNoteScreen extends StatefulWidget {
  const VaporNoteScreen({super.key});

  @override
  State<VaporNoteScreen> createState() => _VaporNoteScreenState();
}

class _VaporNoteScreenState extends State<VaporNoteScreen> {
  static const _swipeVelocityThreshold = 280.0;
  static const _shareChannel = MethodChannel('vapor/share');
  static const _improvementTones = <_ImprovementTone>[
    _ImprovementTone(label: 'Clear', style: 'clear, natural, lightly polished'),
    _ImprovementTone(label: 'Short', style: 'concise and compressed'),
    _ImprovementTone(label: 'Warm', style: 'warm, calm, and human'),
    _ImprovementTone(label: 'Formal', style: 'formal and professional'),
    _ImprovementTone(label: 'Casual', style: 'casual and conversational'),
    _ImprovementTone(label: 'Confident', style: 'confident and direct'),
    _ImprovementTone(label: 'Soft', style: 'gentle and tactful'),
    _ImprovementTone(label: 'Polished', style: 'smooth and refined'),
  ];

  late final VaporNoteController _noteController;
  late final VaporNotesHistory _history;
  late final VaporTextImprover _textImprover;
  late final TextEditingController _inputController;
  late final TextEditingController _noteTitleController;
  late final TextEditingController _noteTextController;
  late final FocusNode _inputFocusNode;
  late final FocusNode _noteTitleFocusNode;
  late final FocusNode _noteTextFocusNode;

  bool _isHistoryOpen = false;
  bool _isThemePickerOpen = false;
  bool _isTonePickerOpen = false;
  bool _isImproving = false;
  String? _activeNoteId;
  int _themeIndex = 0;
  int _toneIndex = 0;
  int _statusSignal = 0;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _noteController = VaporNoteController();
    _history = VaporNotesHistory();
    _textImprover = VaporTextImprover();
    _history.load();
    _inputController = TextEditingController();
    _noteTitleController = TextEditingController();
    _noteTextController = TextEditingController();
    _inputFocusNode = FocusNode(debugLabel: 'vapor-hidden-input');
    _noteTitleFocusNode = FocusNode(debugLabel: 'vapor-note-title');
    _noteTextFocusNode = FocusNode(debugLabel: 'vapor-note-text');
    _noteTitleFocusNode.addListener(_handleEditorFocusChanged);
    _noteTextFocusNode.addListener(_handleEditorFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInputFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _history.dispose();
    _textImprover.dispose();
    _inputController.dispose();
    _noteTitleController.dispose();
    _noteTextController.dispose();
    _inputFocusNode.dispose();
    _noteTitleFocusNode
      ..removeListener(_handleEditorFocusChanged)
      ..dispose();
    _noteTextFocusNode
      ..removeListener(_handleEditorFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualTheme = vaporVisualThemes[_themeIndex];
    final themedData = visualTheme.toThemeData(Theme.of(context));

    return Theme(
      data: themedData,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: visualTheme.background,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_noteController, _history]),
          builder: (context, _) {
            final hasSentence = _noteController.hasCompiledSentence;
            final editorFocused =
                _noteTitleFocusNode.hasFocus || _noteTextFocusNode.hasFocus;
            final showCompiledActions =
                hasSentence &&
                !editorFocused &&
                !_isHistoryOpen &&
                !_isThemePickerOpen;

            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleCanvasTap,
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VaporBackground(color: visualTheme.background),
                        SafeArea(
                          bottom: !hasSentence,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: hasSentence
                                ? _CompiledSentenceView(
                                    key: const ValueKey(
                                      'compiled-sentence-view',
                                    ),
                                    titleController: _noteTitleController,
                                    textController: _noteTextController,
                                    titleFocusNode: _noteTitleFocusNode,
                                    textFocusNode: _noteTextFocusNode,
                                    statusMessage: _statusMessage,
                                    onTitleChanged: _handleNoteTitleChanged,
                                    onTextChanged: _handleNoteTextChanged,
                                    onBackgroundTap: _handleCanvasTap,
                                  )
                                : ActiveWordDisplay(
                                    key: const ValueKey('active-word-view'),
                                    word: _noteController.currentWord,
                                    showHint:
                                        _noteController.words.isEmpty &&
                                        _noteController.currentWord.isEmpty,
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: _HiddenTextInput(
                            controller: _inputController,
                            focusNode: _inputFocusNode,
                            onChanged: _handleInputChanged,
                            onSubmitted: (_) => _completeSentence(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_isThemePickerOpen,
                      child: AnimatedOpacity(
                        opacity: _isThemePickerOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: GestureDetector(
                              onTap: _toggleThemePicker,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: _TopControls(
                      isHistoryOpen: _isHistoryOpen,
                      isThemePickerOpen: _isThemePickerOpen,
                      themes: vaporVisualThemes,
                      selectedThemeIndex: _themeIndex,
                      onHistoryPressed: _toggleHistory,
                      onThemePressed: _toggleThemePicker,
                      onThemeSelected: _selectTheme,
                      onResetPressed: _reset,
                    ),
                  ),
                  _BottomWordControls(
                    visible: _noteController.canRestorePreviousWord,
                    onPreviousWordPressed: _restorePreviousWord,
                  ),
                  _CompiledNoteActions(
                    visible: showCompiledActions,
                    onSharePressed: _shareCompiledText,
                    onCopyPressed: _copyCompiledText,
                    isImproving: _isImproving,
                    isTonePickerOpen: _isTonePickerOpen,
                    onImprovePressed: _toggleTonePicker,
                  ),
                  _ImprovementTonePicker(
                    visible: showCompiledActions && _isTonePickerOpen,
                    tones: _improvementTones,
                    selectedToneIndex: _toneIndex,
                    onToneSelected: _improveCompiledText,
                  ),
                  VaporHistoryDrawer(
                    isOpen: _isHistoryOpen,
                    notes: _history.notes,
                    onClose: _closeHistory,
                    onNoteSelected: _openSavedNote,
                    onNoteDeleted: _deleteSavedNote,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleInputChanged(String value) {
    final result = _noteController.handleTextInput(value);
    if (result.replacementText != null) {
      _replaceHiddenInputText(result.replacementText!);
    }

    if (result.action == VaporInputAction.wordCommitted) {
      HapticFeedback.selectionClick();
    }

    if (result.action == VaporInputAction.sentenceCompleted) {
      _syncEditorFromCompiledText();
      _autoSaveCompiledNote();
      _inputFocusNode.unfocus();
    }
  }

  void _completeSentence() {
    final completed = _noteController.completeSentence();
    _replaceHiddenInputText('');

    if (completed) {
      _syncEditorFromCompiledText();
      _autoSaveCompiledNote();
      _inputFocusNode.unfocus();
    } else {
      _requestInputFocus();
    }
  }

  void _restorePreviousWord() {
    final restoredWord = _noteController.restorePreviousWord();
    if (restoredWord == null) {
      return;
    }

    _replaceHiddenInputText(restoredWord);
    _requestInputFocus();
    HapticFeedback.selectionClick();
  }

  void _autoSaveCompiledNote() {
    final sentence = _noteTextController.text.trim().isEmpty
        ? _noteController.compiledSentence
        : _noteTextController.text;
    if (sentence.isEmpty || _history.containsText(sentence)) {
      return;
    }

    final savedNote = _history.save(sentence, title: _noteTitleController.text);
    if (savedNote == null) {
      return;
    }

    _activeNoteId = savedNote.id;
    _showStatus('SAVED');
    HapticFeedback.mediumImpact();
  }

  void _openSavedNote(SavedVaporNote note) {
    _noteController.loadCompiledSentence(note.text);
    _activeNoteId = note.id;
    _setEditorTitle(note.title);
    _setEditorText(note.text);
    _replaceHiddenInputText('');
    _inputFocusNode.unfocus();
    HapticFeedback.selectionClick();
    _closeHistory(withHaptic: false);
  }

  Future<void> _deleteSavedNote(SavedVaporNote note) async {
    final confirmed = await _confirmDeleteNote(note);
    if (!mounted || !confirmed) {
      return;
    }

    _history.delete(note.id);
    _showStatus('DELETED');
    HapticFeedback.selectionClick();
  }

  Future<bool> _confirmDeleteNote(SavedVaporNote note) async {
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();
    HapticFeedback.lightImpact();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss delete confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: FrostedPanel(
                radius: 26,
                blur: 22,
                surfaceOpacity: 0.20,
                borderOpacity: 0.22,
                shadowOpacity: 0.38,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Delete note?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$title" will be removed from history.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.70),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(false);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.92,
                            ),
                            foregroundColor: colorScheme.surface,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final scale = Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );

    return confirmed ?? false;
  }

  void _reset() {
    _noteController.reset();
    _replaceHiddenInputText('');
    _setEditorTitle('');
    _setEditorText('');
    _activeNoteId = null;
    _isTonePickerOpen = false;
    _statusSignal++;
    HapticFeedback.mediumImpact();

    if (_statusMessage != null) {
      setState(() {
        _statusMessage = null;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInputFocus();
    });
  }

  Future<void> _copyCompiledText() async {
    final sentence = _noteTextController.text.trim();
    if (sentence.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: sentence));
    await HapticFeedback.mediumImpact();

    if (!mounted) {
      return;
    }

    _showStatus('COPIED');
  }

  Future<void> _shareCompiledText() async {
    final text = _sharePayload();
    if (text.isEmpty) {
      return;
    }

    try {
      await _shareChannel.invokeMethod<void>('shareText', {
        'title': _noteTitleController.text.trim().isEmpty
            ? 'Vapor note'
            : _noteTitleController.text.trim(),
        'text': text,
      });
      await HapticFeedback.mediumImpact();

      if (mounted) {
        _showStatus('SHARED');
      }
    } on MissingPluginException {
      await _copyShareFallback(text);
    } on PlatformException {
      await _copyShareFallback(text);
    }
  }

  Future<void> _copyShareFallback(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await HapticFeedback.mediumImpact();

    if (mounted) {
      _showStatus('SHARE COPIED');
    }
  }

  void _toggleTonePicker() {
    if (_isImproving) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isTonePickerOpen = !_isTonePickerOpen;
    });
  }

  Future<void> _improveCompiledText(int toneIndex) async {
    final text = _noteTextController.text.trim();
    if (text.isEmpty || _isImproving) {
      return;
    }
    final tone = _improvementTones[toneIndex];

    HapticFeedback.selectionClick();
    setState(() {
      _toneIndex = toneIndex;
      _isTonePickerOpen = false;
      _isImproving = true;
    });
    _showStatus(_textImprover.isConfigured ? 'AI...' : 'LOCAL');

    try {
      final improvedText = await _textImprover.improve(
        text: text,
        title: _noteTitleController.text,
        style: tone.style,
      );
      if (!mounted) {
        return;
      }

      _setEditorText(improvedText);
      _handleNoteTextChanged(improvedText);
      _showStatus('AI DONE');
      HapticFeedback.mediumImpact();
    } on VaporTextImproverUnavailable {
      final improvedText = _localPolish(text);
      if (!mounted) {
        return;
      }

      _setEditorText(improvedText);
      _handleNoteTextChanged(improvedText);
      _showStatus('LOCAL');
      HapticFeedback.mediumImpact();
    } on Object {
      if (mounted) {
        _showStatus('AI FAILED');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImproving = false;
        });
      }
    }
  }

  void _showStatus(String message) {
    if (!mounted) {
      return;
    }

    final signal = ++_statusSignal;
    setState(() {
      _statusMessage = message;
    });

    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (!mounted || signal != _statusSignal) {
        return;
      }

      setState(() {
        _statusMessage = null;
      });
    });
  }

  void _toggleHistory() {
    HapticFeedback.lightImpact();
    setState(() {
      _isHistoryOpen = !_isHistoryOpen;
      if (_isHistoryOpen) {
        _isThemePickerOpen = false;
        _isTonePickerOpen = false;
      }
    });

    if (!_isHistoryOpen) {
      _requestInputFocus();
    } else {
      _inputFocusNode.unfocus();
    }
  }

  void _closeHistory({bool withHaptic = true}) {
    if (!_isHistoryOpen) {
      return;
    }

    if (withHaptic) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _isHistoryOpen = false;
    });

    if (!_noteController.hasCompiledSentence) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestInputFocus();
      });
    }
  }

  void _toggleThemePicker() {
    HapticFeedback.lightImpact();
    setState(() {
      _isThemePickerOpen = !_isThemePickerOpen;
      if (_isThemePickerOpen) {
        _isHistoryOpen = false;
        _isTonePickerOpen = false;
      }
    });

    if (!_isThemePickerOpen) {
      _requestInputFocus();
    } else {
      _inputFocusNode.unfocus();
    }
  }

  void _selectTheme(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _themeIndex = index;
    });
  }

  void _handleEditorFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleCanvasTap() {
    if (_isTonePickerOpen) {
      HapticFeedback.selectionClick();
      setState(() {
        _isTonePickerOpen = false;
      });
      return;
    }

    if (_noteController.hasCompiledSentence) {
      FocusScope.of(context).unfocus();
    } else {
      _requestInputFocus();
    }
  }

  void _handleNoteTitleChanged(String title) {
    _persistActiveNote();
  }

  void _handleNoteTextChanged(String text) {
    _noteController.updateCompiledSentence(text);
    _persistActiveNote();
  }

  void _persistActiveNote() {
    final text = _noteTextController.text;
    if (text.trim().isEmpty) {
      return;
    }

    final activeNoteId = _activeNoteId;
    if (activeNoteId == null) {
      final savedNote = _history.save(text, title: _noteTitleController.text);
      _activeNoteId = savedNote?.id;
      return;
    }

    _history.update(
      id: activeNoteId,
      title: _noteTitleController.text,
      text: text,
    );
  }

  void _syncEditorFromCompiledText() {
    _setEditorText(_noteController.compiledSentence);
  }

  void _setEditorTitle(String title) {
    _noteTitleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  void _setEditorText(String text) {
    _noteTextController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _replaceHiddenInputText(String text) {
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _requestInputFocus() {
    if (_noteController.hasCompiledSentence ||
        _isHistoryOpen ||
        _isThemePickerOpen) {
      return;
    }

    _inputFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  String _sharePayload() {
    final title = _noteTitleController.text.trim();
    final text = _noteTextController.text.trim();
    if (title.isEmpty) {
      return text;
    }

    if (text.isEmpty) {
      return title;
    }

    return '$title\n\n$text';
  }

  String _localPolish(String text) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) {
      return collapsed;
    }

    final first = collapsed.substring(0, 1).toUpperCase();
    final rest = collapsed.length == 1 ? '' : collapsed.substring(1);
    final sentence = '$first$rest';

    if (RegExp(r'[.!?]$').hasMatch(sentence)) {
      return sentence;
    }

    return '$sentence.';
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_swipeVelocityThreshold) {
      _reset();
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > _swipeVelocityThreshold) {
      _completeSentence();
    }
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.isHistoryOpen,
    required this.isThemePickerOpen,
    required this.themes,
    required this.selectedThemeIndex,
    required this.onHistoryPressed,
    required this.onThemePressed,
    required this.onThemeSelected,
    required this.onResetPressed,
  });

  final bool isHistoryOpen;
  final bool isThemePickerOpen;
  final List<VaporVisualTheme> themes;
  final int selectedThemeIndex;
  final VoidCallback onHistoryPressed;
  final VoidCallback onThemePressed;
  final ValueChanged<int> onThemeSelected;
  final VoidCallback onResetPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const buttonExtent = 50.0;
            const buttonGap = 10.0;
            final closedThemeLeft =
                constraints.maxWidth - (buttonExtent * 2) - buttonGap;
            final openThemeLeft = constraints.maxWidth - buttonExtent;

            return SizedBox(
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: isThemePickerOpen,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: isThemePickerOpen ? 0 : 1,
                        child: LevitatingButton(
                          icon: isHistoryOpen
                              ? Icons.close_rounded
                              : Icons.history_rounded,
                          tooltip: isHistoryOpen
                              ? 'Close history'
                              : 'Open history',
                          selected: isHistoryOpen,
                          onPressed: onHistoryPressed,
                          large: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: isThemePickerOpen,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: isThemePickerOpen ? 0 : 1,
                        child: LevitatingButton(
                          icon: Icons.add_rounded,
                          tooltip: 'New note',
                          onPressed: onResetPressed,
                          large: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: buttonExtent + 12,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: !isThemePickerOpen,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: isThemePickerOpen
                            ? _ThemeCardsList(
                                key: const ValueKey('theme-cards-visible'),
                                themes: themes,
                                selectedThemeIndex: selectedThemeIndex,
                                onThemeSelected: onThemeSelected,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('theme-cards-hidden'),
                              ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: isThemePickerOpen ? openThemeLeft : closedThemeLeft,
                    top: 0,
                    child: LevitatingButton(
                      icon: isThemePickerOpen
                          ? Icons.close_rounded
                          : Icons.palette_outlined,
                      tooltip: isThemePickerOpen
                          ? 'Close theme picker'
                          : 'Open theme picker',
                      selected: isThemePickerOpen,
                      onPressed: onThemePressed,
                      large: true,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeCardsList extends StatelessWidget {
  const _ThemeCardsList({
    super.key,
    required this.themes,
    required this.selectedThemeIndex,
    required this.onThemeSelected,
  });

  final List<VaporVisualTheme> themes;
  final int selectedThemeIndex;
  final ValueChanged<int> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, 0.08, 0.92, 1],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          key: const ValueKey('theme-cards-list'),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: themes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return _ThemeColorCard(
              theme: themes[index],
              selected: index == selectedThemeIndex,
              onTap: () => onThemeSelected(index),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeColorCard extends StatelessWidget {
  const _ThemeColorCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final VaporVisualTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FrostedPanel(
        radius: 20,
        blur: 14,
        surfaceOpacity: selected ? 0.36 : 0.22,
        borderOpacity: selected ? 0.72 : 0.24,
        shadowOpacity: selected ? 0.44 : 0.22,
        padding: const EdgeInsets.fromLTRB(9, 8, 12, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected
                          ? colorScheme.onSurface.withValues(alpha: 0.88)
                          : theme.outline.withValues(alpha: 0.55),
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.90),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: colorScheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 9),
            Text(
              theme.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(
                  alpha: selected ? 0.98 : 0.82,
                ),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImprovementTone {
  const _ImprovementTone({required this.label, required this.style});

  final String label;
  final String style;
}

class _BottomWordControls extends StatelessWidget {
  const _BottomWordControls({
    required this.visible,
    required this.onPreviousWordPressed,
  });

  final bool visible;
  final VoidCallback onPreviousWordPressed;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: 24,
      right: 24,
      bottom: keyboardInset + 14,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: visible ? 1 : 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: LevitatingButton(
              icon: Icons.undo_rounded,
              label: 'Previous word',
              tooltip: 'Return to previous word',
              onPressed: onPreviousWordPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompiledNoteActions extends StatelessWidget {
  const _CompiledNoteActions({
    required this.visible,
    required this.onSharePressed,
    required this.onCopyPressed,
    required this.isImproving,
    required this.isTonePickerOpen,
    required this.onImprovePressed,
  });

  final bool visible;
  final VoidCallback onSharePressed;
  final VoidCallback onCopyPressed;
  final bool isImproving;
  final bool isTonePickerOpen;
  final VoidCallback? onImprovePressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: 22,
      right: 22,
      bottom: 24,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: visible ? 1 : 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LevitatingButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                tooltip: 'Share note',
                onPressed: onSharePressed,
              ),
              const SizedBox(width: 10),
              LevitatingButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                tooltip: 'Copy note',
                onPressed: onCopyPressed,
              ),
              const SizedBox(width: 10),
              LevitatingButton(
                icon: isTonePickerOpen
                    ? Icons.close_rounded
                    : Icons.auto_awesome_rounded,
                label: isImproving ? 'AI...' : 'AI',
                tooltip: isTonePickerOpen ? 'Close tones' : 'Improve with AI',
                onPressed: onImprovePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImprovementTonePicker extends StatelessWidget {
  const _ImprovementTonePicker({
    required this.visible,
    required this.tones,
    required this.selectedToneIndex,
    required this.onToneSelected,
  });

  final bool visible;
  final List<_ImprovementTone> tones;
  final int selectedToneIndex;
  final ValueChanged<int> onToneSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: 22,
      right: 22,
      bottom: visible ? 84 : 64,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.14),
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: visible
              ? _ImprovementToneCardsList(
                  key: const ValueKey('tone-cards-visible'),
                  tones: tones,
                  selectedToneIndex: selectedToneIndex,
                  onToneSelected: onToneSelected,
                )
              : const SizedBox.shrink(key: ValueKey('tone-cards-hidden')),
        ),
      ),
    );
  }
}

class _ImprovementToneCardsList extends StatelessWidget {
  const _ImprovementToneCardsList({
    super.key,
    required this.tones,
    required this.selectedToneIndex,
    required this.onToneSelected,
  });

  final List<_ImprovementTone> tones;
  final int selectedToneIndex;
  final ValueChanged<int> onToneSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, 0.08, 0.92, 1],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          key: const ValueKey('tone-cards-list'),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: tones.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return _ImprovementToneCard(
              tone: tones[index],
              selected: index == selectedToneIndex,
              onTap: () => onToneSelected(index),
            );
          },
        ),
      ),
    );
  }
}

class _ImprovementToneCard extends StatelessWidget {
  const _ImprovementToneCard({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final _ImprovementTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FrostedPanel(
        radius: 20,
        blur: 14,
        surfaceOpacity: selected ? 0.36 : 0.22,
        borderOpacity: selected ? 0.72 : 0.24,
        shadowOpacity: selected ? 0.44 : 0.22,
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected
                          ? colorScheme.onSurface.withValues(alpha: 0.88)
                          : colorScheme.outline.withValues(alpha: 0.28),
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 17,
                    color: colorScheme.onSurface.withValues(
                      alpha: selected ? 0.98 : 0.70,
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.90),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: colorScheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 9),
            Text(
              tone.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(
                  alpha: selected ? 0.98 : 0.82,
                ),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompiledSentenceView extends StatelessWidget {
  const _CompiledSentenceView({
    super.key,
    required this.titleController,
    required this.textController,
    required this.titleFocusNode,
    required this.textFocusNode,
    required this.statusMessage,
    required this.onTitleChanged,
    required this.onTextChanged,
    required this.onBackgroundTap,
  });

  final TextEditingController titleController;
  final TextEditingController textController;
  final FocusNode titleFocusNode;
  final FocusNode textFocusNode;
  final String? statusMessage;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    final hasStatus = statusMessage != null;
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBackgroundTap,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(22, 92, 22, keyboardInset + 112),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostedPanel(
                  radius: 24,
                  blur: 18,
                  surfaceOpacity: 0.14,
                  borderOpacity: 0.16,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const ValueKey('compiled-note-title-input'),
                        controller: titleController,
                        focusNode: titleFocusNode,
                        enableInteractiveSelection: true,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardAppearance: Brightness.dark,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.32,
                                ),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onChanged: onTitleChanged,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey('compiled-note-text-input'),
                        controller: textController,
                        focusNode: textFocusNode,
                        enableInteractiveSelection: true,
                        minLines: 4,
                        maxLines: null,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardAppearance: Brightness.dark,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.94),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          letterSpacing: 0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your note',
                          hintStyle: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.30,
                                ),
                                fontSize: 16,
                                height: 1.35,
                              ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onChanged: onTextChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedOpacity(
                  opacity: hasStatus ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: FrostedPanel(
                    radius: 999,
                    surfaceOpacity: 0.14,
                    borderOpacity: 0.18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    child: Text(
                      statusMessage ?? ' ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HiddenTextInput extends StatelessWidget {
  const _HiddenTextInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0.01,
        child: TextField(
          key: const ValueKey('vapor-hidden-input'),
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          enableInteractiveSelection: false,
          showCursor: false,
          keyboardType: TextInputType.text,
          keyboardAppearance: Brightness.dark,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
            height: 1,
          ),
          cursorColor: Colors.transparent,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}
