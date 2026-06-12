import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Pill-shaped badge used on homework cards and session cards.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'pending'   => (const Color(0xFFFFF9C4), const Color(0xFFFF8F00), Localizations.localeOf(context).languageCode == 'ar' ? 'قيد الانتظار' : 'Pending'),
      'submitted' => (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Localizations.localeOf(context).languageCode == 'ar' ? 'تم التسليم' : 'Submitted'),
      'corrected' => (const Color(0xFFE8F5E9), AppColors.success,       Localizations.localeOf(context).languageCode == 'ar' ? 'تم التصحيح' : 'Corrected'),
      'present'   => (const Color(0xFFE8F5E9), AppColors.success,       Localizations.localeOf(context).languageCode == 'ar' ? 'حاضر' : 'Present'),
      'absent'    => (const Color(0xFFFFEBEE), AppColors.error,         Localizations.localeOf(context).languageCode == 'ar' ? 'غائب' : 'Absent'),
      'late'      => (const Color(0xFFFFF3E0), Colors.orange.shade800, Localizations.localeOf(context).languageCode == 'ar' ? 'متأخر' : 'Late'),
      _           => (Colors.grey.shade100,    Colors.grey,             status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      fg,
          fontSize:   12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
