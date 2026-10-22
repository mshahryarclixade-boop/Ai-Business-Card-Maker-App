import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../model/email_signature.dart';
import '../service/email_signature_store.dart';

/// State of the New / Edit signature screen.
class SignatureEditorController extends GetxController {
  SignatureEditorController(EmailSignature initial)
    : _initial = initial,
      sig = initial.obs;

  final EmailSignature _initial;
  final Rx<EmailSignature> sig;

  /// The user changed something since the screen opened.
  bool get dirty => !sig.value.sameContentAs(_initial);

  void setStyle(SignatureStyle s) => sig.value = sig.value.copyWith(style: s);
  void setQr(bool v) => sig.value = sig.value.copyWith(showQr: v);
  void setBookCall(bool v) => sig.value = sig.value.copyWith(showBookCall: v);

  void setDetails({
    required String fullName,
    required String jobTitle,
    required String company,
    required String phone,
    required String website,
  }) => sig.value = sig.value.copyWith(
    fullName: fullName.trim(),
    jobTitle: jobTitle.trim(),
    company: company.trim(),
    phone: phone.trim(),
    website: website.trim(),
  );

  /// Opens the gallery; keeps the current image if the user backs out.
  /// Images are scaled down: they are saved with the signature.
  Future<void> pickImage({required bool logo}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    sig.value = logo
        ? sig.value.copyWith(logo: bytes)
        : sig.value.copyWith(photo: bytes);
  }

  void removeImage({required bool logo}) => sig.value = logo
      ? sig.value.copyWith(clearLogo: true)
      : sig.value.copyWith(clearPhoto: true);

  /// Saves into the store; it becomes the active signature.
  void save() => EmailSignatureStore.put(sig.value);
}
