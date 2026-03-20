class JobSummary {
  JobSummary({
    required this.id,
    required this.title,
    required this.clientName,
    required this.address,
    required this.scheduledLabel,
    required this.destinationLat,
    required this.destinationLng,
    required this.currentLat,
    required this.currentLng,
    required this.balanceDue,
  });

  final String id;
  final String title;
  final String clientName;
  final String address;
  final String scheduledLabel;
  final double destinationLat;
  final double destinationLng;
  final double currentLat;
  final double currentLng;
  final double balanceDue;
}

final List<JobSummary> mockJobs = [
  JobSummary(
    id: 'f12a6f84-9999-4f6f-a1be-3f8b2c542b11',
    title: 'Water Heater Replacement',
    clientName: 'Alex Rivera',
    address: '1526 Olive St, Lincoln',
    scheduledLabel: 'Today · 2:30 PM',
    destinationLat: 40.8152,
    destinationLng: -96.7024,
    currentLat: 40.8001,
    currentLng: -96.6753,
    balanceDue: 425.00,
  ),
  JobSummary(
    id: 'b2e4f1a9-1111-4ad2-8b7b-5c2f95c24e20',
    title: 'HVAC Tune-Up',
    clientName: 'Jordan Lee',
    address: '83 Pine Ridge Dr, Lincoln',
    scheduledLabel: 'Today · 4:15 PM',
    destinationLat: 40.7894,
    destinationLng: -96.7131,
    currentLat: 40.7812,
    currentLng: -96.7042,
    balanceDue: 180.00,
  ),
];
