import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/student_invite_service.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({super.key});

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _whatsappCtrl  = TextEditingController();
  final _messengerCtrl  = TextEditingController();

  String? _country;
  int     _level         = 1;
  double  _lessonInLevel = 0.0;
  double  _totalInLevel  = 20.0;
  bool    _isPaid        = false;
  bool    _loading      = false;
  bool    _showPass     = false;
  bool    _showConfirm  = false;
  String _studySystem   = 'classes';
  double  _studyBalance  = 20.0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _whatsappCtrl.dispose();
    _messengerCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final creds = await StudentInviteService().createStudentAccount(
        fullName:      _nameCtrl.text.trim(),
        email:         _emailCtrl.text.trim().toLowerCase(),
        password:      _passCtrl.text,
        country:       _country,
        whatsapp:      _whatsappCtrl.text.trim().isEmpty
            ? null
            : _whatsappCtrl.text.trim(),
        messengerLink: _messengerCtrl.text.trim().isEmpty
            ? null
            : _messengerCtrl.text.trim(),
        level:         _level,
        lessonInLevel: _lessonInLevel,
        totalInLevel:  _totalInLevel,
        isPaid:        _isPaid,
        studySystem:   _studySystem,
        studyBalance:  _studyBalance,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      await _showSuccessDialog(creds);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(StudentCredentials creds) async {
    await showDialog<void>(
      context:            context,
      barrierDismissible: false,
      builder: (ctx) => _CredentialsDialog(creds: creds),
    );
    if (mounted) context.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme:       const IconThemeData(color: AppColors.surface),
        title: Text(
          l10n.createStudentAccount,
          style: const TextStyle(
            color:      AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: [
            const SizedBox(height: AppSpacing.medium),

            // ── Icon header ─────────────────────────────────────────
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color:  AppColors.primary.withValues(alpha: 0.10),
                  shape:  BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_outlined,
                  color: AppColors.primary,
                  size:  40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.enterStudentDetails,
                style: const TextStyle(
                  color:    AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.large),

            // ── Section: Basic info ───────────────────────────────
            _SectionLabel(label: l10n.loginDetailsSection),
            const SizedBox(height: AppSpacing.small),
            _FormCard(
              children: [
                _FieldTile(
                  controller:   _nameCtrl,
                  label:        l10n.fullName,
                  icon:         Icons.person_outline,
                  rtl:          true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.studentNameRequired
                      : null,
                ),
                _divider(),
                _FieldTile(
                  controller:   _emailCtrl,
                  label:        l10n.email,
                  icon:         Icons.email_outlined,
                  keyboard:     TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.emailRequired;
                    }
                    final ok = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(v.trim());
                    return ok ? null : l10n.invalidEmail;
                  },
                ),
                _divider(),
                // Password
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4,
                  ),
                  child: TextFormField(
                    controller:     _passCtrl,
                    obscureText:    !_showPass,
                    textDirection:  TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText:  l10n.password,
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size:  20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                      border:        InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.passwordRequired;
                      if (v.length < 6) return l10n.passwordMinLength;
                      return null;
                    },
                  ),
                ),
                _divider(),
                // Confirm password
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4,
                  ),
                  child: TextFormField(
                    controller:    _confirmCtrl,
                    obscureText:   !_showConfirm,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText:  l10n.confirmPassword,
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primary,
                        size:  20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      border:        InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v != _passCtrl.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.medium),



            const SizedBox(height: AppSpacing.medium),

            // ── Section: Location & contact ─────────────────────────
            _SectionLabel(label: l10n.countryAndContactSection),
            const SizedBox(height: AppSpacing.small),
            _FormCard(
              children: [
                // Country dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 2,
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _country,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:  l10n.selectStudentCountry,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.primary,
                        size:  20,
                      ),
                      border:        InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    hint: Text(
                      l10n.selectStudentCountry,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    items: _kCountries
                        .map((c) => DropdownMenuItem(value: c, child: Text(getLocalizedCountry(context, c))))
                        .toList(),
                    onChanged: (v) => setState(() => _country = v),
                  ),
                ),
                _divider(),
                // WhatsApp number
                _FieldTile(
                  controller: _whatsappCtrl,
                  label:      l10n.whatsappNumber,
                  icon:       Icons.chat_outlined,
                  keyboard:   TextInputType.phone,
                  hint:       l10n.whatsappNumberHint,
                  iconColor:  const Color(0xFF25D366),
                ),
                _divider(),
                // Messenger link
                _FieldTile(
                  controller: _messengerCtrl,
                  label:      l10n.messengerLinkOptional,
                  icon:       Icons.chat_bubble_outline,
                  hint:       'https://m.me/username',
                  keyboard:   TextInputType.url,
                  rtl:        false,
                ),
              ],
            ),

            // ── Section: Level & Lesson ──────────────────────────
            _SectionLabel(
              label: l10n.levelAndInitialLessonSection,
            ),
            const SizedBox(height: AppSpacing.small),
            _FormCard(
              children: [
                // Study system selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: DropdownButtonFormField<String>(
                    initialValue: _studySystem,
                    decoration: InputDecoration(
                      labelText: getStudySystemLabel(context),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primary,
                        size:  20,
                      ),
                      border:        InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'classes',
                        child: Text(getClassesLabel(context)),
                      ),
                      DropdownMenuItem(
                        value: 'hours',
                        child: Text(getHoursLabel(context)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _studySystem = val;
                          _studyBalance = (_totalInLevel - _lessonInLevel).clamp(0.0, 99999.0);
                        });
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 48, color: AppColors.progressTrack),
                // Level picker
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.signal_cellular_alt,
                        color: AppColors.primary,
                        size:  20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.level,
                          style: const TextStyle(
                            color:      AppColors.textSecondary,
                            fontSize:   14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _level > 1
                            ? () => setState(() => _level--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primary,
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$_level',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.bold,
                            color:      AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => _level++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primary,
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 48, color: AppColors.progressTrack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextFormField(
                    key: ValueKey('completed_$_studySystem'),
                    initialValue: '${_lessonInLevel.toInt()}',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _studySystem == 'hours'
                          ? (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'عدد الساعات المكتملة في المستوى'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Seviyedeki Tamamlanan Saatler'
                                  : 'Completed Hours in Level')
                          : (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'عدد الحصص المكتملة في المستوى'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Seviyedeki Tamamlanan Dersler'
                                  : 'Completed Classes in Level'),
                      prefixIcon: const Icon(Icons.menu_book_outlined, color: AppColors.secondary),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          _lessonInLevel = parsed;
                          _studyBalance = (_totalInLevel - _lessonInLevel).clamp(0.0, 99999.0);
                        });
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 48, color: AppColors.progressTrack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextFormField(
                    key: ValueKey('total_$_studySystem'),
                    initialValue: '${_totalInLevel.toInt()}',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _studySystem == 'hours'
                          ? (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إجمالي ساعات المستوى'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Seviyedeki Toplam Saat'
                                  : 'Total Hours in Level')
                          : (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إجمالي حصص المستوى'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Seviyedeki Toplam Ders'
                                  : 'Total Classes in Level'),
                      prefixIcon: Icon(
                        _studySystem == 'hours' ? Icons.alarm_on_outlined : Icons.class_outlined,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          _totalInLevel = parsed;
                          _studyBalance = (_totalInLevel - _lessonInLevel).clamp(0.0, 99999.0);
                        });
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 48, color: AppColors.progressTrack),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextFormField(
                    key: ValueKey('balance_${_studySystem}_$_studyBalance'),
                    initialValue: _studyBalance % 1 == 0 ? '${_studyBalance.toInt()}' : '$_studyBalance',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _studySystem == 'hours'
                          ? (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الرصيد الابتدائي للساعات'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Başlangıç Saat Bakiyesi'
                                  : 'Initial Hours Balance')
                          : (Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الرصيد الابتدائي للحصص'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Başlangıç Ders Bakiyesi'
                                  : 'Initial Classes Balance'),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondary),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          _studyBalance = parsed;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.medium),

            // ── Section: Payment status ──────────────────────────
            _SectionLabel(label: l10n.initialCoursePaymentStatus),
            const SizedBox(height: AppSpacing.small),
            _FormCard(
              children: [
                SwitchListTile(
                  title: Text(
                    l10n.paidInAdvance,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isPaid ? l10n.accountActivationPaid : l10n.accountActivationUnpaid,
                    style: TextStyle(
                      color: _isPaid ? AppColors.success : AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                  value: _isPaid,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isPaid = v),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.large),

            // ── Submit ─────────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add, size: 20),
                label: Text(
                  _loading ? l10n.creatingAccount : l10n.createAccount,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────────────────────

Widget _divider() => const Divider(
      height: 1, indent: 56, color: AppColors.progressTrack,
    );

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard  = TextInputType.text,
    this.rtl       = false,
    this.hint,
    this.validator,
    this.iconColor,
  });
  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType              keyboard;
  final bool                       rtl;
  final String?                    hint;
  final String? Function(String?)? validator;
  final Color?                     iconColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller:    controller,
          keyboardType:  keyboard,
          validator:     validator,
          textAlign:     rtl ? TextAlign.right : TextAlign.left,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText:    label,
            labelStyle:   const TextStyle(color: AppColors.textSecondary),
            hintText:     hint,
            hintStyle:    const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
            ),
            prefixIcon:   Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
            border:        InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      );
}

// ── Success dialog ───────────────────────────────────────────────────────────────────

class _CredentialsDialog extends StatelessWidget {
  const _CredentialsDialog({required this.creds});
  final StudentCredentials creds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 26),
          const SizedBox(width: 8),
          Text(
            l10n.accountCreatedSuccess,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color:      AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shareDetailsWithStudent,
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            _CredRow(label: l10n.credName,       value: creds.fullName),
            const SizedBox(height: 6),
            _CredRow(label: l10n.credEmail,      value: creds.email, mono: true),
            const SizedBox(height: 6),
            _CredRow(
              label: l10n.password,
              value: creds.password,
              mono:  true,
            ),
            if (creds.country != null && creds.country!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _CredRow(label: l10n.countryLabel, value: getLocalizedCountry(context, creds.country!)),
            ],
            if (creds.whatsapp != null && creds.whatsapp!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _CredRow(
                label: l10n.whatsappLabel,
                value: creds.whatsapp!,
                mono:  true,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: creds.shareText),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.copiedToClipboard),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon:  const Icon(Icons.copy, size: 18),
                label: Text(l10n.copyLoginDetails),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.close,
            style: const TextStyle(
              color:      AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.label,
    required this.value,
    this.mono = false,
  });
  final String label;
  final String value;
  final bool   mono;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textDirection:
                    mono ? TextDirection.ltr : TextDirection.rtl,
                style: TextStyle(
                  fontWeight:    FontWeight.bold,
                  fontSize:      13,
                  color:         AppColors.textPrimary,
                  fontFamily:    mono ? 'monospace' : null,
                  letterSpacing: mono ? 1.2 : 0,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Country list ──────────────────────────────────────────────────────────────────────

const List<String> _kCountries = [
  'المملكة العربية السعودية',
  'مصر',
  'الأردن',
  'فلسطين',
  'الإمارات العربية المتحدة',
  'الكويت',
  'البحرين',
  'قطر',
  'عُمان',
  'اليمن',
  'العراق',
  'سوريا',
  'لبنان',
  'ليبيا',
  'تونس',
  'الجزائر',
  'المغرب',
  'السودان',
  'الصومال',
  'موريتانيا',
  'تركيا',
  'باكستان',
  'ماليزيا',
  'إندونيسيا',
  'المملكة المتحدة',
  'ألمانيا',
  'فرنسا',
  'الولايات المتحدة الأمريكية',
  'كندا',
  'أستراليا',
  'دولة أخرى',
];

String getLocalizedCountry(BuildContext context, String countryName) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Saudi Arabia';
      case 'مصر': return 'Egypt';
      case 'الأردن': return 'Jordan';
      case 'فلسطين': return 'Palestine';
      case 'الإمارات العربية المتحدة': return 'United Arab Emirates';
      case 'الكويت': return 'Kuwait';
      case 'البحرين': return 'Bahrain';
      case 'قطر': return 'Qatar';
      case 'عُمان': return 'Oman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Iraq';
      case 'سوريا': return 'Syria';
      case 'لبنان': return 'Lebanon';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunisia';
      case 'الجزائر': return 'Algeria';
      case 'المغرب': return 'Morocco';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somalia';
      case 'موريتانيا': return 'Mauritania';
      case 'تركيا': return 'Turkey';
      case 'باكستان': return 'Pakistan';
      case 'ماليزيا': return 'Malaysia';
      case 'إندونيسيا': return 'Indonesia';
      case 'المملكة المتحدة': return 'United Kingdom';
      case 'ألمانيا': return 'Germany';
      case 'فرنسا': return 'France';
      case 'الولايات المتحدة الأمريكية': return 'United States';
      case 'كندا': return 'Canada';
      case 'أستراليا': return 'Australia';
      case 'دولة أخرى': return 'Other Country';
      default: return countryName;
    }
  } else if (locale == 'tr') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Suudi Arabistan';
      case 'مصر': return 'Mısır';
      case 'الأردن': return 'Ürdün';
      case 'فلسطين': return 'Filistin';
      case 'الإمارات العربية المتحدة': return 'Birleşik Arap Emirlikleri';
      case 'الكويت': return 'Kuveyt';
      case 'البحرين': return 'Bahreyn';
      case 'قطر': return 'Katar';
      case 'عُمان': return 'Umman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Irak';
      case 'سوريا': return 'Suriye';
      case 'لبنان': return 'Lübnan';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunus';
      case 'الجزائر': return 'Cezayir';
      case 'المغرب': return 'Fas';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somali';
      case 'موريتانيا': return 'Moritanya';
      case 'تركيا': return 'Türkiye';
      case 'باكستان': return 'Pakistan';
      case 'ماليزيا': return 'Malezya';
      case 'إندونيسيا': return 'Endonezya';
      case 'المملكة المتحدة': return 'Birleşik Krallık';
      case 'ألمانيا': return 'Almanya';
      case 'فرنسا': return 'Fransa';
      case 'الولايات المتحدة الأمريكية': return 'Amerika Birleşik Devletleri';
      case 'كندا': return 'Kanada';
      case 'أستراليا': return 'Avustralya';
      case 'دولة أخرى': return 'Diğer Ülke';
      default: return countryName;
    }
  }
  return countryName;
}

String getStudySystemLabel(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar') return 'نظام الدراسة';
  if (locale == 'tr') return 'Çalışma Sistemi';
  return 'Study System';
}

String getClassesLabel(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar') return 'حصص';
  if (locale == 'tr') return 'Dersler';
  return 'Classes';
}

String getHoursLabel(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar') return 'ساعات';
  if (locale == 'tr') return 'Saatler';
  return 'Hours';
}

String getInitialBalanceLabel(BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'ar') return 'الرصيد الابتدائي';
  if (locale == 'tr') return 'Başlangıç Bakiyesi';
  return 'Initial Balance';
}

