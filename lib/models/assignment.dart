class AssignmentSummary {
  AssignmentSummary({
    required this.id,
    required this.jobId,
    required this.organizationClientId,
    required this.jobTitle,
    required this.clientName,
    required this.addressLine,
    required this.scheduledLabel,
    required this.status,
  });

  final String id;
  final String jobId;
  final String organizationClientId;
  final String jobTitle;
  final String clientName;
  final String addressLine;
  final String scheduledLabel;
  final String status;

  factory AssignmentSummary.fromApi(Map<String, dynamic> json) {
    final addressParts = [
      json['address1'] as String?,
      json['city'] as String?,
      json['state'] as String?,
      json['zipCode'] as String?
    ].where((part) => part != null && part.trim().isNotEmpty).map((part) => part!).toList();

    final rawStatus = json['status'];
    final statusLabel = _formatStatus(rawStatus);

    return AssignmentSummary(
      id: (json['id'] ?? '').toString(),
      jobId: (json['jobId'] ?? '').toString(),
      organizationClientId: (json['organizationClientId'] ?? '').toString(),
      jobTitle: (json['jobTitle'] ?? 'Job').toString(),
      clientName: (json['clientName'] ?? 'Client').toString(),
      addressLine: addressParts.isEmpty ? 'Address unavailable' : addressParts.join(', '),
      scheduledLabel: (json['scheduledStart'] ?? '').toString(),
      status: statusLabel,
    );
  }

  static String _formatStatus(dynamic status) {
    if (status == null) {
      return 'Scheduled';
    }

    if (status is int) {
      return _statusFromInt(status);
    }

    final statusString = status.toString();
    final parsed = int.tryParse(statusString);
    if (parsed != null) {
      return _statusFromInt(parsed);
    }

    return statusString.isEmpty ? 'Scheduled' : statusString;
  }

  static String _statusFromInt(int status) {
    switch (status) {
      case 1:
        return 'Scheduled';
      case 2:
        return 'InProgress';
      case 3:
        return 'Completed';
      case 4:
        return 'Skipped';
      case 5:
        return 'Canceled';
      default:
        return 'Scheduled';
    }
  }
}

final List<AssignmentSummary> demoAssignments = [
  AssignmentSummary(
    id: 'f12a6f84-9999-4f6f-a1be-3f8b2c542b11',
    jobId: '6f1c6a36-5555-4b2a-8f0c-4930b66552f1',
    organizationClientId: '1f6a6f84-2222-4f6f-a1be-3f8b2c542b11',
    jobTitle: 'Water Heater Replacement',
    clientName: 'Alex Rivera',
    addressLine: '1526 Olive St, Lincoln',
    scheduledLabel: 'Today · 2:30 PM',
    status: 'Scheduled',
  ),
  AssignmentSummary(
    id: 'b2e4f1a9-1111-4ad2-8b7b-5c2f95c24e20',
    jobId: '9b03f872-4444-4fe9-9e0d-7a4fcd11db13',
    organizationClientId: '8c2f1a9b-3333-4ad2-8b7b-5c2f95c24e20',
    jobTitle: 'HVAC Tune-Up',
    clientName: 'Jordan Lee',
    addressLine: '83 Pine Ridge Dr, Lincoln',
    scheduledLabel: 'Today · 4:15 PM',
    status: 'Scheduled',
  ),
];
