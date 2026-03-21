import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../models/job_update.dart';
import '../models/job_update_request.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class JobUpdateService {
  JobUpdateService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<bool> sendNoteUpdate({
    required String jobId,
    required String message,
  }) {
    return _sendUpdate(
      jobId,
      JobUpdateRequest(type: JobUpdateType.note, message: message),
    );
  }

  Future<bool> sendStatusUpdate({
    required String jobId,
    required int status,
  }) {
    return _sendUpdate(
      jobId,
      JobUpdateRequest(type: JobUpdateType.statusChange, status: status),
    );
  }

  Future<bool> sendPhotoUpdate({
    required String jobId,
    required XFile photo,
  }) async {
    if (!AppSession.isAuthenticated) {
      return false;
    }

    final fields = _buildFields(JobUpdateRequest(type: JobUpdateType.photo));
    final fileName = photo.name.isNotEmpty ? photo.name : 'job_update.jpg';
    final contentType = _resolveContentType(fileName);

    final file = await http.MultipartFile.fromPath(
      'attachments',
      photo.path,
      filename: fileName,
      contentType: contentType,
    );

    final response = await _apiClient.postMultipart(
      '${AppConstants.jobUpdatesPath}/$jobId/updates',
      fields: fields,
      files: [file],
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> sendPhotoUpdateFromPath({
    required String jobId,
    required String filePath,
  }) async {
    if (!AppSession.isAuthenticated) {
      return false;
    }

    final fileName = filePath.split('/').last;
    final contentType = _resolveContentType(fileName);

    final file = await http.MultipartFile.fromPath(
      'attachments',
      filePath,
      filename: fileName,
      contentType: contentType,
    );

    final response = await _apiClient.postMultipart(
      '${AppConstants.jobUpdatesPath}/$jobId/updates',
      fields: _buildFields(JobUpdateRequest(type: JobUpdateType.photo)),
      files: [file],
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<JobUpdateItem>> fetchJobUpdates({required String jobId}) async {
    if (!AppSession.isAuthenticated) {
      return [];
    }

    final response = await _apiClient.get('${AppConstants.jobUpdatesPath}/$jobId/updates');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => JobUpdateItem.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> _sendUpdate(String jobId, JobUpdateRequest request) async {
    if (!AppSession.isAuthenticated) {
      return false;
    }

    final response = await _apiClient.postMultipart(
      '${AppConstants.jobUpdatesPath}/$jobId/updates',
      fields: _buildFields(request),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Map<String, String> _buildFields(JobUpdateRequest request) {
    return {
      'type': request.type.toString(),
      if (request.message != null) 'message': request.message!.trim(),
      if (request.status != null) 'status': request.status!.toString(),
    };
  }

  MediaType _resolveContentType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (ext.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
