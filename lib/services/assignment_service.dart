import 'dart:convert';

import '../constants/app_constants.dart';
import '../models/assignment.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class AssignmentService {
  AssignmentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<List<AssignmentSummary>> fetchAssignments({required DateTime start, required DateTime end}) async {
    if (!AppSession.isAuthenticated) {
      return demoAssignments;
    }

    final query = '?start=${Uri.encodeComponent(start.toUtc().toIso8601String())}'
        '&end=${Uri.encodeComponent(end.toUtc().toIso8601String())}';

    final response = await _apiClient.get('${AppConstants.assignmentsPath}$query');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return demoAssignments;
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AssignmentSummary.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> updateAssignmentStatus({
    required String assignmentId,
    required int status,
    DateTime? actualStart,
    DateTime? actualEnd,
  }) async {
    if (!AppSession.isAuthenticated) {
      return false;
    }

    final body = <String, dynamic>{
      'status': status,
      if (actualStart != null) 'actualStart': actualStart.toUtc().toIso8601String(),
      if (actualEnd != null) 'actualEnd': actualEnd.toUtc().toIso8601String(),
    };

    final response = await _apiClient.putJson('${AppConstants.assignmentsPath}/$assignmentId/status', body);
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
