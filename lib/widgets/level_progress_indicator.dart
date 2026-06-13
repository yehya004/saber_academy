import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';
import '../l10n/app_localizations.dart';

class LevelProgressIndicator extends StatelessWidget {
  final int level;
  final num progressInLevel; 
  final num totalInLevel;

  const LevelProgressIndicator({
    super.key,
    required this.level,
    required this.progressInLevel,
    required this.totalInLevel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (totalInLevel > 0.0 ? (progressInLevel / totalInLevel) : 0.0).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context);

    return CircularPercentIndicator(
      radius:            AppSpacing.circularProgressRadius,
      lineWidth:         AppSpacing.progressLineWidth,
      percent:           percent,
      animation:         true,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$level', style: AppTextStyles.displayLarge),
          Text(l10n.level, style: AppTextStyles.caption),
        ],
      ),
      progressColor:     AppColors.secondary,
      backgroundColor:   AppColors.progressTrack,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }
}
