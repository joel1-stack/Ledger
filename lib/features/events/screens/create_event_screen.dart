import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String groupId;
  const CreateEventScreen({required this.groupId, super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  String _type = 'death';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(firestoreServiceProvider).createEvent(widget.groupId, {
        'type': _type,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'targetAmount': 0,
        'collectedAmount': 0,
        'requiredPerMember': double.tryParse(_amountCtrl.text) ?? 0,
        'deadline': Timestamp.fromDate(_deadline),
        'status': 'active',
        'createdBy': user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('New Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Type *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['death', 'wedding', 'emergency', 'project', 'meeting', 'other'].map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppTextField(controller: _titleCtrl, label: 'Title *', hint: 'e.g. Death of John Kamau\'s Father'),
            const SizedBox(height: 16),
            AppTextField(controller: _descCtrl, label: 'Description', hint: 'Describe the event', maxLines: 3),
            const SizedBox(height: 16),
            AppTextField(controller: _amountCtrl, label: 'Required Contribution (KES)', hint: 'Amount per member', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text(DateHelpers.formatDate(_deadline)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 32),
            AppButton(label: 'Create Event', onPressed: _titleCtrl.text.trim().isNotEmpty ? _create : null, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
