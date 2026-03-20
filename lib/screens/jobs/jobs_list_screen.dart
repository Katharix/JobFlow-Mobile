import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../models/assignment.dart';
import '../../services/assignment_service.dart';
import '../../state/app_session.dart';
import '../../widgets/jobflow_app_bar.dart';
import '../../widgets/section_card.dart';
import 'job_detail_screen.dart';

class JobsListScreen extends StatelessWidget {
  const JobsListScreen({super.key});

  String _formatSchedule(String raw) {
    try {
      final parsed = DateTime.parse(raw).toLocal();
      return DateFormat('EEE · h:mm a').format(parsed);
    } catch (_) {
      return raw.isEmpty ? 'Scheduled' : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JobFlowAppBar(title: 'Assignments'),
      body: FutureBuilder<List<AssignmentSummary>>(
        future: AssignmentService().fetchAssignments(
          start: DateTime.now().subtract(const Duration(days: 1)),
          end: DateTime.now().add(const Duration(days: 7)),
        ),
        builder: (context, snapshot) {
          final assignments = snapshot.data ?? demoAssignments;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: assignments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return GestureDetector(
                onTap: () {
                  AppSession.activeAssignment = assignment;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => JobDetailScreen(assignment: assignment)),
                  );
                },
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.jobTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('${assignment.clientName} · ${assignment.addressLine}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(_formatSchedule(assignment.scheduledLabel))),
                          Chip(label: Text(assignment.status)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
