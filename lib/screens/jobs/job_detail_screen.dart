import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../models/assignment.dart';
import '../../models/job_tracking_update.dart';
import '../../models/job_update.dart';
import '../../models/job_update_request.dart';
import '../../services/assignment_service.dart';
import '../../services/job_update_service.dart';
import '../../services/job_update_queue_service.dart';
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
  final _jobUpdateService = JobUpdateService();
  final _jobUpdateQueue = JobUpdateQueueService();
  final _imagePicker = ImagePicker();
  Timer? _liveTrackingTimer;
  bool _trackingLive = false;
  bool _sendingUpdate = false;
  final _noteController = TextEditingController();
  late String _currentStatus;
  bool _loadingUpdates = true;
  List<JobUpdateItem> _recentUpdates = [];
  int _queuedUpdates = 0;

  @override
  void initState() {
    super.initState();
    AppSession.activeAssignment = widget.assignment;
    _currentStatus = widget.assignment.status;
    _loadRecentUpdates();
    _flushQueuedUpdates();
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    _noteController.dispose();
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

  Future<void> _sendNoteUpdate() async {
    final message = _noteController.text.trim();
    if (message.isEmpty || _sendingUpdate) return;

    setState(() => _sendingUpdate = true);
    final success = await _jobUpdateService.sendNoteUpdate(
      jobId: widget.assignment.jobId,
      message: message,
    );

    if (mounted) {
      setState(() => _sendingUpdate = false);
      if (success) {
        _noteController.clear();
        await _loadRecentUpdates();
      } else {
        await _jobUpdateQueue.enqueue(JobUpdateQueueItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          jobId: widget.assignment.jobId,
          type: JobUpdateType.note,
          message: message,
          createdAt: DateTime.now(),
        ));
        await _refreshQueueCount();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Update sent to client.' : 'Offline: update queued for sync.',
          ),
        ),
      );
    }
  }

  Future<void> _sendPhotoUpdate(ImageSource source) async {
    if (_sendingUpdate) return;

    final photo = await _imagePicker.pickImage(source: source, imageQuality: 75);
    if (photo == null) return;

    setState(() => _sendingUpdate = true);
    final success = await _jobUpdateService.sendPhotoUpdate(
      jobId: widget.assignment.jobId,
      photo: photo,
    );

    if (mounted) {
      setState(() => _sendingUpdate = false);
      if (success) {
        await _loadRecentUpdates();
      } else {
        await _jobUpdateQueue.enqueue(JobUpdateQueueItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          jobId: widget.assignment.jobId,
          type: JobUpdateType.photo,
          filePath: photo.path,
          createdAt: DateTime.now(),
        ));
        await _refreshQueueCount();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Photo shared with client.' : 'Offline: photo queued for sync.',
          ),
        ),
      );
    }
  }

  Future<void> _sendStatusUpdate(int status, String label) async {
    if (_sendingUpdate) return;

    setState(() => _sendingUpdate = true);
    final success = await _jobUpdateService.sendStatusUpdate(
      jobId: widget.assignment.jobId,
      status: status,
    );

    if (mounted) {
      setState(() => _sendingUpdate = false);
      if (success) {
        await _loadRecentUpdates();
      } else {
        await _jobUpdateQueue.enqueue(JobUpdateQueueItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          jobId: widget.assignment.jobId,
          type: JobUpdateType.statusChange,
          status: status,
          createdAt: DateTime.now(),
        ));
        await _refreshQueueCount();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Client updated: $label.' : 'Offline: status queued for sync.',
          ),
        ),
      );
    }
  }

  Future<void> _flushQueuedUpdates() async {
    final sent = await _jobUpdateQueue.flushQueue();
    await _refreshQueueCount();

    if (!mounted || sent == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent $sent queued update${sent == 1 ? '' : 's'} to clients.')),
    );
    await _loadRecentUpdates();
  }

  Future<void> _refreshQueueCount() async {
    final count = await _jobUpdateQueue.getQueueCount();
    if (!mounted) return;
    setState(() => _queuedUpdates = count);
  }

  Future<void> _loadRecentUpdates() async {
    setState(() => _loadingUpdates = true);
    final updates = await _jobUpdateService.fetchJobUpdates(jobId: widget.assignment.jobId);
    if (!mounted) return;
    setState(() {
      _recentUpdates = updates.take(6).toList();
      _loadingUpdates = false;
    });
  }

  String _formatUpdateTime(DateTime time) {
    return DateFormat('MMM d, h:mm a').format(time);
  }

  String _formatUpdateType(JobUpdateItem item) {
    final raw = item.type.toLowerCase();
    if (raw.contains('photo')) {
      return 'Photo update';
    }
    if (raw.contains('status')) {
      return 'Status update';
    }
    return 'Note';
  }

  void _openNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick note', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add a quick update for the client... ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendingUpdate
                      ? null
                      : () async {
                          await _sendNoteUpdate();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: Text(_sendingUpdate ? 'Sending...' : 'Send update'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _openPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share a photo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sendPhotoUpdate(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _sendPhotoUpdate(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openStatusSheet() {
    const options = [
      {'label': 'In progress', 'value': 2},
      {'label': 'Completed', 'value': 3},
      {'label': 'Cancelled', 'value': 4},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share status update', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...options.map((option) {
                return ListTile(
                  title: Text(option['label'] as String),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _sendStatusUpdate(option['value'] as int, option['label'] as String);
                  },
                );
              }),
            ],
          ),
        );
      },
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
                Text('Quick update', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Send a note, photo, or status update in seconds.'),
                if (_queuedUpdates > 0) ...[
                  const SizedBox(height: 8),
                  Text('Queued updates: $_queuedUpdates'),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _sendingUpdate ? null : _openNoteSheet,
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('Add note'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sendingUpdate ? null : _openPhotoSheet,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Add photo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sendingUpdate ? null : _openStatusSheet,
                      icon: const Icon(Icons.sync_alt_outlined),
                      label: const Text('Status update'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _sendingUpdate ? null : _flushQueuedUpdates,
                      icon: const Icon(Icons.sync_outlined),
                      label: const Text('Sync queued'),
                    ),
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
                Text('Recent updates', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_loadingUpdates)
                  const Text('Loading updates...')
                else if (_recentUpdates.isEmpty)
                  const Text('No updates shared yet.')
                else
                  Column(
                    children: _recentUpdates
                        .map(
                          (update) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_formatUpdateType(update)),
                            subtitle: Text(
                              update.message?.isNotEmpty == true
                                  ? update.message!
                                  : 'Shared at ${_formatUpdateTime(update.occurredAt)}',
                            ),
                            trailing: Text(_formatUpdateTime(update.occurredAt)),
                          ),
                        )
                        .toList(),
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
