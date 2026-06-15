import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/group_provider.dart';
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
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _memberNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+254');
  final List<Map<String, dynamic>> _types = [];
  bool _isLoading = false;
  String? _readSim;

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
      ],
    },
    'sacco': {
      'name': 'SACCO',
      'desc': 'Savings and Credit Cooperative',
      'types': [
        {'name': 'Share Contribution', 'amount': 500.0, 'frequency': 'monthly', 'mandatory': true},
        {'name': 'Loan Repayment', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
      ],
    },
    'church': {
      'name': 'Church Group',
      'desc': 'Managing tithes, offerings, and ministry funds',
      'types': [
        {'name': 'Tithe', 'amount': 0.0, 'frequency': 'monthly', 'mandatory': false},
        {'name': 'Building Fund', 'amount': 2000.0, 'frequency': 'monthly', 'mandatory': true},
      ],
    },
    'wedding': {
      'name': 'Wedding Committee',
      'desc': 'Coordinate wedding budgets and contributions',
      'types': [
        {'name': 'Contribution', 'amount': 0.0, 'frequency': 'one-time', 'mandatory': false},
        {'name': 'Budget Item', 'amount': 0.0, 'frequency': 'one-time', 'mandatory': false},
      ],
    },
    'community_project': {
      'name': 'Community Project',
      'desc': 'Build together with transparent tracking',
      'types': [
        {'name': 'Project Contribution', 'amount': 0.0, 'frequency': 'one-time', 'mandatory': false},
        {'name': 'Monthly Dues', 'amount': 500.0, 'frequency': 'monthly', 'mandatory': true},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _readSimFromDevice();
    if (widget.modelId != null && _modelConfigs.containsKey(widget.modelId)) {
      final cfg = _modelConfigs[widget.modelId]!;
      _nameCtrl.text = cfg['name'] as String;
      _descCtrl.text = cfg['desc'] as String;
      _types.addAll(cfg['types'] as List<Map<String, dynamic>>);
    }
  }

  Future<void> _readSimFromDevice() async {
    try {
      final hint = await SmsAutoFill().hint;
      if (hint != null && mounted) {
        final raw = hint.replaceAll(RegExp(r'\D'), '');
        if (raw.length >= 10) {
          final last9 = raw.length > 9 ? raw.substring(raw.length - 9) : raw;
          setState(() => _readSim = '+254$last9');
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _memberNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final memberName = _memberNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || memberName.isEmpty || phone.length < 10) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final service = ref.read(firestoreServiceProvider);
      final simMatch = _readSim != null && _readSim == phone;
      final group = await service.createGroup({
        'name': name,
        'description': _descCtrl.text.trim(),
        'inviteCode': IdGenerator.generateInviteCode(),
        'createdBy': user.uid,
        'createdByName': memberName,
        'createdByPhone': phone,
        'simVerified': simMatch,
        'createdAt': FieldValue.serverTimestamp(),
        'enabledFeatures': ['contributions', 'events', 'approvals', 'reports', 'documents', 'timeline'],
        'stats': {'totalMembers': 1, 'totalCollected': 0.0, 'totalOutstanding': 0.0, 'activeEvents': 0},
      });
      await service.addMember(group.id, {
        'userId': user.uid,
        'phone': phone,
        'name': memberName,
        'role': 'chairman',
        'groupId': group.id,
        'memberNumber': 1,
        'status': simMatch ? 'active' : 'pending_verify',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      for (final t in _types) {
        await service.addContributionType(group.id, {
          ...t,
          'groupId': group.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ref.read(currentGroupIdProvider.notifier).state = group.id;
        if (simMatch) {
          context.go(RouteNames.inviteMembers, extra: group.id);
        } else {
          _showOtpDialog(group.id, phone, memberName);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(String groupId, String phone, String name) {
    final codeCtrl = TextEditingController();
    final auth = ref.read(authServiceProvider);
    String? vid;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Chairman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SIM phone number does not match. Verify with OTP to become Chairman.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(labelText: 'OTP Code'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.length < 6 || vid == null) return;
              try {
                await auth.linkPhone(vid!, codeCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) context.go(RouteNames.inviteMembers, extra: groupId);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    auth.sendOtpAndGetVerificationId(phone).then((v) => vid = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Group'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(AppIllustrations.bgCreate, height: 140, width: 260, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Group Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AppTextField(controller: _nameCtrl, label: 'Group Name *', hint: 'e.g. Mwangaza Welfare'),
            const SizedBox(height: 12),
            AppTextField(controller: _descCtrl, label: 'Description', hint: 'What is your group about?', maxLines: 3),
            const SizedBox(height: 24),
            const Text('Your Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AppTextField(controller: _memberNameCtrl, label: 'Your Name *', hint: 'e.g. Joel Kaunda'),
            const SizedBox(height: 12),
            AppTextField(controller: _phoneCtrl, label: 'Your Phone *', hint: '+254712345678', keyboardType: TextInputType.phone),
            if (_readSim != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.sim_card, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text('SIM: $_readSim', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_types.isNotEmpty) ...[
              const Text('Contribution Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._types.map((t) => Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                  title: Text(t['name']),
                  subtitle: Text('KES ${(t['amount'] as double).toStringAsFixed(0)} | ${t['frequency']}'),
                  dense: true,
                ),
              )),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: 'Create Group',
              onPressed: (_nameCtrl.text.trim().isNotEmpty && _memberNameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().length >= 10) ? _create : null,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
