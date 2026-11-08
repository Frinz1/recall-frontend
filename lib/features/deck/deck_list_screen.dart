import 'package:flutter/material.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/services/study_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/toast_feedback.dart';
import '../subject/subject_list_screen.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  String? _selectedSubjectId;
  bool _onlyStarred = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudyRepository.instance,
      builder: (context, _) {
        final repo = StudyRepository.instance;
        final subjects = repo.subjects;

        var filteredDecks = repo.decks.where((deck) {
          if (_onlyStarred && !deck.isFavorite) {
            return false;
          }
          if (_selectedSubjectId != null && deck.subjectId != _selectedSubjectId) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return deck.title.toLowerCase().contains(q) ||
                deck.description.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Decks & Library', style: AppTypography.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'Manage Subjects',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubjectListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Create New Deck',
                onPressed: () => _openCreateDeckDialog(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search decks or topics...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgSurface1,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),

              // Subject + Starred Filter Chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          'New Subject',
                          style: AppTypography.badge.copyWith(color: AppColors.primary),
                        ),
                        backgroundColor: AppColors.bgSurface1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () => _openCreateSubjectDialog(context),
                      ),
                    ),
                    _buildChip(
                      label: 'All Decks',
                      isSelected: !_onlyStarred && _selectedSubjectId == null,
                      onTap: () => setState(() {
                        _onlyStarred = false;
                        _selectedSubjectId = null;
                      }),
                    ),
                    _buildChip(
                      label: '★ Starred',
                      isSelected: _onlyStarred,
                      onTap: () => setState(() {
                        _onlyStarred = !_onlyStarred;
                      }),
                    ),
                    ...subjects.map((sub) {
                      return _buildChip(
                        label: sub.name,
                        isSelected: _selectedSubjectId == sub.id,
                        onTap: () => setState(() {
                          _selectedSubjectId =
                              _selectedSubjectId == sub.id ? null : sub.id;
                        }),
                      );
                    }),
                  ],
                ),
              ),

              // Deck List or Empty State
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.bgSurface1,
                  onRefresh: () => repo.fetchAllFromCloud(),
                  child: filteredDecks.isEmpty
                      ? EmptyStateView(
                          icon: _onlyStarred ? Icons.star_outline_rounded : Icons.style_outlined,
                          title: _onlyStarred ? 'No Starred Decks Yet' : 'No Decks Found',
                          description: _onlyStarred
                              ? 'Tap the star icon on any deck to pin it to the top of your library.'
                              : (_searchQuery.isNotEmpty
                                  ? 'No decks match "$_searchQuery".'
                                  : 'Create a subject and your first flashcard deck to start studying.'),
                          ctaLabel: _onlyStarred ? 'Show All Decks' : 'Create New Deck',
                          onCtaPressed: _onlyStarred
                              ? () => setState(() => _onlyStarred = false)
                              : () => _openCreateDeckDialog(context),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: filteredDecks.length,
                          itemBuilder: (context, index) {
                            final deck = filteredDecks[index];
                            return _buildDeckCard(context, deck);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: isSelected ? AppColors.bgCanvas : AppColors.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.bgSurface1,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.bgCanvas,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deck.isFavorite
              ? Colors.amber.withValues(alpha: 0.45)
              : AppColors.borderSubtle,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeckDetailScreen(deckId: deck.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(deck.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                deck.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium,
                              ),
                            ),
                            if (deck.isFavorite) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.push_pin_rounded, size: 14, color: Colors.amber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deck.description.isEmpty ? 'No description provided.' : deck.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      deck.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: deck.isFavorite ? Colors.amber : AppColors.textMuted,
                    ),
                    tooltip: deck.isFavorite ? 'Remove from Starred' : 'Pin to Top (Starred)',
                    onPressed: () {
                      final next = !deck.isFavorite;
                      StudyRepository.instance.toggleFavoriteDeck(deck.id);
                      if (next) {
                        ToastFeedback.showSuccess(
                          context,
                          '"${deck.title}" pinned to top of decks!',
                        );
                      } else {
                        ToastFeedback.showInfo(
                          context,
                          '"${deck.title}" unpinned.',
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    tooltip: 'Delete Deck',
                    onPressed: () async {
                      await StudyRepository.instance.deleteDeck(deck.id);
                      if (context.mounted) {
                        ToastFeedback.showInfo(context, 'Deck "${deck.title}" deleted.');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress and metrics (Clearly distinguishes New Cards vs Scheduled Due Cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${deck.totalCards} cards • ${deck.masteredCount} mastered',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (deck.newCardsCount > 0)
                        Container(
                          margin: EdgeInsets.only(right: deck.scheduledDueCount > 0 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF083344),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${deck.newCardsCount} new',
                            style: AppTypography.badge.copyWith(color: const Color(0xFF67E8F9)),
                          ),
                        ),
                      if (deck.scheduledDueCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${deck.scheduledDueCount} due today',
                            style: AppTypography.badge.copyWith(color: AppColors.danger),
                          ),
                        ),
                      if (deck.newCardsCount == 0 && deck.scheduledDueCount == 0)
                        Text(
                          deck.totalCards == 0 ? 'Add cards to start' : 'All caught up!',
                          style: AppTypography.badge.copyWith(
                            color: deck.totalCards == 0 ? AppColors.textMuted : AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deck.cards.isEmpty ? 0.0 : (deck.masteredCount / deck.cards.length),
                  backgroundColor: AppColors.bgSurface2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateSubjectDialog(BuildContext context, {ValueChanged<Subject>? onCreated}) {
    final nameCtrl = TextEditingController();
    int selectedColor = 0xFF6366F1;
    final colorOptions = [
      0xFF6366F1,
      0xFF3B82F6,
      0xFF10B981,
      0xFFA855F7,
      0xFFF59E0B,
      0xFFEF4444,
      0xFF06B6D4,
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgSurface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              title: const Text('New Subject', style: AppTypography.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g. Data Structures, Networking',
                      filled: true,
                      fillColor: AppColors.bgSurface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Theme Color', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 16, color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Create Subject',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ToastFeedback.showError(context, 'Please enter a subject name.');
                      return;
                    }
                    Navigator.of(ctx).pop();
                    final created = await StudyRepository.instance.addSubject(
                      name: name,
                      colorValue: selectedColor,
                    );
                    if (created != null && onCreated != null) {
                      onCreated(created);
                    }
                    if (context.mounted) {
                      ToastFeedback.showSuccess(context, 'Subject "$name" saved to cloud!');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCreateDeckDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final newSubjectCtrl = TextEditingController();
    final repo = StudyRepository.instance;
    String? selectedSub = repo.subjects.isNotEmpty ? repo.subjects.first.id : null;
    int selectedColor = 0xFF3B82F6;
    final colorOptions = [
      0xFF3B82F6,
      0xFF6366F1,
      0xFF10B981,
      0xFFA855F7,
      0xFFF59E0B,
      0xFFEF4444,
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentSubjects = repo.subjects;
            if (selectedSub == null && currentSubjects.isNotEmpty) {
              selectedSub = currentSubjects.first.id;
            }

            return AlertDialog(
              backgroundColor: AppColors.bgSurface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              title: const Text('Create New Deck', style: AppTypography.titleLarge),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Deck Title',
                        hintText: 'e.g., Computer Architecture',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What concepts are covered?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subject Category', style: AppTypography.labelMedium),
                        if (currentSubjects.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              _openCreateSubjectDialog(
                                context,
                                onCreated: (sub) {
                                  setDialogState(() {
                                    selectedSub = sub.id;
                                  });
                                },
                              );
                            },
                            icon: const Icon(Icons.add, size: 15, color: AppColors.primary),
                            label: const Text(
                              'New Subject',
                              style: TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (currentSubjects.isEmpty)
                      TextField(
                        controller: newSubjectCtrl,
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'New Subject Name',
                          hintText: 'e.g., Networking, Operating Systems',
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedSub,
                        dropdownColor: AppColors.bgSurface2,
                        items: currentSubjects.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSub = val);
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    const Text('Deck Color', style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colorOptions.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Create Deck',
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) {
                      ToastFeedback.showError(context, 'Please enter a deck title.');
                      return;
                    }

                    Navigator.of(ctx).pop();

                    String targetSubjectId = selectedSub ?? '';
                    if (currentSubjects.isEmpty) {
                      final subName = newSubjectCtrl.text.trim().isEmpty
                          ? 'General Studies'
                          : newSubjectCtrl.text.trim();
                      final createdSub = await repo.addSubject(
                        name: subName,
                        colorValue: selectedColor,
                      );
                      if (createdSub != null) {
                        targetSubjectId = createdSub.id;
                      }
                    }

                    await repo.addDeck(
                      title: t,
                      description: descCtrl.text.trim(),
                      subjectId: targetSubjectId,
                      colorValue: selectedColor,
                    );
                    if (context.mounted) {
                      ToastFeedback.showSuccess(context, 'Deck "$t" created and saved to cloud!');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
