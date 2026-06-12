import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

class LevelProgressIndicator extends StatelessWidget {
  final int level;
  final num progressInLevel; 
  final int totalAttended;

  const LevelProgressIndicator({
    super.key,
    required this.level,
    required this.progressInLevel,
    required this.totalAttended,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progressInLevel / 20.0).clamp(0.0, 1.0);
    final progressStr = progressInLevel is int
        ? progressInLevel.toString()
        : (progressInLevel % 1 == 0
            ? progressInLevel.toInt().toString()
            : progressInLevel.toStringAsFixed(1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius:      AppSpacing.circularProgressRadius,
          lineWidth:   AppSpacing.progressLineWidth,
          percent:     percent,
          animation:   true,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$level', style: AppTextStyles.displayLarge),
              const Text('Level',  style: AppTextStyles.caption),
            ],
          ),
          progressColor:    AppColors.secondary,
          backgroundColor:  AppColors.progressTrack,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(
          '$progressStr / 20 sessions',
          style: AppTextStyles.caption,
        ),
        Text(
          'Total attended: $totalAttended',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
