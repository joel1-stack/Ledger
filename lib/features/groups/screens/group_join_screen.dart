import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/group_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../router/app_router.dart';

class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  final _searchCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;
  bool _showCodeEntry = false;
  bool _isLoading = false;
  bool _requestSent = false;
  String? _requestedGroupId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final results = await service.searchGroupsByName(query);
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _requestAccess(GroupModel group) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = user.displayName ?? 'User';
    final phone = user.phoneNumber ?? '+254';
    setState(() { _requestSent = true; _requestedGroupId = group.id; });
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.sendJoinRequest(group.id, user.uid, name, phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${group.name}! Wait for chairman approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() { _requestSent = false; _requestedGroupId = null; });
      }
    }
  }

  Future<void> _findByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final group = await service.getGroupByInviteCode(code);
      if (!mounted) return;
      if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code')));
        setState(() => _isLoading = false);
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final membersSnapshot = await service.membersRef(group.id).get();
      final members = membersSnapshot.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      final matched = members.cast<Map<String, dynamic>?>().firstWhere(
        (m) => m?['phone'] == user.phoneNumber, orElse: () => null,
      );
      if (matched != null) {
        await service.updateMember(group.id, matched['id'] ?? '', {'userId': user.uid, 'status': 'active'});
        ref.read(currentGroupIdProvider.notifier).state = group.id;
        if (mounted) context.go(RouteNames.home);
      } else {
        await service.addMember(group.id, {
          'userId': user.uid, 'phone': user.phoneNumber ?? '', 'name': user.displayName ?? 'Member',
          'role': 'member', 'groupId': group.id, 'memberNumber': members.length + 1,
          'status': 'active', 'joinedAt': FieldValue.serverTimestamp(),
        });
        ref.read(currentGroupIdProvider.notifier).state = group.id;
        if (mounted) context.go(RouteNames.home);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join a Group', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showCodeEntry ? _buildCodeEntry() : _buildSearchView(),
    );
  }

  Widget _buildSearchView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search group name...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              suffixIcon: _isSearching
                  ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _search(''); })
                      : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (_, i) => _buildGroupCard(_searchResults[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton.icon(
            onPressed: () => setState(() => _showCodeEntry = true),
            icon: const Icon(Icons.keyboard, size: 18),
            label: const Text('Have an invite code? Enter Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Search for a group by name', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Or use the invite code below', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final visual = AppIllustrations.modelVisuals.values.firstWhere(
      (v) => v.title == group.name, orElse: () => AppIllustrations.modelVisuals['custom']!,
    );
    final isRequested = _requestSent && _requestedGroupId == group.id;
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: visual.imageUrl ?? 'https://picsum.photos/seed/group/200/200',
              width: 100, height: 100, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(width: 100, color: AppColors.primaryLight, child: Icon(Icons.group, color: AppColors.primary)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${group.stats.totalMembers} members', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isRequested
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : ElevatedButton(
                    onPressed: () => _requestAccess(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Request Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCodeEntry() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _showCodeEntry = false),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Search by name'),
          ),
          const SizedBox(height: 32),
          const Text('Enter Invite Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ask your group chairman for the code', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: 'MWANGA2026',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: AppButton(label: 'Find Group', onPressed: _codeCtrl.text.trim().isNotEmpty ? _findByCode : null, isLoading: _isLoading),
          ),
        ],
      ),
    );
  }
}
