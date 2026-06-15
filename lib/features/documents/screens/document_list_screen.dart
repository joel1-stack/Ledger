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
                  subtitle: Text('${DateHelpers.formatDate(doc.createdAt)} \u2022 ${doc.type}'),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewDocument(context, doc.title);
                          break;
                        case 'share':
                          _shareDocument(context, doc.title);
                          break;
                        case 'print':
                          _printDocument(context, doc.title);
                          break;
                        case 'delete':
                          _deleteDocument(context, ref, groupId, doc.id);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'), dense: true)),
                      const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'), dense: true)),
                      const PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print), title: Text('Print'), dense: true)),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error)), dense: true)),
                    ],
                  ),
                  onTap: () => _viewDocument(context, doc.title),
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
      case 'report': return Icons.bar_chart;
      case 'photo': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  void _uploadDocument(BuildContext context, WidgetRef ref, String groupId) {
    final titleCtrl = TextEditingController();
    String selectedType = 'other';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. June Meeting Minutes'),
            ),
            const SizedBox(height: 16),
            // ignore: deprecated_member_use
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
                DropdownMenuItem(value: 'report', child: Text('Report')),
                DropdownMenuItem(value: 'constitution', child: Text('Constitution')),
                DropdownMenuItem(value: 'photo', child: Text('Photo')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => selectedType = v ?? 'other',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(currentUserProvider);
              await ref.read(firestoreServiceProvider).addDocument(groupId, {
                'title': titleCtrl.text,
                'fileUrl': '',
                'type': selectedType,
                'uploadedBy': user?.uid ?? '',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document uploaded')),
                );
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
                SizedBox(height: 16),
                Text('Document viewer', style: TextStyle(color: AppColors.textSecondary)),
                Text('File preview coming soon', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton.icon(
            onPressed: () { Navigator.pop(ctx); },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  void _shareDocument(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing "$title"...')),
    );
  }

  void _printDocument(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printing "$title"...')),
    );
  }

  void _deleteDocument(BuildContext context, WidgetRef ref, String groupId, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
