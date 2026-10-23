import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/clixa_controller.dart';
import 'clixa_sheets.dart';

/// The "Idea verdict" at the end of a Validate chat. UI only: the content is
/// a placeholder, and the pitch button asks for Pro.
class VerdictCard extends StatelessWidget {
  const VerdictCard({super.key});

  static const _blue = AppColors.onboardingBtnEnd;
  static const _red = Color(0xFFB3261E);

  TextStyle _t(double size, Color color, {FontWeight? w, double? h}) =>
      TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: size + 1,
        fontWeight: w,
        height: h,
        color: color,
      );

  Widget _section(
    String titleKey,
    Color color,
    String mark,
    List<String> keys,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleKey.tr, style: _t(12, color, w: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final k in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(mark, style: _t(12, color, w: FontWeight.w800)),
                  ),
                  Expanded(
                    child: Text(
                      k.tr,
                      style: _t(12.5, AppColors.titleDark, h: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9D3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'clixa_verdict_label'.tr,
                  style: _t(11, AppColors.textGrey, w: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'clixa_verdict_badge'.tr,
                  style: _t(11, _blue, w: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'clixa_verdict_headline'.tr,
            style: _t(15, AppColors.titleDark, w: FontWeight.w800, h: 1.3),
          ),
          _section('clixa_verdict_strengths', _blue, '+', const [
            'clixa_verdict_strength_1',
            'clixa_verdict_strength_2',
          ]),
          _section('clixa_verdict_risks', _red, '!', const [
            'clixa_verdict_risk_1',
            'clixa_verdict_risk_2',
          ]),
          _section('clixa_verdict_next', AppColors.titleDark, '→', const [
            'clixa_verdict_next_1',
            'clixa_verdict_next_2',
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => showClixaUpgrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'clixa_verdict_pitch'.tr,
                        maxLines: 1,
                        style: _t(13, Colors.white, w: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (!ClixaController.to.isPro) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'clixa_pro'.tr,
                        style: _t(
                          9.5,
                          AppColors.crownGold,
                          w: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'clixa_verdict_disclaimer'.tr,
            style: _t(10.5, AppColors.textGrey, h: 1.3),
          ),
        ],
      ),
    );
  }
}
