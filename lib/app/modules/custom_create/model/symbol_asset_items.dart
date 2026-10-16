import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconAssetItem {
  final String id;
  final String label;
  final IconData? iconData;      // Material icons
  final FaIconData? faIconData;  // Font Awesome icons

  const IconAssetItem({
    required this.id,
    required this.label,
    this.iconData,
    this.faIconData,
  }) : assert(iconData != null || faIconData != null);

  /// Builds the right widget for whichever icon type this item holds.
  Widget buildIcon({double? size, Color? color}) {
    final fa = faIconData;
    if (fa != null) return FaIcon(fa, size: size, color: color);
    return Icon(iconData, size: size, color: color);
  }
}

const List<IconAssetItem> kSocialIcons = [
  IconAssetItem(id: 'linkedin', label: 'LinkedIn', faIconData: FontAwesomeIcons.linkedin),
  IconAssetItem(id: 'instagram', label: 'Instagram', faIconData: FontAwesomeIcons.instagram),
  IconAssetItem(id: 'x', label: 'X', faIconData: FontAwesomeIcons.xTwitter),
  IconAssetItem(id: 'facebook', label: 'Facebook', faIconData: FontAwesomeIcons.facebook),
  IconAssetItem(id: 'whatsapp', label: 'WhatsApp', faIconData: FontAwesomeIcons.whatsapp),
  IconAssetItem(id: 'youtube', label: 'YouTube', faIconData: FontAwesomeIcons.youtube),
];

/// Arrow tab: free, straight from Material Icons, no assets needed.
const List<IconAssetItem> kArrowStyles = [
  IconAssetItem(id: 'arrow_solid', label: 'Arrow', iconData: Icons.arrow_forward_rounded),
  IconAssetItem(id: 'arrow_circle', label: 'Circled', iconData: Icons.arrow_circle_right_outlined),
  IconAssetItem(id: 'arrow_back', label: 'Back', iconData: Icons.arrow_back_rounded),
  IconAssetItem(id: 'arrow_double', label: 'Double', iconData: Icons.double_arrow_rounded),
  IconAssetItem(id: 'arrow_curved', label: 'Curved', iconData: Icons.turn_right_rounded),
  IconAssetItem(id: 'arrow_down', label: 'Down', iconData: Icons.arrow_downward_rounded),
];

/// Icons tab: general-purpose contact/decoration icons.
const List<IconAssetItem> kGeneralIcons = [
  IconAssetItem(id: 'globe', label: 'Website', iconData: Icons.language_rounded),
  IconAssetItem(id: 'mail', label: 'Email', iconData: Icons.alternate_email_rounded),
  IconAssetItem(id: 'phone', label: 'Phone', iconData: Icons.call_rounded),
  IconAssetItem(id: 'location', label: 'Location', iconData: Icons.location_on_rounded),
  IconAssetItem(id: 'star', label: 'Star', iconData: Icons.star_rounded),
  IconAssetItem(id: 'briefcase', label: 'Work', iconData: Icons.work_rounded),
];

/// Every icon a sticker can hold. Saved designs are restored by looking the
/// icon up here, because building IconData at runtime breaks icon tree shaking
/// in release builds. Add any new sticker icon to this list too.
final List<IconData> kAllStickerIcons = [
  for (final item in [...kSocialIcons, ...kArrowStyles, ...kGeneralIcons])
    item.faIconData?.data ?? item.iconData!,
  // Icons placed by the AI layout mapper.
  Icons.phone,
  Icons.email,
  Icons.language,
  Icons.location_on,
  Icons.link,
  // Icons of the first card's layout (assets/template_json/first_card).
  Icons.call_outlined,
  Icons.mail_outline_rounded,
  Icons.language_outlined,
];

/// Finds the const IconData matching a saved code point / font family.
IconData? stickerIconFor(int codePoint, String? fontFamily) {
  for (final icon in kAllStickerIcons) {
    if (icon.codePoint == codePoint && icon.fontFamily == fontFamily) {
      return icon;
    }
  }
  return null;
}