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
import '../../../shared/widgets/app_button.dart';
import '../../../router/app_router.dart';

class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _readSim;

  @override
  void initState() {
    super.initState();
    _readSimFromDevice();
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
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _findAndJoin() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final group = await service.getGroupByInviteCode(code);
      if (!mounted) return;
      if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code. Please check and try again.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final membersSnapshot = await service.membersRef(group.id).get();
      final members = membersSnapshot.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      final matchedMember = _readSim != null
          ? members.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m?['phone'] == _readSim,
              orElse: () => null,
            )
          : null;
      if (!mounted) return;
      if (matchedMember != null) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          await service.updateMember(group.id, matchedMember['id'] ?? '', {
            'userId': user.uid,
            'status': 'active',
          });
        }
        ref.read(currentGroupIdProvider.notifier).state = group.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${matchedMember['name'] ?? 'Member'}!')),
          );
        }
        if (mounted) context.go(RouteNames.home);
      } else {
        _showClaimProfileDialog(group.id, members);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showClaimProfileDialog(String groupId, List<dynamic> members) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: _readSim ?? '+254');
    final auth = ref.read(authServiceProvider);
    String? vid;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Claim Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your SIM number was not found in this group. Verify to claim your profile.'),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Name *')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Your Phone *'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            const Text('We will send an OTP to verify.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 10) return;
              try {
                if (vid == null || vid == 'auto_verified') {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    await ref.read(firestoreServiceProvider).addMember(groupId, {
                      'userId': user.uid,
                      'phone': phoneCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'role': 'member',
                      'groupId': groupId,
                      'memberNumber': members.length + 1,
                      'status': 'active',
                      'joinedAt': FieldValue.serverTimestamp(),
                    });
                  }
                } else if (vid != null) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showOtpVerifyDialog(groupId, vid!, phoneCtrl.text.trim(), nameCtrl.text.trim(), members.length);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.read(currentGroupIdProvider.notifier).state = groupId;
                if (mounted) context.go(RouteNames.home);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Verify & Join'),
          ),
        ],
      ),
    );
    auth.sendOtpAndGetVerificationId(phoneCtrl.text.trim()).then((v) => vid = v);
  }

  void _showOtpVerifyDialog(String groupId, String vid, String phone, String name, int memberCount) {
    final codeCtrl = TextEditingController();
    final auth = ref.read(authServiceProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Code sent to $phone'),
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
              if (codeCtrl.text.length < 6) return;
              try {
                await auth.linkPhone(vid, codeCtrl.text);
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await ref.read(firestoreServiceProvider).addMember(groupId, {
                    'userId': user.uid,
                    'phone': phone,
                    'name': name,
                    'role': 'member',
                    'groupId': groupId,
                    'memberNumber': memberCount + 1,
                    'status': 'active',
                    'joinedAt': FieldValue.serverTimestamp(),
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.read(currentGroupIdProvider.notifier).state = groupId;
                if (mounted) context.go(RouteNames.home);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Join Group'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(AppIllustrations.bgJoin, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 32),
              const Text('Enter Invite Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Ask your group chairman for the code', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10),
                decoration: InputDecoration(
                  hintText: 'MWANGA2026',
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              if (_readSim != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sim_card, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text('SIM: $_readSim', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity, height: 56,
                child: AppButton(label: 'Find Group', onPressed: _codeCtrl.text.trim().isNotEmpty ? _findAndJoin : null, isLoading: _isLoading),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
