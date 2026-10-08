import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/add_link_sheet.dart';
import '../../paywall/view/paywall_view.dart';
import '../../profile/model/profile_model.dart';
import '../../profile/service/profile_repository.dart';
import '../../profile_setup/service/profile_store.dart';
import '../service/qr_generator_service.dart';
import '../model/qr_profile_data.dart';
import 'qr_preview_screen.dart';

class CustomQrCodeScreen extends StatefulWidget {
  final bool forCardInsertion;

  const CustomQrCodeScreen({super.key, this.forCardInsertion = false});

  @override
  State<CustomQrCodeScreen> createState() => _CustomQrCodeScreenState();
}

class _SocialLinkEntry {
  final String platform;
  final String imagePath;
  String url;

  _SocialLinkEntry(this.platform, this.imagePath, this.url);
}

class _CustomQrCodeScreenState extends State<CustomQrCodeScreen> {
  /// GetStorage key for the last QR form the user generated.
  static const String _storeKey = 'qr_form_data';

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _designation = TextEditingController();
  final _website = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();

  final List<_SocialLinkEntry> _socialLinks = [];
  bool _isGenerating = false;
  bool _autoFill = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _designation.dispose();
    _website.dispose();
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  String _s(dynamic v) => v is String ? v : '';

  /// Opens with the last saved QR details. The first time, the form is
  /// filled from the details entered during profile setup.
  void _loadForm() {
    final raw = GetStorage().read<String>(_storeKey);

    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _fullName.text = _s(m['fullName']);
        _phone.text = _s(m['phone']);
        _email.text = _s(m['email']);
        _company.text = _s(m['company']);
        _designation.text = _s(m['designation']);
        _website.text = _s(m['website']);
        _country.text = _s(m['country']);
        _city.text = _s(m['city']);

        final links = (m['links'] as List?) ?? const [];
        for (final item in links) {
          if (item is Map) {
            _socialLinks.add(
              _SocialLinkEntry(
                _s(item['platform']),
                _s(item['imagePath']),
                _s(item['url']),
              ),
            );
          }
        }
        return;
      } catch (_) {
        // Unreadable saved data: fall back to the setup details below.
      }
    }

    final d = ProfileStore.to.profile.value;
    _fullName.text = d.fullName;
    _phone.text = d.phone;
    _email.text = d.email;
    _company.text = d.companyName;
    _designation.text = d.designation;
    _website.text = d.website;
  }

  /// Remembers the form so "Edit Digital Card Details" opens with it again.
  void _saveForm() {
    GetStorage().write(
      _storeKey,
      jsonEncode({
        'fullName': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'company': _company.text.trim(),
        'designation': _designation.text.trim(),
        'website': _website.text.trim(),
        'country': _country.text.trim(),
        'city': _city.text.trim(),
        'links': _socialLinks
            .map(
              (e) => {
            'platform': e.platform,
            'imagePath': e.imagePath,
            'url': e.url,
          },
        )
            .toList(),
      }),
    );
  }

  /// Opens the shared white bottom sheet (4 platform icons per row),
  /// then the URL sheet, and adds the result to the social links list.
  Future<void> _openAddLinkSheet() async {
    final added = await showAddLinkSheet(context);
    if (added == null) return;

    setState(() {
      _socialLinks.add(
        _SocialLinkEntry(
          added.platform.name,
          added.platform.imagePath,
          added.url,
        ),
      );
    });
  }

  /// Fills every field on this form from the given saved profile.
  /// Existing text is fully replaced — this is only called right after
  /// the user flips the "Auto-fill" toggle on.
  void _applyProfileAutofill(ProfileModel profile) {
    setState(() {
      _fullName.text = profile.fullName;
      _phone.text = profile.phone;
      _email.text = profile.email;
      _company.text = profile.companyName;
      _designation.text = profile.jobTitle;
      _website.text = profile.companyWebsite;

      _country.clear();
      _city.text = profile.location;

      // `ProfileModel.socialLinks` only stores raw URLs (no platform
      // label), so the platform is guessed from the URL.
      _socialLinks
        ..clear()
        ..addAll(
          profile.socialLinks.where((url) => url.trim().isNotEmpty).map((url) {
            final p = guessPlatform(url);
            return _SocialLinkEntry(p.name, p.imagePath, url.trim());
          }),
        );
    });
  }

  QrProfileData _collectProfile() {
    return QrProfileData(
      fullName: _fullName.text.trim(),
      phoneNumber: _phone.text.trim(),
      emailAddress: _email.text.trim(),
      companyName: _company.text.trim(),
      designation: _designation.text.trim(),
      websiteUrl: _website.text.trim(),
      country: _country.text.trim(),
      city: _city.text.trim(),
      socialLinks: _socialLinks
          .map((e) => SocialLink(platform: e.platform, url: e.url))
          .toList(),
    );
  }

  Future<void> _generate() async {
    // Dismiss the keyboard before generating.
    FocusScope.of(context).unfocus();

    final profile = _collectProfile();

    if (!profile.isValid) {
      Get.snackbar(
        'Full name required',
        'Add at least a full name before generating a QR code.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    // Keep these details for next time.
    _saveForm();

    setState(() => _isGenerating = true);

    try {
      final bytes = await QrGeneratorService().generatePngBytes(profile);

      final dir = await getTemporaryDirectory();
      await File(
        '${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(bytes);

      if (!mounted) return;

      Get.off(() => QrPreviewScreen(profile: profile));
    } catch (_) {
      Get.snackbar(
        'Something went wrong',
        'Could not generate the QR code. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.titleDark),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Custom QR Code',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Get.to(
                        () => const PaywallView(),
                    transition: Transition.rightToLeft,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.crown,
                    size: 18,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Auto-fill from your saved profile',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Switch(
                    value: _autoFill,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white38,
                    onChanged: (value) {
                      if (value) {
                        final profile = ProfileRepository.getSavedProfile();
                        if (profile == null) {
                          Get.snackbar(
                            'No saved profile',
                            'Save your profile first to use auto-fill.',
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(15),
                          );
                          return;
                        }
                        _applyProfileAutofill(profile);
                      }
                      setState(() => _autoFill = value);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Personal Info'),
                    _Field(
                      label: 'Full Name',
                      controller: _fullName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Phone Number',
                            controller: _phone,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            label: 'Email Address',
                            controller: _email,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Professional'),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Company Name',
                            controller: _company,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            label: 'Designation',
                            controller: _designation,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      label: 'Website URL',
                      controller: _website,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    _SectionLabel('Social Links'),
                    ..._socialLinks.map(
                          (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                link.imagePath,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  link.url,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setState(() => _socialLinks.remove(link)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openAddLinkSheet,
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomPaint(
                          painter: _DottedBorderPainter(
                            color: AppColors.primary,
                            radius: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add custom links',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SectionLabel('Location (optional)'),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Country',
                            controller: _country,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            label: 'City',
                            controller: _city,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Generate QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          style: AppTextStyles.splashSubtitle.copyWith(
            fontSize: 12,
            color: Colors.black,
          ),
          strutStyle: const StrutStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            height: 1.0,
            forceStrutHeight: true,
          ),
          onEditingComplete: () {
            if (textInputAction == TextInputAction.done) {
              FocusScope.of(context).unfocus();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dotted border painter for the "Add custom links" button.
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DottedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end.toDouble()), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}