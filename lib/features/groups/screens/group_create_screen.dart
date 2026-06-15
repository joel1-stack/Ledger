import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/constants/app_colors.dart';
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
  int _step = 1;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _memberNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+254');
  final _typeNameCtrl = TextEditingController();
  final _typeAmountCtrl = TextEditingController();
  final List<Map<String, dynamic>> _types = [];
  final List<Map<String, String>> _docs = [];
  final _docTitleCtrl = TextEditingController();
  String _docTypeValue = 'other';
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

  bool get _isCustom => widget.modelId == 'custom';
  bool get _step1Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _memberNameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().length >= 10;

  @override
  void initState() {
    super.initState();
    _readSimFromDevice();
    if (widget.modelId != null && widget.modelId != 'custom' && _modelConfigs.containsKey(widget.modelId)) {
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
    _typeNameCtrl.dispose();
    _typeAmountCtrl.dispose();
    _docTitleCtrl.dispose();
    super.dispose();
  }

  void _addType() {
    final name = _typeNameCtrl.text.trim();
    final amount = double.tryParse(_typeAmountCtrl.text.trim()) ?? 0;
    if (name.isEmpty) return;
    setState(() {
      _types.add({'name': name, 'amount': amount, 'frequency': 'monthly', 'mandatory': false});
      _typeNameCtrl.clear();
      _typeAmountCtrl.clear();
    });
  }

  void _removeType(int index) {
    setState(() => _types.removeAt(index));
  }

  void _addDoc() {
    final title = _docTitleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _docs.add({'title': title, 'type': _docTypeValue});
      _docTitleCtrl.clear();
      _docTypeValue = 'other';
    });
  }

  void _removeDoc(int index) {
    setState(() => _docs.removeAt(index));
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
      for (final d in _docs) {
        await service.addDocument(group.id, {
          'title': d['title'],
          'type': d['type'],
          'fileUrl': '',
          'uploadedBy': user.uid,
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
    String? errorMsg;

    void proceedWithoutVerify() {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skipped verification. You can verify later in settings.'), backgroundColor: AppColors.warning),
      );
      context.go(RouteNames.inviteMembers, extra: groupId);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Verify Chairman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SIM phone number does not match.'),
              const SizedBox(height: 8),
              Text('Enter the OTP sent to $phone',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(errorMsg!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
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
            TextButton(
              onPressed: proceedWithoutVerify,
              child: const Text('Skip Verification'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.length < 6 || vid == null) return;
                try {
                  await auth.linkPhone(vid!, codeCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) context.go(RouteNames.inviteMembers, extra: groupId);
                } catch (e) {
                  setDialogState(() => errorMsg = 'Invalid OTP. Try again or skip.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
    auth.sendOtpAndGetVerificationId(phone).then((v) { vid = v; return v; }).catchError((e) {
      if (mounted) {
        errorMsg = 'SMS could not be sent. Please enable SMS region in Firebase console or use Skip.';
        setState(() {});
      }
      return '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isCustom ? 'Custom Group' : 'Create Group'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _stepDot(1, 'Details'),
                _stepLine(1),
                _stepDot(2, 'Types'),
                _stepLine(2),
                _stepDot(3, 'Review'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 1 ? _buildStep1() : _step == 2 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _step >= step;
    final isDone = _step > step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppColors.divider,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(int from) {
    final isActive = _step > from;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.divider),
    );
  }

  Widget _buildStep1() {
    final modelName = widget.modelId != null && _modelConfigs.containsKey(widget.modelId)
        ? _modelConfigs[widget.modelId]!['name'] as String
        : _isCustom ? 'Custom' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (modelName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(modelName, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const Text('Group Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        AppTextField(controller: _nameCtrl, label: 'Group Name *', hint: 'e.g. Mwangaza Welfare'),
        const SizedBox(height: 12),
        AppTextField(controller: _descCtrl, label: 'Description', hint: 'What is your group about?', maxLines: 3),
        const SizedBox(height: 24),

        // Documents section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Group Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton.icon(
              onPressed: _showAddDocDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: AppColors.textTertiary, size: 20),
                const SizedBox(width: 8),
                Text('Attach constitution, rules, or any document',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ],
            ),
          )
        else
          ..._docs.asMap().entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          Text(entry.value['type'] ?? '',
                              style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeDoc(entry.key),
                      child: Icon(Icons.close, size: 18, color: AppColors.error),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 24),
        const Text('Your Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
        const SizedBox(height: 32),
        AppButton(
          label: 'Continue',
          onPressed: _step1Valid ? () => setState(() => _step = 2) : null,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What does your group collect?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (_types.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, color: AppColors.textTertiary, size: 40),
                const SizedBox(height: 12),
                const Text('No contribution types yet', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Add types below, or skip and add later',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ],
            ),
          )
        else
          ..._types.asMap().entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                  ),
                  title: Text(entry.value['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('KES ${(entry.value['amount'] as double).toStringAsFixed(0)} \u2022 ${entry.value['frequency']}',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                  trailing: _isCustom
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                          onPressed: () => _removeType(entry.key),
                        )
                      : null,
                  dense: true,
                ),
              )),
        if (_isCustom) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showAddTypeDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Custom Contribution Type'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Continue',
                onPressed: () => setState(() => _step = 3),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final isCustom = _isCustom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review your group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.group, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameCtrl.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${_types.length} contribution type${_types.length != 1 ? 's' : ''}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _reviewRow(Icons.person, 'Chairman', _memberNameCtrl.text),
              _reviewRow(Icons.phone, 'Phone', _phoneCtrl.text),
              if (_descCtrl.text.isNotEmpty)
                _reviewRow(Icons.description, 'Description', _descCtrl.text),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Contribution Types', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              ..._types.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(t['name'], style: const TextStyle(fontSize: 14)),
                        const Spacer(),
                        Text('KES ${(t['amount'] as double).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  )),
              if (_docs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                ..._docs.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(d['title'] ?? '', style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          Text(d['type'] ?? '', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Create Group',
                onPressed: _create,
                isLoading: _isLoading,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddDocDialog() {
    _docTitleCtrl.clear();
    _docTypeValue = 'other';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _docTitleCtrl,
                decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. Group Constitution'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _docTypeValue,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'constitution', child: Text('Constitution')),
                  DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                  DropdownMenuItem(value: 'rules', child: Text('Rules')),
                  DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => _docTypeValue = v ?? 'other'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addDoc();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTypeDialog() {
    _typeNameCtrl.clear();
    _typeAmountCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Contribution Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _typeNameCtrl,
              decoration: const InputDecoration(labelText: 'Type Name', hintText: 'e.g. Monthly Fee'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typeAmountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (KES)', hintText: 'e.g. 500'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addType();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
