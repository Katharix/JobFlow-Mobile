import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_update_request.dart';
import 'job_update_service.dart';

class JobUpdateQueueItem {
  JobUpdateQueueItem({
    required this.id,
    required this.jobId,
    required this.type,
    this.message,
    this.status,
    this.filePath,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final int type;
  final String? message;
  final int? status;
  final String? filePath;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'type': type,
      'message': message,
      'status': status,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JobUpdateQueueItem.fromJson(Map<String, dynamic> json) {
    return JobUpdateQueueItem(
      id: (json['id'] ?? '').toString(),
      jobId: (json['jobId'] ?? '').toString(),
      type: json['type'] is int ? json['type'] as int : int.tryParse('${json['type']}') ?? 0,
      message: json['message']?.toString(),
      status: json['status'] is int ? json['status'] as int : int.tryParse('${json['status']}'),
      filePath: json['filePath']?.toString(),
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }
}

class JobUpdateQueueService {
  JobUpdateQueueService({JobUpdateService? updateService})
      : _updateService = updateService ?? JobUpdateService();

  static const _storageKey = 'jobflow.offline.job_updates';
  final JobUpdateService _updateService;

  Future<int> getQueueCount() async {
    final items = await _loadQueue();
    return items.length;
  }

  Future<void> enqueue(JobUpdateQueueItem item) async {
    final queue = await _loadQueue();
    queue.add(item);
    await _saveQueue(queue);
  }

  Future<int> flushQueue() async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return 0;

    final remaining = <JobUpdateQueueItem>[];
    var sentCount = 0;

    for (final item in queue) {
      final success = await _sendItem(item);
      if (success) {
        sentCount += 1;
      } else {
        remaining.add(item);
      }
    }

    await _saveQueue(remaining);
    return sentCount;
  }

  Future<bool> _sendItem(JobUpdateQueueItem item) async {
    switch (item.type) {
      case JobUpdateType.note:
        if (item.message == null || item.message!.isEmpty) return false;
        return _updateService.sendNoteUpdate(jobId: item.jobId, message: item.message!);
      case JobUpdateType.statusChange:
        if (item.status == null) return false;
        return _updateService.sendStatusUpdate(jobId: item.jobId, status: item.status!);
      case JobUpdateType.photo:
        if (item.filePath == null || item.filePath!.isEmpty) return false;
        return _updateService.sendPhotoUpdateFromPath(jobId: item.jobId, filePath: item.filePath!);
      default:
        return false;
    }
  }

  Future<List<JobUpdateQueueItem>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => JobUpdateQueueItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<JobUpdateQueueItem> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(queue.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
