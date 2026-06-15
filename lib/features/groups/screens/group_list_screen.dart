import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/models/group_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../router/app_router.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  final _searchCtrl = TextEditingController();
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = ref.watch(currentUserProvider);
    final groupsAsync = firebaseUser != null
        ? ref.watch(userGroupsProvider2(firebaseUser.uid))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_showSearch ? 'Search Groups' : 'Ledger'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchResults = [];
                _searchCtrl.clear();
              }
            }),
          ),
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go(RouteNames.landing);
              },
            ),
        ],
      ),
      body: _showSearch ? _buildSearchBody() : _buildMainBody(groupsAsync),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.groupModel),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.createGroup),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinDialog(context, ref),
                    icon: const Icon(Icons.login),
                    label: const Text(AppStrings.joinGroup),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by group name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() {}),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        if (_isSearching)
          const AppLoading()
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              itemBuilder: (_, i) {
                final group = _searchResults[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(group.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${group.stats.totalMembers} members'),
                    trailing: TextButton(
                      onPressed: () => _requestToJoin(group),
                      child: const Text('Request to Join', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          )
        else if (_searchCtrl.text.isNotEmpty)
          const Expanded(
            child: Center(child: Text('No groups found with that name')),
          )
        else
          const Expanded(
            child: Center(child: Text('Type a group name to search')),
          ),
      ],
    );
  }

  Widget _buildMainBody(AsyncValue<List<GroupModel>>? groupsAsync) {
    if (groupsAsync == null || groupsAsync is AsyncLoading) {
      return _buildEmptyState();
    }
    return groupsAsync.when(
      data: (groups) => groups.isEmpty
          ? _buildEmptyState()
          : _buildGroupsList(context, ref, groups),
      loading: () => const AppLoading(),
      error: (_, _) => _buildEmptyState(),
    );
  }

  Widget _buildGroupsList(BuildContext context, WidgetRef ref, List<GroupModel> groups) {
    if (groups.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final group = groups[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(group.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${group.stats.totalMembers} members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(currentGroupIdProvider.notifier).state = group.id;
              context.go(RouteNames.home);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                AppIllustrations.people,
                width: 200, height: 200, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const Text(AppStrings.noGroups, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppStrings.noGroupsSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.joinGroup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(hintText: 'Enter invite code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Text('Ask the group chairman for the invite code to join.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(firestoreServiceProvider);
              final group = await service.getGroupByInviteCode(code);
              if (!context.mounted) return;
              if (group == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid invite code')),
                );
                return;
              }
              _showJoinConfirmDialog(context, ref, group);
            },
            child: const Text('Look Up'),
          ),
        ],
      ),
    );
  }

  void _showJoinConfirmDialog(BuildContext context, WidgetRef ref, GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Join ${group.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(group.name[0].toUpperCase()),
            ),
            const SizedBox(height: 16),
            Text('${group.name}\n${group.stats.totalMembers} members'),
            const SizedBox(height: 16),
            Text('Your request will be sent to the group admin for approval.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Join request sent to ${group.name}')),
              );
            },
            child: const Text('Request to Join'),
          ),
        ],
      ),
    );
  }

  void _requestToJoin(GroupModel group) {
    _showJoinConfirmDialog(context, ref, group);
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('groups')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      final results = snap.docs
          .map((doc) => GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }
}
