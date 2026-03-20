class JobTrackingUpdateDto {
  JobTrackingUpdateDto({
    required this.jobId,
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final String jobId;
  final String employeeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'employeeId': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
