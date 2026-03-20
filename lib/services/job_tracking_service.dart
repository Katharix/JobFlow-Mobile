import '../constants/app_constants.dart';
import '../models/job_tracking_update.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class JobTrackingService {
  JobTrackingService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<bool> sendLocationUpdate(JobTrackingUpdateDto dto) async {
    if (AppSession.employeeId == null || AppSession.employeeId!.isEmpty) {
      return false;
    }

    final response = await _apiClient.postJson(
      AppConstants.jobTrackingUpdatePath,
      dto.toJson(),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
