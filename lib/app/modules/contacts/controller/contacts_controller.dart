import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/contact_model.dart';

class ContactsController extends GetxController {
  static const String _storageKey = 'contacts_list';

  final contacts = <ContactModel>[].obs;
  final searchQuery = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadContacts();
  }

  /// Contacts to actually render — respects the current search query.
  List<ContactModel> get filteredContacts {
    final q = searchQuery.value.trim().toLowerCase();
    final sorted = [...contacts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (q.isEmpty) return sorted;
    return sorted.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.companyName.toLowerCase().contains(q) ||
          c.jobTitle.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();
  }

  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  Future<void> loadContacts() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw) as List;
        contacts.assignAll(
          decoded.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  // ---------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------

  Future<void> addContact(ContactModel contact) async {
    contacts.add(contact);
    await _persist();
  }

  Future<void> updateContact(ContactModel updated) async {
    final index = contacts.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      contacts[index] = updated;
      contacts.refresh();
      await _persist();
    }
  }

  Future<void> deleteContact(String id) async {
    contacts.removeWhere((c) => c.id == id);
    await _persist();
  }

  void updateSearch(String query) => searchQuery.value = query;

  // ---------------------------------------------------------------------
  // Image handling — copies the picked file into app storage so it
  // survives after the OS image-picker cache is cleared.
  // ---------------------------------------------------------------------

  Future<String?> pickAndStoreImage({required ImageSource source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final contactsDir = Directory('${docsDir.path}/contact_photos');
    if (!await contactsDir.exists()) {
      await contactsDir.create(recursive: true);
    }
    final ext = picked.path.split('.').last;
    final fileName = 'contact_${DateTime.now().microsecondsSinceEpoch}.$ext';
    final savedFile = await File(picked.path).copy('${contactsDir.path}/$fileName');
    return savedFile.path;
  }

  /// Copies an already-existing image (e.g. the scanned card image, which
  /// usually lives in a temp/cache folder) into app storage so it doesn't
  /// disappear later. Returns the original path if copying fails.
  Future<String> persistImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return sourcePath;

      final docsDir = await getApplicationDocumentsDirectory();
      final contactsDir = Directory('${docsDir.path}/contact_photos');
      if (!await contactsDir.exists()) {
        await contactsDir.create(recursive: true);
      }

      // Already stored in our folder — nothing to copy.
      if (sourcePath.startsWith(contactsDir.path)) return sourcePath;

      final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      final fileName = 'contact_${DateTime.now().microsecondsSinceEpoch}.$ext';
      final savedFile = await source.copy('${contactsDir.path}/$fileName');
      return savedFile.path;
    } catch (_) {
      return sourcePath;
    }
  }
}