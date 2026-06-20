import 'dart:async';

import 'package:flutter/material.dart';

class ActiveWordDisplay extends StatelessWidget {
  const ActiveWordDisplay({
    super.key,
    required this.word,
    required this.showHint,
  });

  final String word;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: colorScheme.onSurface,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: 0,
      shadows: [
        Shadow(
          color: colorScheme.shadow.withValues(alpha: 0.18),
          blurRadius: 20,
        ),
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: SizedBox(
          width: double.infinity,
          height: 140,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 170),
              reverseDuration: const Duration(milliseconds: 190),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, -0.24),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: word.isEmpty
                  ? showHint
                        ? const _TypingAnimationHint(
                            key: ValueKey('typing-hint'),
                          )
                        : const SizedBox(
                            key: ValueKey('empty-active-word'),
                            height: 52,
                          )
                  : FittedBox(
                      key: const ValueKey('visible-active-word'),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        word,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingAnimationHint extends StatefulWidget {
  const _TypingAnimationHint({super.key});

  @override
  State<_TypingAnimationHint> createState() => _TypingAnimationHintState();
}

class _TypingAnimationHintState extends State<_TypingAnimationHint> {
  static const _phrases = [
    'your thoughts',
    'a quick note',
    'an idea',
    'something important',
    'a reminder',
    'a daily log',
    'a memory',
    'a note to self',
    'something creative',
  ];

  static const _typeSpeed = Duration(milliseconds: 85);
  static const _deleteSpeed = Duration(milliseconds: 45);
  static const _pauseAfterType = Duration(milliseconds: 1800);
  static const _pauseAfterDelete = Duration(milliseconds: 500);

  int _phraseIndex = 0;
  String _displayText = '';
  bool _isDeleting = false;
  Timer? _animTimer;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
    _scheduleNextTick();
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextTick() {
    final phrase = _phrases[_phraseIndex];

    if (!_isDeleting) {
      if (_displayText.length < phrase.length) {
        _animTimer = Timer(_typeSpeed, () {
          if (!mounted) return;
          setState(() {
            _displayText = phrase.substring(0, _displayText.length + 1);
          });
          _scheduleNextTick();
        });
      } else {
        _animTimer = Timer(_pauseAfterType, () {
          if (!mounted) return;
          setState(() => _isDeleting = true);
          _scheduleNextTick();
        });
      }
    } else {
      if (_displayText.isNotEmpty) {
        _animTimer = Timer(_deleteSpeed, () {
          if (!mounted) return;
          setState(() {
            _displayText =
                _displayText.substring(0, _displayText.length - 1);
          });
          _scheduleNextTick();
        });
      } else {
        _animTimer = Timer(_pauseAfterDelete, () {
          if (!mounted) return;
          setState(() {
            _phraseIndex = (_phraseIndex + 1) % _phrases.length;
            _isDeleting = false;
          });
          _scheduleNextTick();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface.withValues(alpha: 0.28);
    final textStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: textColor,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: 0,
    );

    return Semantics(
      label: 'Start typing to create a note',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: _displayText),
                TextSpan(
                  text: '│',
                  style: TextStyle(
                    color: textColor.withValues(
                      alpha: _cursorVisible ? 0.40 : 0,
                    ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: textStyle,
          ),
          const SizedBox(height: 24),
          Text(
            'space hides words  ·  enter reveals',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.16),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
