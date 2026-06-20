import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../application/vapor_notes_history.dart';
import 'frosted_panel.dart';
import 'levitating_button.dart';

class VaporHistoryDrawer extends StatefulWidget {
  const VaporHistoryDrawer({
    super.key,
    required this.isOpen,
    required this.notes,
    required this.onClose,
    required this.onNoteSelected,
    required this.onNoteDeleted,
  });

  final bool isOpen;
  final List<SavedVaporNote> notes;
  final VoidCallback onClose;
  final ValueChanged<SavedVaporNote> onNoteSelected;
  final ValueChanged<SavedVaporNote> onNoteDeleted;

  @override
  State<VaporHistoryDrawer> createState() => _VaporHistoryDrawerState();
}

class _VaporHistoryDrawerState extends State<VaporHistoryDrawer> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode(debugLabel: 'vapor-history-search');
  }

  @override
  void didUpdateWidget(covariant VaporHistoryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen && !widget.isOpen) {
      _stopSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _filteredNotes();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 420
              ? constraints.maxWidth * 0.84
              : 360.0;

          return IgnorePointer(
            ignoring: !widget.isOpen,
            child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: widget.isOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: SafeArea(
                    right: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: widget.isOpen ? 1 : 0),
                        duration: const Duration(milliseconds: 340),
                        curve: widget.isOpen
                            ? Curves.easeOutCubic
                            : Curves.easeInCubic,
                        builder: (context, value, child) {
                          final progress = value.clamp(0.0, 1.0);
                          final scale = 0.85 + progress * 0.15;
                          final slideX = -30.0 * (1 - progress);
                          final opacity = progress;

                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(slideX, 0),
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.topLeft,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: FrostedPanel(
                          radius: 28,
                          blur: 20,
                          surfaceOpacity: 0.18,
                          borderOpacity: 0.18,
                          shadowOpacity: 0.34,
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DrawerHeader(
                                isSearching: _isSearching,
                                searchController: _searchController,
                                searchFocusNode: _searchFocusNode,
                                onSearchChanged: (_) => setState(() {}),
                                onSearchPressed: _startSearch,
                                onClosePressed: _isSearching
                                    ? _stopSearch
                                    : widget.onClose,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: widget.notes.isEmpty
                                    ? const _EmptyHistory()
                                    : filteredNotes.isEmpty
                                    ? const _EmptySearchResults()
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          4,
                                          16,
                                          18,
                                        ),
                                        itemCount: filteredNotes.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final note = filteredNotes[index];
                                          return _HistoryNoteTile(
                                            note: note,
                                            onTap: () =>
                                                widget.onNoteSelected(note),
                                            onDelete: () =>
                                                widget.onNoteDeleted(note),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<SavedVaporNote> _filteredNotes() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.notes;
    }

    return widget.notes
        .where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.text.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _startSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _stopSearch() {
    if (!_isSearching && _searchController.text.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchPressed,
    required this.onClosePressed,
  });

  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 8),
      child: SizedBox(
        height: 50,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const closeWidth = 45.0;
            const gap = 10.0;
            const closedSearchWidth = 45.0;
            final expandedSearchWidth = constraints.maxWidth - closeWidth - gap;
            final closedSearchLeft = expandedSearchWidth - closedSearchWidth;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  right: closeWidth + gap,
                  child: IgnorePointer(
                    ignoring: isSearching,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: isSearching
                          ? const SizedBox.shrink(
                              key: ValueKey('history-title-hidden'),
                            )
                          : Align(
                              key: const ValueKey('history-title-visible'),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'History',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: isSearching ? 0 : closedSearchLeft,
                  top: 0,
                  width: isSearching ? expandedSearchWidth : closedSearchWidth,
                  child: _ExpandingHistorySearch(
                    isSearching: isSearching,
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onSearchPressed: onSearchPressed,
                    onChanged: onSearchChanged,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: LevitatingButton(
                    icon: Icons.close_rounded,
                    tooltip: isSearching ? 'Close search' : 'Close history',
                    selected: isSearching,
                    onPressed: onClosePressed,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpandingHistorySearch extends StatelessWidget {
  const _ExpandingHistorySearch({
    required this.isSearching,
    required this.controller,
    required this.focusNode,
    required this.onSearchPressed,
    required this.onChanged,
  });

  final bool isSearching;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Search notes',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isSearching ? null : onSearchPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 45,
          padding: EdgeInsets.only(left: 12, right: isSearching ? 12 : 0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: isSearching ? 0.16 : 0.13,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: isSearching ? 0.20 : 0.16,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 19,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 170),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isSearching
                      ? TextField(
                          key: const ValueKey('history-search-input'),
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          keyboardAppearance: Brightness.dark,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Search notes',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.42,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: const EdgeInsets.only(left: 9),
                          ),
                          onChanged: onChanged,
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('history-search-input-hidden'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryNoteTile extends StatelessWidget {
  const _HistoryNoteTile({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final SavedVaporNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();

    return FrostedPanel(
      radius: 18,
      blur: 14,
      surfaceOpacity: 0.11,
      borderOpacity: 0.12,
      shadowOpacity: 0.18,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      note.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatTime(note.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete note',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.64),
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    const monthNames = <String>[
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    final day = dateTime.day.toString();
    final month = monthNames[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Saved notes will appear here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.52),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResults extends StatelessWidget {
  const _EmptySearchResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'No matching notes.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.52),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
