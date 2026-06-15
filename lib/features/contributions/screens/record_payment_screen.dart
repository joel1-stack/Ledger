import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/contributions_provider.dart';
import '../../../core/providers/members_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_loading.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String groupId;
  const RecordPaymentScreen({required this.groupId, super.key});

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  String? _selectedTypeId;
  String? _selectedMemberId;
  double _amount = 0;
  String _method = 'cash';
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedTypeId == null || _selectedMemberId == null) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final members = await ref.read(membersProvider(widget.groupId).future);
      final member = members.firstWhere((m) => m.id == _selectedMemberId);
      final types = await ref.read(contributionTypesProvider(widget.groupId).future);
      final type = types.firstWhere((t) => t.id == _selectedTypeId);

      await ref.read(firestoreServiceProvider).recordContribution(widget.groupId, {
        'memberId': _selectedMemberId,
        'memberName': member.name,
        'typeId': _selectedTypeId,
        'typeName': type.name,
        'amount': _amount > 0 ? _amount : type.amount,
        'status': 'paid',
        'method': _method,
        'receiptUrl': null,
        'notes': _notesCtrl.text,
        'recordedBy': user?.uid ?? '',
        'recordedByName': user?.displayName ?? user?.uid ?? '',
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(contributionTypesProvider(widget.groupId));
    final members = ref.watch(membersProvider(widget.groupId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            types.when(
              data: (typeList) => DropdownButtonFormField(
                initialValue: _selectedTypeId,
                items: typeList.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} — ${t.amount > 0 ? "KES ${t.amount.toStringAsFixed(0)}" : "Open"}'))).toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
                decoration: const InputDecoration(labelText: 'Contribution Type *'),
              ),
              loading: () => const SizedBox(height: 60, child: AppLoading()),
              error: (_, _) => const Text('Error loading types'),
            ),
            const SizedBox(height: 16),
            members.when(
              data: (memberList) => DropdownButtonFormField(
                initialValue: _selectedMemberId,
                items: memberList.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
                decoration: const InputDecoration(labelText: 'Member *'),
              ),
              loading: () => const SizedBox(height: 60, child: AppLoading()),
              error: (_, _) => const Text('Error loading members'),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (KES)'),
              onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _methodChip('cash', 'Cash', Icons.money)),
                const SizedBox(width: 12),
                Expanded(child: _methodChip('mpesa', 'M-Pesa', Icons.phone_android)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save Payment',
              onPressed: (_selectedTypeId != null && _selectedMemberId != null) ? _save : null,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String value, String label, IconData icon) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
