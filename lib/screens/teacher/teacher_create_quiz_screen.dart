import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_option_model.dart';
import '../../models/quiz_question_model.dart';
import '../../services/quiz_service.dart';
import '../../services/telegram_storage_service.dart';

/// Full screen for creating or editing a quiz with its questions.
/// Create mode: pass teacherId only.
/// Edit mode: pass teacherId + quiz.
class TeacherCreateQuizScreen extends StatefulWidget {
  final String teacherId;
  final QuizModel? quiz; // non-null = edit mode
  const TeacherCreateQuizScreen({
    super.key,
    required this.teacherId,
    this.quiz,
  });

  @override
  State<TeacherCreateQuizScreen> createState() =>
      _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends State<TeacherCreateQuizScreen> {
  final _service = QuizService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_QuizQuestionDraft> _questions = [];
  bool _saving = false;

  bool get _isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final q = widget.quiz;
    if (q != null) {
      _titleCtrl.text = q.title;
      _descCtrl.text = q.description ?? '';
      for (final qq in q.questions) {
        _questions.add(_QuizQuestionDraft(
          questionText: qq.questionText,
          questionType: qq.questionType,
          options: qq.options,
          correctAnswer: qq.correctAnswer,
          telegramFileId: qq.telegramFileId,
          hint: qq.hint,
          passageText: qq.passageText,
          points: qq.points,
          timeSeconds: qq.timeSeconds,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _addQuestion() async {
    final draft = await showDialog<_QuizQuestionDraft>(
      context: context,
      builder: (_) => _QuestionEditorDialog(orderIndex: _questions.length),
    );
    if (draft != null) setState(() => _questions.add(draft));
  }

  Future<void> _editQuestion(int index) async {
    final draft = await showDialog<_QuizQuestionDraft>(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        orderIndex: index,
        initial: _questions[index],
      ),
    );
    if (draft != null) setState(() => _questions[index] = draft);
  }

  Future<void> _importFromBank() async {
    final uid = widget.teacherId;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    List<QuizQuestionModel> allQuestions = [];
    try {
      final quizzes = await _service.fetchTeacherQuizzes(uid);
      allQuestions = quizzes.expand((q) => q.questions).toList();
      if (mounted) Navigator.pop(context); // Pop loading spinner
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading spinner
        _showError('${l10n.failedToLoadData}: $e');
        return;
      }
    }

    if (allQuestions.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importFromQuestionBank),
            content: Text(l10n.noQuestionsToImport),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.okLabel),
              )
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final selectedQuestions = await showDialog<List<QuizQuestionModel>>(
      context: context,
      builder: (ctx) => _QuestionImportDialog(questions: allQuestions),
    );

    if (selectedQuestions != null && selectedQuestions.isNotEmpty) {
      setState(() {
        for (final q in selectedQuestions) {
          _questions.add(_QuizQuestionDraft(
            questionText:   q.questionText,
            questionType:   q.questionType,
            options:        q.options,
            correctAnswer:  q.correctAnswer,
            telegramFileId: q.telegramFileId,
            hint:           q.hint,
            passageText:    q.passageText,
            points:         q.points,
            timeSeconds:    q.timeSeconds,
          ));
        }
      });
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showError(l10n.enterQuizTitleError);
      return;
    }
    if (_questions.isEmpty) {
      _showError(l10n.pleaseAddQuestions);
      return;
    }

    setState(() => _saving = true);
    try {
      final String quizId;
      if (_isEditing) {
        quizId = widget.quiz!.id;
        await _service.updateQuiz(
          id: quizId,
          title: title,
          description: _descCtrl.text.trim(),
        );
        await _service.deleteAllQuestions(quizId);
      } else {
        quizId = await _service.createQuiz(
          teacherId: widget.teacherId,
          title: title,
          description: _descCtrl.text.trim(),
        );
      }

      final questions = _questions.asMap().entries.map((e) {
        final d = e.value;
        return QuizQuestionModel(
          id: '',
          quizId: quizId,
          questionText: d.questionText,
          questionType: d.questionType,
          options: d.options,
          correctAnswer: d.correctAnswer,
          telegramFileId: d.telegramFileId,
          hint: d.hint,
          passageText: d.passageText,
          points: d.points,
          timeSeconds: d.timeSeconds,
          orderIndex: e.key,
        );
      }).toList();

      await _service.insertQuestions(quizId, questions);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('${l10n.profileSaveError}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'true_false' => l10n.questionTypeTrueFalse,
        'single_choice' => l10n.questionTypeSingleChoice,
        'multiple_choice' => l10n.questionTypeMultipleChoice,
        'fill_blank' => l10n.questionTypeFillBlank,
        _ => type,
      };

  IconData _typeIcon(String type) => switch (type) {
        'true_false' => Icons.check_circle_outline,
        'single_choice' => Icons.radio_button_checked_outlined,
        'multiple_choice' => Icons.check_box_outlined,
        'fill_blank' => Icons.edit_outlined,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          _isEditing ? l10n.editQuizTitle : l10n.createQuizTitle,
          style: const TextStyle(
              color: AppColors.surface, fontWeight: FontWeight.bold),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => _save(l10n),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.surface),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.saveLabel,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addQuestionButton,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, AppSpacing.medium, AppSpacing.medium, 100),
        children: [
          // ── Quiz info ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: '${l10n.quizNameLabel} *',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.quizDescriptionOptional,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.medium),

          // ── Questions section header ───────────────────────────
          Row(
            children: [
              Text(
                l10n.questionsSection,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              if (_questions.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_questions.length}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _importFromBank,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(
                  l10n.importFromBankButton,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),

          // ── Questions list ─────────────────────────────────────
          if (_questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.15),
                    style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 40,
                        color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(l10n.noQuestionsYet,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              onReorderItem: (o, n) {
                setState(() {
                  final item = _questions.removeAt(o);
                  _questions.insert(n, item);
                });
              },
              itemBuilder: (ctx, i) {
                final q = _questions[i];
                return _QuestionListTile(
                  key: ValueKey(i),
                  index: i,
                  draft: q,
                  typeLabel: _typeLabel(q.questionType, l10n),
                  typeIcon: _typeIcon(q.questionType),
                  onEdit: () => _editQuestion(i),
                  onDelete: () => setState(() => _questions.removeAt(i)),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Question list tile ─────────────────────────────────────────────────────────

class _QuestionListTile extends StatelessWidget {
  final int index;
  final _QuizQuestionDraft draft;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionListTile({
    super.key,
    required this.index,
    required this.draft,
    required this.typeLabel,
    required this.typeIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          const Icon(Icons.drag_handle_rounded,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          // Number
          Text('${index + 1}.',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 8),
          Icon(typeIcon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
                if (draft.passageText != null && draft.passageText!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '📎 ${draft.passageText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(typeLabel,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(l10n.pointsLabel(draft.points),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    if (draft.timeSeconds != null) ...[
                      const SizedBox(width: 8),
                      Text(l10n.secondsAbbr(draft.timeSeconds!),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primary),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Local draft model ──────────────────────────────────────────────────────────

class _QuizQuestionDraft {
  String questionText;
  String questionType;
  List<QuizOptionModel> options;
  String? correctAnswer;
  String? telegramFileId;
  String? hint;
  String? passageText;
  int points;
  int? timeSeconds;

  _QuizQuestionDraft({
    required this.questionText,
    required this.questionType,
    required this.options,
    this.correctAnswer,
    this.telegramFileId,
    this.hint,
    this.passageText,
    required this.points,
    this.timeSeconds,
  });
}

// ── Question editor dialog ─────────────────────────────────────────────────────

class _QuestionEditorDialog extends StatefulWidget {
  final int orderIndex;
  final _QuizQuestionDraft? initial;

  const _QuestionEditorDialog({required this.orderIndex, this.initial});

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  final _telegram = TelegramStorageService();
  final _passageCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _correctCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '1');
  final _timeCtrl = TextEditingController();

  String _type = 'single_choice';
  String? _fileId;
  bool _uploading = false;

  // Options for choice-based questions
  final List<_OptionDraft> _options = [];
  // For true_false: 0 = صح is correct, 1 = خطأ is correct
  int _tfCorrect = 0;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _type = ini.questionType;
      _passageCtrl.text = ini.passageText ?? '';
      _questionCtrl.text = ini.questionText;
      _correctCtrl.text = ini.correctAnswer ?? '';
      _hintCtrl.text = ini.hint ?? '';
      _pointsCtrl.text = ini.points.toString();
      _timeCtrl.text = ini.timeSeconds?.toString() ?? '';
      _fileId = ini.telegramFileId;

      if (_type == 'true_false') {
        final idx = ini.options.indexWhere((o) => o.isCorrect);
        _tfCorrect = idx >= 0 ? idx : 0;
      } else {
        _options
            .addAll(ini.options.map((o) => _OptionDraft(o.text, o.isCorrect)));
      }
    } else {
      // Default 2 options for single_choice
      _options.addAll([_OptionDraft('', false), _OptionDraft('', false)]);
    }
  }

  @override
  void dispose() {
    _passageCtrl.dispose();
    _questionCtrl.dispose();
    _correctCtrl.dispose();
    _hintCtrl.dispose();
    _pointsCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _switchType(String t) {
    setState(() {
      _type = t;
      if (t == 'single_choice' || t == 'multiple_choice') {
        if (_options.isEmpty) {
          _options.addAll([_OptionDraft('', false), _OptionDraft('', false)]);
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final id = await _telegram.uploadFile(File(path));
      setState(() => _fileId = id);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.imageUploadFailed),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit(AppLocalizations l10n) {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.enterQuestionTextError),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final pts = int.tryParse(_pointsCtrl.text.trim()) ?? 1;
    final sec = int.tryParse(_timeCtrl.text.trim());
    final hint =
        _hintCtrl.text.trim().isNotEmpty ? _hintCtrl.text.trim() : null;

    List<QuizOptionModel> builtOptions = [];
    String? correctAnswer;

    switch (_type) {
      case 'true_false':
        builtOptions = [
          QuizOptionModel(text: 'صح', isCorrect: _tfCorrect == 0),
          QuizOptionModel(text: 'خطأ', isCorrect: _tfCorrect == 1),
        ];
      case 'single_choice':
        if (_options.every((o) => !o.isCorrect)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.selectOneCorrectAnswerError),
            backgroundColor: AppColors.error,
          ));
          return;
        }
        builtOptions = _options
            .map((o) => QuizOptionModel(text: o.text, isCorrect: o.isCorrect))
            .toList();
      case 'multiple_choice':
        if (_options.every((o) => !o.isCorrect)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.selectAtLeastOneCorrectAnswerError),
            backgroundColor: AppColors.error,
          ));
          return;
        }
        builtOptions = _options
            .map((o) => QuizOptionModel(text: o.text, isCorrect: o.isCorrect))
            .toList();
      case 'fill_blank':
        correctAnswer = _correctCtrl.text.trim();
        if (correctAnswer.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.enterCorrectAnswerFillBlankError),
            backgroundColor: AppColors.error,
          ));
          return;
        }
    }

    final passage = _passageCtrl.text.trim().isNotEmpty ? _passageCtrl.text.trim() : null;

    Navigator.pop(
      context,
      _QuizQuestionDraft(
        questionText: text,
        questionType: _type,
        options: builtOptions,
        correctAnswer: correctAnswer,
        telegramFileId: _fileId,
        hint: hint,
        passageText: passage,
        points: pts < 1 ? 1 : pts,
        timeSeconds: sec != null && sec > 0 ? sec : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChoice = _type == 'single_choice' || _type == 'multiple_choice';
    final l10n = AppLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.initial != null ? l10n.edit : l10n.addQuestionButton,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Type selector ─────────────────────────────────────
              Text(l10n.questionTypeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeChip(
                      label: l10n.questionTypeTrueFalse,
                      value: 'true_false',
                      selected: _type,
                      onTap: _switchType),
                  _TypeChip(
                      label: l10n.questionTypeSingleChoice,
                      value: 'single_choice',
                      selected: _type,
                      onTap: _switchType),
                  _TypeChip(
                      label: l10n.questionTypeMultipleChoice,
                      value: 'multiple_choice',
                      selected: _type,
                      onTap: _switchType),
                  _TypeChip(
                      label: l10n.questionTypeFillBlank,
                      value: 'fill_blank',
                      selected: _type,
                      onTap: _switchType),
                ],
              ),
              const SizedBox(height: 16),

              // ── Passage text ──────────────────────────────────────
              Text(l10n.passageLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _passageCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.passageHint,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Question text ─────────────────────────────────────
              Text('${l10n.questionTextLabel} *',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _questionCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.questionTextHint,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Image upload ──────────────────────────────────────
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.image_outlined, size: 16),
                    label: Text(_fileId != null ? l10n.imageUploadChange : l10n.imageUploadAdd,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  if (_fileId != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 4),
                    Text(l10n.imageUploaded,
                        style:
                            const TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Options (choice types) ────────────────────────────
              if (_type == 'true_false') ...[
                Text(l10n.chooseCorrectOption,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TFButton(
                        label: l10n.trueLabel,
                        selected: _tfCorrect == 0,
                        color: AppColors.success,
                        onTap: () => setState(() => _tfCorrect = 0)),
                    const SizedBox(width: 12),
                    _TFButton(
                        label: l10n.falseLabel,
                        selected: _tfCorrect == 1,
                        color: AppColors.error,
                        onTap: () => setState(() => _tfCorrect = 1)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (isChoice) ...[
                Row(
                  children: [
                    Text(l10n.optionsSection,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _options.add(_OptionDraft('', false))),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addOptionLabel,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._options.asMap().entries.map((e) {
                  final i = e.key;
                  final o = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Correct toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_type == 'single_choice') {
                                for (var j = 0; j < _options.length; j++) {
                                  _options[j] =
                                      _OptionDraft(_options[j].text, j == i);
                                }
                              } else {
                                _options[i] =
                                    _OptionDraft(o.text, !o.isCorrect);
                              }
                            });
                          },
                          child: Icon(
                            _type == 'single_choice'
                                ? (o.isCorrect
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked)
                                : (o.isCorrect
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                            color: o.isCorrect
                                ? AppColors.success
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            textDirection: TextDirection.rtl,
                            controller: TextEditingController(text: o.text)
                              ..selection = TextSelection.collapsed(
                                  offset: o.text.length),
                            onChanged: (v) =>
                                _options[i] = _OptionDraft(v, o.isCorrect),
                            decoration: InputDecoration(
                              hintText: l10n.optionIndexHint(i + 1),
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (_options.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18, color: AppColors.error),
                            onPressed: () =>
                                setState(() => _options.removeAt(i)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              if (_type == 'fill_blank') ...[
                Text(l10n.correctAnswerFillBlank,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _correctCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: l10n.correctAnswerFillBlankHint,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Points + time ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.pointsValueLabel} *',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pointsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.timeSecondsOptional,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _timeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: l10n.timeSecondsHint,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Hint ─────────────────────────────────────────────
              Text(l10n.hintOptional,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _hintCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: l10n.hintPlaceholder,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textSecondary),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submit(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                      ),
                      child: Text(
                          widget.initial != null ? l10n.saveEditLabel : l10n.addLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _OptionDraft {
  String text;
  bool isCorrect;
  _OptionDraft(this.text, this.isCorrect);
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.surface : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TFButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionImportDialog extends StatefulWidget {
  final List<QuizQuestionModel> questions;
  const _QuestionImportDialog({required this.questions});

  @override
  State<_QuestionImportDialog> createState() => _QuestionImportDialogState();
}

class _QuestionImportDialogState extends State<_QuestionImportDialog> {
  final List<QuizQuestionModel> _selected = [];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = widget.questions.where((q) {
      if (_searchQuery.trim().isEmpty) return true;
      return q.questionText.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          (q.passageText != null && q.passageText!.toLowerCase().contains(_searchQuery.trim().toLowerCase()));
    }).toList();

    // Deduplicate question texts to make search clean
    final seen = <String>{};
    final unique = filtered.where((q) => seen.add(q.questionText)).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.importFromQuestionBank,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: l10n.searchQuestionsHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: unique.isEmpty
                  ? Center(child: Text(l10n.noQuestionsYet, style: const TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: unique.length,
                      itemBuilder: (ctx, idx) {
                        final q = unique[idx];
                        final isSel = _selected.contains(q);
                        return CheckboxListTile(
                          value: isSel,
                          activeColor: AppColors.primary,
                          title: Text(
                            q.questionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${q.questionType} · ${l10n.pointsLabel(q.points)}${q.passageText != null ? ' · [${l10n.passageLabel}]' : ''}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(q);
                              } else {
                                _selected.remove(q);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                    ),
                    child: Text(l10n.importSelectedButton(_selected.length)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
