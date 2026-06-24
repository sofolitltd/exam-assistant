import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/data/services/firestore_quiz_service.dart';


class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  int _examCount = 0;
  int _questionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final service = FirestoreQuizService();
      final exams = await service.getExams();
      final questions = await service.getQuestionCount();
      if (mounted) {
        setState(() {
          _examCount = exams.length;
          _questionCount = questions;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel'),
      leading: IconButton(
        icon: Icon(LucideIcons.home, size: 20,),
        onPressed: (){
          context.go('/');
        },
      ),
      ),
      body: ResponsiveWrapper(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildStatsBar(),
              const SizedBox(height: 32),
              _buildNavCard(
                icon: Icons.list_alt,
                title: 'Manage Exams',
                subtitle: 'View, edit, or delete existing exams',
                color: Colors.orange,
                onTap: () => _navigateToManageExams(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Row(
      children: [
        _statCard(Icons.book, _isLoading ? '-' : '$_examCount', 'Total Exams'),
        const SizedBox(width: 12),
        _statCard(
          Icons.help_outline,
          _isLoading ? '-' : '$_questionCount',
          'Total Questions',
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToManageExams() async {
    await context.push('/admin/exam');
    _loadStats();
  }
}
