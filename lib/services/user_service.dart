import 'dart:convert';

import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class UserService {
  UserService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<UserProfile?> fetchByFirebaseUid(String uid) async {
    if (!AppSession.isAuthenticated) {
      return null;
    }
    try {
      final response = await _apiClient.get('/api/Users/firebase/$uid');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromApi(data);
    } catch (_) {
      return null;
    }
  }
}
