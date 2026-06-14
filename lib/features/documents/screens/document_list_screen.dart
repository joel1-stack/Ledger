import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/other_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';

class DocumentListScreen extends ConsumerWidget {
  final String groupId;
  const DocumentListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _uploadDocument(context, ref, groupId),
          ),
        ],
      ),
      body: documents.when(
        data: (data) {
          if (data.isEmpty) {
            return const AppEmptyState(title: 'No Documents', subtitle: 'Upload receipts, minutes, and reports');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final doc = data[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(_docIcon(doc.type), color: AppColors.primary),
                  ),
                  title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateHelpers.formatDate(doc.createdAt)),
                  trailing: const Icon(Icons.download_outlined),
                  onTap: () {},
                ),
              );
            },
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'receipt': return Icons.receipt;
      case 'minutes': return Icons.description;
      case 'constitution': return Icons.gavel;
      default: return Icons.insert_drive_file;
    }
  }

  void _uploadDocument(BuildContext context, WidgetRef ref, String groupId) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Document'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. June Meeting Minutes')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(currentUserProvider);
              await ref.read(firestoreServiceProvider).addDocument(groupId, {
                'title': titleCtrl.text,
                'fileUrl': '',
                'type': 'other',
                'uploadedBy': user?.uid ?? '',
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}
