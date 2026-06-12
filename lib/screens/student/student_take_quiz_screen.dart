import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_question_model.dart';
import '../../services/quiz_service.dart';
import '../../services/telegram_storage_service.dart';

/// Student takes an assigned quiz one question at a time.
/// Receives extra: QuizAssignmentModel
class StudentTakeQuizScreen extends StatefulWidget {
  final QuizAssignmentModel assignment;
  const StudentTakeQuizScreen({super.key, required this.assignment});

  @override
  State<StudentTakeQuizScreen> createState() => _StudentTakeQuizScreenState();
}

class _StudentTakeQuizScreenState extends State<StudentTakeQuizScreen> {
  final _quizService     = QuizService();
  final _telegramService = TelegramStorageService();

  List<QuizQuestionModel> _questions = [];
  int _currentIndex = 0;
  bool _loadingQuestions = false;

  // answers keyed by questionId
  final Map<String, _LocalAnswer> _answers = {};

  // per-question image urls
  final Map<String, String?> _imageUrls = {};

  // per-question timer
  Timer?  _timer;
  int     _secondsLeft = 0;

  // per-question start time
  DateTime? _questionStart;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.assignment.quiz?.questions ?? [];
    if (_questions.isEmpty) {
      _fetchQuestionsFresh();
    } else {
      _preloadImages();
      _startQuestion();
    }
  }

  /// Re-fetches the full assignment (including quiz + questions) when the
  /// model passed to this screen had empty questions (e.g. due to RLS).
  Future<void> _fetchQuestionsFresh() async {
    setState(() => _loadingQuestions = true);
    try {
      final fresh = await _quizService.fetchAssignment(widget.assignment.id);
      if (!mounted) return;
      setState(() {
        _questions        = fresh.quiz?.questions ?? [];
        _loadingQuestions = false;
      });
      _preloadImages();
      _startQuestion();
    } catch (e) {
      if (mounted) setState(() => _loadingQuestions = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  QuizQuestionModel? get _current =>
      _questions.isEmpty ? null : _questions[_currentIndex];

  Future<void> _preloadImages() async {
    for (final q in _questions) {
      if (q.telegramFileId != null) {
        try {
          final info = await _telegramService.getFileInfo(q.telegramFileId!);
          _imageUrls[q.id] = info.url;
        } catch (_) {
          _imageUrls[q.id] = null;
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _startQuestion() {
    _timer?.cancel();
    _questionStart = DateTime.now();
    final q = _current;
    if (q == null) return;

    if (q.timeSeconds != null && q.timeSeconds! > 0) {
      _secondsLeft = q.timeSeconds!;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _secondsLeft--;
          if (_secondsLeft <= 0) _advanceOrFinish();
        });
      });
    } else {
      _secondsLeft = 0;
    }
  }

  void _advance() {
    _timer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _startQuestion();
    }
  }

  void _advanceOrFinish() {
    _timer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _startQuestion();
    } else {
      _submit();
    }
  }

  void _goBack() {
    _timer?.cancel();
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startQuestion();
    }
  }

  int _elapsed() {
    if (_questionStart == null) return 0;
    return DateTime.now().difference(_questionStart!).inSeconds;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      final answers = {
        for (final e in _answers.entries)
          e.key: QuestionAnswer(
            textAnswer:      e.value.textAnswer,
            selected:        e.value.selected,
            timeTakenSeconds: e.value.timeTaken,
          )
      };

      await _quizService.submitAttempt(
        assignmentId: widget.assignment.id,
        questions:    _questions,
        answers:      answers,
      );

      final refreshed = await _quizService.fetchAssignment(widget.assignment.id);

      if (mounted) {
        context.pushReplacement(AppRoutes.studentQuizResult, extra: refreshed);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(l10n.sendQuizFailed(e.toString())),
          backgroundColor: AppColors.error,
        ));
        setState(() => _submitting = false);
      }
    }
  }

  void _showHint(String hint) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(l10n.hintLabel, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content:  Text(hint, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:     Text(l10n.okLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Still loading questions from server
    if (_loadingQuestions) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final q = _current;
    if (q == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: Center(child: Text(l10n.noQuestions)),
      );
    }

    final hasTimer  = q.timeSeconds != null && q.timeSeconds! > 0;
    final imageUrl  = _imageUrls[q.id];
    final ans       = _answers[q.id];
    final isLast    = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme:       const IconThemeData(color: AppColors.surface),
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.assignment.quiz?.title ?? l10n.quiz,
              style: const TextStyle(
                  color:      AppColors.surface,
                  fontWeight: FontWeight.bold,
                  fontSize:   15),
            ),
            Text(
              l10n.questionOutOf(_currentIndex + 1, _questions.length),
              style: const TextStyle(
                  color:    AppColors.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (q.hint != null)
            IconButton(
              icon:     const Icon(Icons.lightbulb_outline,
                  color: AppColors.secondary),
              tooltip:  l10n.hintLabel,
              onPressed: () => _showHint(q.hint!),
            ),
          if (hasTimer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: _CountdownChip(seconds: _secondsLeft),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value:           (_currentIndex + 1) / _questions.length,
            minHeight:       4,
            backgroundColor: AppColors.background,
            valueColor:      const AlwaysStoppedAnimation(AppColors.primary),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color:        AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (q.passageText != null && q.passageText!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Text(
                              q.passageText!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                        Text(
                          q.questionText,
                          style: const TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.bold,
                              color:      AppColors.textPrimary),
                          textDirection: TextDirection.rtl,
                        ),
                        if (imageUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit:            BoxFit.cover,
                              loadingBuilder: (_, child, prog) =>
                                  prog == null
                                      ? child
                                      : const Center(
                                          child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary),
                                        )),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Answer section
                  _buildAnswerSection(q, ans),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            color:   AppColors.surface,
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _goBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      icon:  const Icon(Icons.arrow_back_ios_rounded, size: 14),
                      label: Text(l10n.previousButton),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _submitting
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: isLast ? _submit : _advance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLast
                                ? AppColors.success
                                : AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isLast ? l10n.submitQuizButton : l10n.nextButton,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:   15),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(QuizQuestionModel q, _LocalAnswer? ans) {
    final l10n = AppLocalizations.of(context);
    switch (q.questionType) {
      case 'true_false':
        return Row(
          children: [
            Expanded(
              child: _BigChoiceButton(
                label:    l10n.trueLabel,
                selected: ans?.textAnswer == '0',
                color:    AppColors.success,
                onTap: () {
                  setState(() {
                    _answers[q.id] = _LocalAnswer(
                      textAnswer: '0',
                      timeTaken:  _elapsed(),
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigChoiceButton(
                label:    l10n.falseLabel,
                selected: ans?.textAnswer == '1',
                color:    AppColors.error,
                onTap: () {
                  setState(() {
                    _answers[q.id] = _LocalAnswer(
                      textAnswer: '1',
                      timeTaken:  _elapsed(),
                    );
                  });
                },
              ),
            ),
          ],
        );

      case 'single_choice':
        return Column(
          children: q.options.asMap().entries.map((e) {
            final i = e.key;
            final o = e.value;
            final selected = ans?.textAnswer == '$i';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _answers[q.id] = _LocalAnswer(
                      textAnswer: '$i',
                      timeTaken:  _elapsed(),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:        selected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.25),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          o.text,
                          style: TextStyle(
                            color:      selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'multiple_choice':
        final selected = ans?.selected ?? [];
        return Column(
          children: q.options.asMap().entries.map((e) {
            final i      = e.key;
            final o      = e.value;
            final isChk  = selected.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  final newSel = List<int>.from(selected);
                  if (isChk) {
                    newSel.remove(i);
                  } else {
                    newSel.add(i);
                  }
                  setState(() {
                    _answers[q.id] = _LocalAnswer(
                      selected:  newSel,
                      timeTaken: _elapsed(),
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:        isChk
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChk
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.25),
                      width: isChk ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChk
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: isChk
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          o.text,
                          style: TextStyle(
                            color:      isChk
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isChk
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'fill_blank':
        return TextField(
          textDirection: TextDirection.rtl,
          onChanged:     (v) {
            _answers[q.id] = _LocalAnswer(
              textAnswer: v,
              timeTaken:  _elapsed(),
            );
          },
          controller: TextEditingController(text: ans?.textAnswer ?? '')
            ..selection = TextSelection.collapsed(
                offset: ans?.textAnswer?.length ?? 0),
          decoration: InputDecoration(
            hintText:  l10n.typeAnswerHint,
            filled:    true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 2),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Local answer state ─────────────────────────────────────────────────────────

class _LocalAnswer {
  final String? textAnswer;
  final List<int> selected;
  final int timeTaken;

  const _LocalAnswer({
    this.textAnswer,
    this.selected = const [],
    this.timeTaken = 0,
  });
}

// ── Countdown chip ─────────────────────────────────────────────────────────────

class _CountdownChip extends StatelessWidget {
  final int seconds;
  const _CountdownChip({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUrgent = seconds <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        isUrgent
            ? AppColors.error
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined,
              size: 14, color: AppColors.surface),
          const SizedBox(width: 4),
          Text(
            l10n.secondsAbbr(seconds),
            style: const TextStyle(
                color:      AppColors.surface,
                fontWeight: FontWeight.bold,
                fontSize:   13),
          ),
        ],
      ),
    );
  }
}

// ── Big choice button for true/false ──────────────────────────────────────────

class _BigChoiceButton extends StatelessWidget {
  final String   label;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _BigChoiceButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color:        selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   20,
              color:      selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
