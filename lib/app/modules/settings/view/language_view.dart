import '../../../core/widgets/tap_target.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/app_strings.dart';
import '../../../core/translations/tr_extension.dart';

/// A language choice in the Language screen.
class LanguageOption {
  const LanguageOption(this.tag, this.nativeName);

  final String tag;

  /// The language's name in its own script (never translated).
  final String nativeName;
}

const List<LanguageOption> kLanguageOptions = [
  LanguageOption('en', 'English'),
  LanguageOption('ar', 'العربية'),
  LanguageOption('hi', 'हिन्दी'),
  LanguageOption('af', 'Afrikaans'),
  LanguageOption('es', 'Español'),
  LanguageOption('pt', 'Português'),
  LanguageOption('id', 'Bahasa Indonesia'),
  LanguageOption('zh', '中文'),
  LanguageOption('ko', '한국어'),
  LanguageOption('ja', '日本語'),
  LanguageOption('it', 'Italiano'),
  LanguageOption('fr', 'Français'),
  LanguageOption('de', 'Deutsch'),
  LanguageOption('ru', 'Русский'),
];

const Map<String, String> _unlistedNames = {'ur': 'اردو'};

/// The tag of the language in use: the user's pick, or the device language
/// the app resolved to on first launch.
String _activeTag() => AppStrings.savedChoice ?? AppStrings.language;

/// Native name of the language currently in use, for the Settings card.
String currentLanguageLabel() {
  final tag = _activeTag();
  for (final o in kLanguageOptions) {
    if (o.tag == tag) return o.nativeName;
  }
  // Not in the picker (e.g. Urdu on an Urdu phone).
  return _unlistedNames[tag] ?? tag;
}

class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar (same as Settings).
            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TapTarget(child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.titleDark,
                      ),
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      constraints: const BoxConstraints(),
                    )),
                  ),
                  Text(
                    'settings_language_title'.tr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ],
              ),
            ),

            // Options. Rebuilds when the language changes so the check mark
            // moves immediately.
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: AppStrings.changes,
                builder: (context, _, __) {
                  final active = _activeTag();
                  return ListView.separated(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      8,
                      20,
                      24,
                    ),
                    itemCount: kLanguageOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = kLanguageOptions[i];
                      return _LanguageRow(
                        option: o,
                        selected: o.tag == active,
                        onTap: () => AppStrings.setLanguage(o.tag),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.contactsLavenderBg : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.contactsLavenderBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              // Leading badge with the language code.
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option.tag.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Language name (own script).
              Expanded(
                child: Text(
                  option.nativeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.contactsTitleDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Radio-style indicator.
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.dotInactive,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}