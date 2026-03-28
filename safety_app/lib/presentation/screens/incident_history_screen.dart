import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_app/core/constants/app_colors.dart';
import 'package:safety_app/presentation/providers/data_providers.dart';
import 'package:intl/intl.dart';

class IncidentHistoryScreen extends ConsumerStatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  ConsumerState<IncidentHistoryScreen> createState() =>
      _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends ConsumerState<IncidentHistoryScreen> {
  String _formatIsoDate(String? isoString) {
    if (isoString == null) return "Unknown Date";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy, h:mm a').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident History"),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Incident History",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              incidentsAsync.when(
                data: (incidents) => Text(
                  "${incidents.length} incident${incidents.length == 1 ? '' : 's'} recorded",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                loading: () =>
                    const Text("Loading...", style: TextStyle(fontSize: 16)),
                error: (e, st) => const Text("Error loading history",
                    style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: incidentsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen)),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (incidents) {
                    if (incidents.isEmpty) {
                      return const Center(
                          child: Text("No incidents recorded yet."));
                    }
                    return ListView.separated(
                      itemCount: incidents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final data = incidents[index];
                        final docId = data["id"] ?? "";

                        final type = data["type"] ?? "UNKNOWN";
                        final isWitness = type == "WITNESS";
                        const iconColor = AppColors.primaryGreen;
                        final displayIcon = isWitness
                            ? Icons.remove_red_eye_outlined
                            : Icons.shield_outlined;

                        // Handle structured location data
                        String locationStr = "Unknown location";
                        if (data['location'] is Map) {
                          locationStr =
                              data['location']['address'] ?? "Unknown address";
                        }

                        String policeStr = "Unknown police station";
                        if (data['police_station'] is Map) {
                          policeStr = data['police_station']['name'] ??
                              "Unknown station";
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: iconColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(displayIcon,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            type == "WITNESS"
                                                ? "Witness Report"
                                                : "Emergency Mode",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            (data["status"] ?? "UNKNOWN")
                                                .toString()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.grey, size: 20),
                                          onPressed: () async {
                                            await ref
                                                .read(
                                                    incidentRepositoryProvider)
                                                .deleteIncident(docId);
                                            ref.invalidate(
                                                incidentsFutureProvider);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildIconText(
                                        Icons.calendar_today_outlined,
                                        _formatIsoDate(data["timestamp"])),
                                    const SizedBox(height: 4),
                                    _buildIconText(Icons.location_on_outlined,
                                        locationStr),
                                    const SizedBox(height: 8),
                                    Text(
                                      policeStr,
                                      style: const TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
