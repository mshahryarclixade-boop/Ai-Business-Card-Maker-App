import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LogoOptionCard extends StatelessWidget {
  const LogoOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 92,
        decoration: BoxDecoration(
          color: selected ? AppColors.profileOptionSelectedBg : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.profileStepActive
                : AppColors.profileFieldBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.profileStepActive),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: AppColors.splashTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCardShell extends StatelessWidget {
  const _LogoCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.onboardingCardShadow,
            offset: Offset(0, 0.74),
            blurRadius: 32.53,
          ),
        ],
      ),
      child: child,
    );
  }
}

class LogoPreviewCard extends StatelessWidget {
  const LogoPreviewCard({
    super.key,
    required this.bytes,
    required this.name,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _LogoCardShell(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.94),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.profileHintBg,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 22 / 18,
                letterSpacing: 0,
                color: AppColors.splashTextPrimary,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.profileHintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogoSearchingCard extends StatelessWidget {
  const LogoSearchingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LogoCardShell(
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.profileStepActive,
                ),
              ),
            ),
          ),
          SizedBox(width: 13),
          Text(
            'Looking for the logo…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.splashTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class LogoNotFoundNotice extends StatelessWidget {
  const LogoNotFoundNotice({
    super.key,
    required this.onUpload,
    required this.onContinueWithout,
  });

  final VoidCallback onUpload;
  final VoidCallback onContinueWithout;

  static const _linkStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.profileStepActive,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'We couldn’t find a logo on this website.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.profileHintText,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          children: [
            TextButton(
              onPressed: onUpload,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Upload logo', style: _linkStyle),
            ),
            TextButton(
              onPressed: onContinueWithout,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Continue without logo', style: _linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}