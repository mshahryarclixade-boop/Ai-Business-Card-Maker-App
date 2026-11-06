import 'dart:convert';

import '../../modules/custom_create/model/card_element_model.dart';
import '../../modules/profile_setup/model/user_profile_data.dart';
import '../../modules/profile_setup/service/profile_logo_file.dart';
import '../../modules/template/model/template_live_data.dart';

/// Brings a saved card's details in line with a changed profile, without
/// touching what the user made themselves.
///
/// Only elements that carry a profile `field` (name, title, company, phone,
/// email, website, the logo, the monogram letter) are considered, and a text
/// is only replaced while it still shows exactly the OLD profile value. A text
/// the user edited by hand, an element they added, and every position, size,
/// colour and layer stay as they are.
abstract final class CardProfileSync {
  /// A copy of [data] (a card's `designData`, both sides) with the profile
  /// changes applied, or null when nothing in it follows the profile.
  ///
  /// [newLogoPath] / [newLogoAspect] describe the new profile logo ('' / null
  /// for none).
  static Map<String, dynamic>? apply(
    Map<String, dynamic> data,
    UserProfileData old,
    UserProfileData neu, {
    String? newLogoPath,
    double newLogoAspect = 1,
  }) {
    final oldV = TemplateData.valuesOf(old);
    final newV = TemplateData.valuesOf(neu);
    final logoChanged = _logoKey(old) != _logoKey(neu);

    final copy = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    var changed = false;

    final sides = <Map<String, dynamic>>[
      copy,
      if (copy['back'] is Map<String, dynamic>)
        copy['back'] as Map<String, dynamic>,
    ];

    for (final side in sides) {
      final els = (side['elements'] as List?)?.cast<Map<String, dynamic>>();
      if (els == null) continue;
      final out = <Map<String, dynamic>>[];
      // Fields whose text was removed (the new value is empty): their icon
      // goes with them.
      final emptied = <String>{};

      for (final e in els) {
        final field = e['field'] as String?;
        if (field == null) {
          out.add(e);
          continue;
        }

        if (field == 'logo' && e['type'] == 'image') {
          if (!logoChanged) {
            out.add(e);
            continue;
          }
          changed = true;
          if (newLogoPath == null || newLogoPath.isEmpty) continue; // removed
          out.add(_refitLogo(e, newLogoPath, newLogoAspect));
          continue;
        }

        if (e['type'] == 'text' && oldV.containsKey(field)) {
          final o = oldV[field]!;
          final n = newV[field]!;
          if (o == n || o.isEmpty) {
            out.add(e);
            continue;
          }
          final text = e['text'] as String? ?? '';
          String? next;
          if (text == o) {
            next = n;
          } else if (text == o.toUpperCase() && o != o.toUpperCase()) {
            // The template shows this one in capitals.
            next = n.toUpperCase();
          }
          if (next == null) {
            out.add(e); // edited by hand: left alone
            continue;
          }
          changed = true;
          if (n.isEmpty) {
            emptied.add(field);
            continue;
          }
          out.add({...e, 'text': next});
          continue;
        }
        out.add(e);
      }

      if (emptied.isNotEmpty) {
        out.removeWhere(
          (e) => e['type'] == 'symbol' && emptied.contains(e['field']),
        );
      }
      side['elements'] = out;
    }
    return changed ? copy : null;
  }

  static String _logoKey(UserProfileData p) =>
      p.hasLogo ? ProfileLogoFile.contentKey(p.logoBytes!) : '';

  /// The logo in the same box as before, but never stretched.
  static Map<String, dynamic> _refitLogo(
    Map<String, dynamic> e,
    String path,
    double aspect,
  ) {
    final w = (e['width'] as num?)?.toDouble() ?? 40;
    final h = (e['height'] as num?)?.toDouble() ?? 40;
    final box = w > h ? w : h;
    final nw = aspect >= 1 ? box : box * aspect;
    final nh = aspect >= 1 ? box / aspect : box;
    final pos = e['position'] as Map<String, dynamic>;
    final cx = (pos['dx'] as num).toDouble() + w / 2;
    final cy = (pos['dy'] as num).toDouble() + h / 2;
    return {
      ...e,
      'imageFilePath': path,
      'imageAsset': null,
      'width': nw,
      'height': nh,
      'position': {'dx': cx - nw / 2, 'dy': cy - nh / 2},
    };
  }

  /// The elements of one side of [data], parsed (for rendering).
  static List<CardElement> elementsOf(Map<String, dynamic> side) => [
    for (final e in (side['elements'] as List? ?? const []))
      CardElement.fromJson(e as Map<String, dynamic>),
  ];
}
