import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../models/assignment.dart';
import '../../models/job_tracking_update.dart';
import '../../services/assignment_service.dart';
import '../../services/job_tracking_service.dart';
import '../../services/location_service.dart';
import '../../state/app_session.dart';
import '../messages_screen.dart';
import '../payments_screen.dart';
import '../../widgets/jobflow_app_bar.dart';
import '../../widgets/section_card.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.assignment});

  final AssignmentSummary assignment;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _trackingService = JobTrackingService();
  final _locationService = LocationService();
  final _assignmentService = AssignmentService();
  Timer? _liveTrackingTimer;
  bool _trackingLive = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    AppSession.activeAssignment = widget.assignment;
    _currentStatus = widget.assignment.status;
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCurrentLocation({bool showToast = true}) async {
    final employeeId = AppSession.employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee ID required for tracking updates.')),
        );
      }
      return;
    }

    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
      }
      return;
    }

    final payload = JobTrackingUpdateDto(
      jobId: widget.assignment.jobId,
      employeeId: employeeId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    final success = await _trackingService.sendLocationUpdate(payload);
    if (!mounted || !showToast) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'ETA update sent to client.' : 'Unable to send update.'),
      ),
    );
  }

  Future<void> _toggleLiveTracking() async {
    if (_trackingLive) {
      _liveTrackingTimer?.cancel();
      setState(() => _trackingLive = false);
      return;
    }

    await _sendCurrentLocation(showToast: false);
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _sendCurrentLocation(showToast: false);
    });
    setState(() => _trackingLive = true);
  }

  Future<void> _openDirections() async {
    final address = Uri.encodeComponent(widget.assignment.addressLine);
    final uri = Uri.parse('${AppConstants.googleMapsDirectionsBaseUrl}&destination=$address');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  Future<void> _updateStatus(int status, String label) async {
    final success = await _assignmentService.updateAssignmentStatus(
      assignmentId: widget.assignment.id,
      status: status,
      actualStart: status == 2 ? DateTime.now() : null,
      actualEnd: status == 3 ? DateTime.now() : null,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() => _currentStatus = label);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Status updated to $label.' : 'Unable to update status.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    return Scaffold(
      appBar: const JobFlowAppBar(title: 'Job details'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.jobTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(assignment.clientName),
                const SizedBox(height: 4),
                Text(assignment.addressLine),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(assignment.scheduledLabel)),
                    Chip(label: Text(_currentStatus)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jobflow actions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _currentStatus == 'InProgress'
                            ? null
                            : () => _updateStatus(2, 'InProgress'),
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: const Text('Start job'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _currentStatus == 'Completed'
                            ? null
                            : () => _updateStatus(3, 'Completed'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete job'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _sendCurrentLocation,
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('Send ETA update'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _toggleLiveTracking,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(_trackingLive ? 'Stop live tracking' : 'Start live tracking'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Open directions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Balance due: syncs from invoice data.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                    );
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Take payment'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messaging', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Send an update back to the office.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MessagesScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Message dispatch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
