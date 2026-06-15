import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import 'generate_report_screen.dart';

class ReportListScreen extends ConsumerWidget {
  final String groupId;
  const ReportListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 180, height: 140,
              child: SvgPicture.network(
                AppIllustrations.goal,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Generate Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Export group data as PDF', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildReportCard(context, 'Monthly Summary', Icons.calendar_month, 'Income, expenses, and balance for a month'),
          _buildReportCard(context, 'Member Statement', Icons.person, 'Individual member contribution history'),
          _buildReportCard(context, 'Event Report', Icons.event, 'Contributions collected for a specific event'),
          _buildReportCard(context, 'Full Audit', Icons.assessment, 'Complete group financial history'),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, String subtitle) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => GenerateReportScreen(groupId: groupId, reportType: title),
        )),
      ),
    );
  }
}
