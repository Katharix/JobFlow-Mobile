class JobUpdateRequest {
  JobUpdateRequest({
    required this.type,
    this.message,
    this.status,
  });

  final int type;
  final String? message;
  final int? status;
}

class JobUpdateType {
  static const int note = 0;
  static const int statusChange = 1;
  static const int photo = 2;
  static const int system = 3;
}
