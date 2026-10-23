/// Which profile's data the app is showing. Every per-profile store reads and
/// writes its storage key through [key], so each profile keeps its own
/// information, designs, QR codes and signatures.
///
/// The first profile ([defaultId]) uses the original, un-suffixed keys, so the
/// data saved before profiles existed simply belongs to it.
abstract final class ProfileScope {
  static const defaultId = 'main';

  /// The active profile.
  static String id = defaultId;

  /// The storage key for [base] in the active profile (or in [forId]).
  static String key(String base, [String? forId]) {
    final i = forId ?? id;
    return i == defaultId ? base : '${base}__$i';
  }

  /// Every storage key that holds per-profile data.
  static const perProfileKeys = [
    'user_profile_data',
    'recent_designs',
    'email_signatures',
    'qr_entries',
    'qr_form_data',
    'qr_intro_seen',
  ];
}
