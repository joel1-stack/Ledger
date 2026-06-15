import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../router/app_router.dart';

class GroupCreateScreen extends ConsumerStatefulWidget {
  final String? modelId;
  const GroupCreateScreen({this.modelId, super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  int _step = 1;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<Map<String, dynamic>> _contributionTypes = [];
  bool _isLoading = false;

  static const _modelConfigs = {
    'funeral_welfare': {
      'name': 'Funeral Welfare',
      'desc': 'Burial society supporting members during bereavement',
      'types': [
        {'name': 'Monthly Fee', 'amount': 500.0, 'frequency': 'monthly', 'mandatory': true},
        {'name': 'Death Contribution', 'amount': 2000.0, 'frequency': 'as-needed', 'mandatory': true},
        {'name': 'Emergency Levy', 'amount': 1000.0, 'frequency': 'as-needed', 'mandatory': false},
      ],
    },
    'investment_chama': {
      'name': 'Investment Chama',
      'desc': 'Pool savings for investments and dividends',
      'types': [
        {'name': 'Share Purchase', 'amount': 1000.0, 'frequency': 'monthly', 'mandatory': true},
        {'name': 'Project Contribution', 'amount': 5000.0, 'frequency': 'as-needed', 'mandatory': false},
        {'name': 'Loan Payment', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
      ],
    },
    'church_group': {
      'name': 'Church Group',
      'desc': 'Managing tithes, offerings, and ministry funds',
      'types': [
        {'name': 'Tithe', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
        {'name': 'Offering', 'amount': 0.0, 'frequency': 'weekly', 'mandatory': false},
        {'name': 'Building Fund', 'amount': 2000.0, 'frequency': 'monthly', 'mandatory': true},
        {'name': 'Ministry Project', 'amount': 0.0, 'frequency': 'as-needed', 'mandatory': false},
      ],
    },
    'sacco': {
      'name': 'SACCO',
      'desc': 'Savings and Credit Cooperative',
      'types': [
        {'name': 'Share Contribution', 'amount': 500.0, 'frequency': 'monthly', 'mandatory': true},
        {'name': 'Loan Repayment', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
        {'name': 'Savings Deposit', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    if (widget.modelId != null && _modelConfigs.containsKey(widget.modelId)) {
      final config = _modelConfigs[widget.modelId]!;
      _nameController.text = config['name'] as String;
      _descController.text = config['desc'] as String;
      final types = config['types'] as List<Map<String, dynamic>>;
      _contributionTypes.addAll(types);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addContributionType() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        String frequency = 'monthly';
        bool mandatory = true;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Add Contribution Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'Monthly Contribution')),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (KES)')),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: frequency,
                  items: ['monthly', 'weekly', 'one-time', 'as-needed'].map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1)))).toList(),
                  onChanged: (v) => setDialogState(() => frequency = v!),
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Mandatory'),
                  value: mandatory,
                  onChanged: (v) => setDialogState(() => mandatory = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _contributionTypes.add({
                      'name': nameCtrl.text,
                      'amount': double.tryParse(amountCtrl.text) ?? 0,
                      'frequency': frequency,
                      'mandatory': mandatory,
                    });
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final firebaseUser = ref.read(currentUserProvider);
      if (firebaseUser == null) return;
      final service = ref.read(firestoreServiceProvider);
      final group = await service.createGroup({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'inviteCode': IdGenerator.generateInviteCode(),
        'createdBy': firebaseUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'enabledFeatures': ['contributions', 'events', 'approvals', 'reports', 'documents', 'timeline'],
        'stats': {'totalMembers': 1, 'totalCollected': 0.0, 'totalOutstanding': 0.0, 'activeEvents': 0},
      });
      await service.addMember(group.id, {
        'userId': firebaseUser.uid,
        'phone': firebaseUser.phoneNumber ?? '',
        'name': firebaseUser.displayName ?? _nameController.text.trim(),
        'role': 'chairman',
        'groupId': group.id,
        'memberNumber': 1,
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      for (final type in _contributionTypes) {
        await service.addContributionType(group.id, {
          ...type,
          'groupId': group.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ref.read(currentGroupIdProvider.notifier).state = group.id;
        context.go(RouteNames.inviteMembers, extra: group.id);
      }
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
      appBar: AppBar(title: Text('Step $_step of 3')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: _step / 3, backgroundColor: AppColors.background, color: AppColors.primary),
              const SizedBox(height: 32),
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (_step > 1)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 1) const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: _step < 3 ? 'Next' : 'Create Group',
                  onPressed: () {
                    if (_step < 3) {
                      setState(() => _step++);
                    } else {
                      _createGroup();
                    }
                  },
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Center(
            child: SizedBox(
              width: 180, height: 140,
              child: SvgPicture.network(
                AppIllustrations.groupCreate,
                fit: BoxFit.contain,
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text('Create Your Group', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        AppTextField(controller: _nameController, label: 'Group Name *', hint: 'e.g. Mwangaza Funeral Welfare'),
        const SizedBox(height: 16),
        AppTextField(controller: _descController, label: 'Description', hint: 'Supporting members during bereavement', maxLines: 3),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Center(
            child: SizedBox(
              width: 180, height: 140,
              child: SvgPicture.network(
                AppIllustrations.wallet,
                fit: BoxFit.contain,
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text('Set Contribution Types', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('What does your group collect?', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              ..._contributionTypes.map((t) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                      title: Text(t['name']),
                      subtitle: Text('KES ${(t['amount'] as double).toStringAsFixed(0)} | ${t['frequency']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => setState(() => _contributionTypes.remove(t)),
                      ),
                    ),
                  )),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  title: const Text('Add Contribution Type'),
                  onTap: _addContributionType,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Center(
            child: SizedBox(
              width: 180, height: 140,
              child: SvgPicture.network(
                AppIllustrations.teamWork,
                fit: BoxFit.contain,
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text('Roles & Invite', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('You (Chairman)'),
          subtitle: const Text('Full access'),
        ),
        const Divider(),
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person_add_alt_1)),
          title: Text('Add Treasurer'),
          subtitle: Text('By phone number'),
        ),
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person_add_alt_1)),
          title: Text('Add Secretary'),
          subtitle: Text('By phone number'),
        ),
      ],
    );
  }
}
