class JobUpdateItem {
  JobUpdateItem({
    required this.id,
    required this.type,
    required this.message,
    required this.status,
    required this.occurredAt,
  });

  final String id;
  final String type;
  final String? message;
  final int? status;
  final DateTime occurredAt;

  factory JobUpdateItem.fromApi(Map<String, dynamic> json) {
    final rawOccurredAt = (json['occurredAt'] ?? '').toString();
    DateTime parsed;
    try {
      parsed = DateTime.parse(rawOccurredAt).toLocal();
    } catch (_) {
      parsed = DateTime.now();
    }

    return JobUpdateItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      message: json['message']?.toString(),
      status: json['status'] is int ? json['status'] as int : int.tryParse('${json['status']}'),
      occurredAt: parsed,
    );
  }
}
