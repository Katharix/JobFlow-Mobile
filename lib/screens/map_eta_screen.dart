import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../services/location_service.dart';
import '../state/app_session.dart';
import '../widgets/jobflow_app_bar.dart';
import '../widgets/section_card.dart';

class MapEtaScreen extends StatelessWidget {
  const MapEtaScreen({super.key});

  Future<LatLng?> _loadCurrentLocation() async {
    final position = await LocationService().getCurrentPosition();
    if (position == null) {
      return null;
    }
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _openDirections(String address, BuildContext context) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('${AppConstants.googleMapsDirectionsBaseUrl}&destination=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JobFlowAppBar(title: 'Directions & ETA'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route overview', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FutureBuilder<LatLng?>(
                      future: _loadCurrentLocation(),
                      builder: (context, snapshot) {
                        final location = snapshot.data;
                        if (location == null) {
                          return Container(
                            color: const Color(0xFFE9EEF1),
                            child: const Center(
                              child: Text('Enable location to view the map.'),
                            ),
                          );
                        }

                        return GoogleMap(
                          initialCameraPosition: CameraPosition(target: location, zoom: 13),
                          markers: {
                            Marker(markerId: const MarkerId('me'), position: location),
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppSession.activeAssignment == null
                      ? 'Select a job to see the destination.'
                      : 'Next stop: ${AppSession.activeAssignment!.addressLine}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: AppSession.activeAssignment == null
                      ? null
                      : () => _openDirections(AppSession.activeAssignment!.addressLine, context),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Start navigation'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arrival status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('ETA updates send automatically from job tracking.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('Send manual ETA update'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
