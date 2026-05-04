import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/contacts_provider.dart';
import 'package:rakshak/shared/models/emergency_contact.dart';

/// Contacts Manager — Emergency contacts with hierarchy system.
/// Clean white UI with contact cards, call/alert actions.
class ContactsManager extends StatefulWidget {
  const ContactsManager({super.key});

  @override
  State<ContactsManager> createState() => _ContactsManagerState();
}

class _ContactsManagerState extends State<ContactsManager> {
  void _showContactSheet({EmergencyContact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    bool isPrimary = contact?.isPrimary ?? false;
    final String relationship = contact?.relationship ?? 'Family';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact == null ? 'Add Contact' : 'Edit Contact',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Primary Contact', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: isPrimary,
                        activeThumbColor: const Color(0xFFD32F2F),
                        onChanged: (val) => setSheetState(() => isPrimary = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                          if (contact == null) {
                            context.read<ContactsProvider>().addContact(EmergencyContact(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text,
                              phone: phoneController.text,
                              isPrimary: isPrimary,
                              relationship: relationship,
                            ));
                          } else {
                            context.read<ContactsProvider>().updateContact(contact.copyWith(
                              name: nameController.text,
                              phone: phoneController.text,
                              isPrimary: isPrimary,
                              relationship: relationship,
                            ));
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(contact == null ? 'Save Contact' : 'Update Contact'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        final contacts = provider.contacts;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1C)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Emergency Contacts',
              style: TextStyle(
                color: Color(0xFF1A1C1C),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          body: provider.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1C1C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contacts.length} contacts saved',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contacts list
                  Expanded(
                    child: contacts.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No emergency contacts yet', 
                                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return Dismissible(
                              key: Key(contact.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                provider.removeContact(contact.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${contact.name} removed')),
                                );
                              },
                              child: _ContactCard(
                                contact: contact,
                                onEdit: () => _showContactSheet(contact: contact),
                              ),
                            );
                          },
                        ),
                  ),

                  // Add contact button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showContactSheet(),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text(
                          'Add Emergency Contact',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onEdit;

  const _ContactCard({required this.contact, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: contact.isPrimary
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: contact.isPrimary
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (contact.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: () async {
              final uri = Uri.parse('sms:${contact.phone}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.message_outlined,
                color: Color(0xFFE65100), size: 22),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF1976D2), size: 22),
          ),
          IconButton(
            onPressed: () async {
              final uri = Uri.parse('tel:${contact.phone}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.phone_outlined,
                color: Color(0xFF388E3C), size: 22),
          ),
        ],
      ),
    );
  }
}

