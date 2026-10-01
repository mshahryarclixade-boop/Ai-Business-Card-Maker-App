import 'package:flutter/material.dart';

import '../model/contact_model.dart';
import 'contact_card.dart';

class ContactsList extends StatelessWidget {
  final List<ContactModel> contacts;
  final ValueChanged<ContactModel> onTap;
  final ValueChanged<ContactModel> onDelete;

  const ContactsList({
    super.key,
    required this.contacts,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = contacts[i];

        return ContactCard(
          contact: c,
          onTap: () => onTap(c),
          onDelete: () => onDelete(c),
        );
      },
    );
  }
}
