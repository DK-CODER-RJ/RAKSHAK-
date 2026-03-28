import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safety_app/core/constants/app_colors.dart';
import 'package:safety_app/presentation/providers/emergency_viewmodel.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(emergencyViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0b0f0c),
      appBar: AppBar(
        title: const Text("Emergency Mode"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ── Pulsing SOS Circle ──
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring 3
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2000.ms)
                                .fade(begin: 0.5, end: 0.0, duration: 2000.ms),
                            // Outer pulse ring 2
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.15, 1.15), duration: 1800.ms, delay: 300.ms)
                                .fade(begin: 0.6, end: 0.0, duration: 1800.ms, delay: 300.ms),
                            // Inner glow circle
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryGreen.withValues(alpha: 0.3),
                                    AppColors.primaryGreen.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.1, 1.1), duration: 1200.ms),
                            // Core circle with icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryGreen,
                                    Color(0xFF0E8C3A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shield,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fade().scale(begin: const Offset(0.5, 0.5)),

                      const SizedBox(height: 28),

                      // Title
                      const Text(
                        "Emergency Mode",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ).animate(delay: 300.ms).fade().slideY(begin: 0.2),

                      const SizedBox(height: 10),

                      Text(
                        'Tap the button below or say "Help" or\n"Emergency" to activate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ).animate(delay: 350.ms).fade(),

                      const SizedBox(height: 32),

                      // ── Feature Status Cards ──
                      const _FeatureStatusCard(
                        icon: Icons.mic_none_rounded,
                        title: "Audio Recording",
                        subtitle: "Ready to capture",
                        iconColor: AppColors.primaryGreen,
                      ).animate(delay: 400.ms).fade().slideX(begin: -0.1),

                      const SizedBox(height: 12),

                      const _FeatureStatusCard(
                        icon: Icons.location_on_outlined,
                        title: "Live Location Sharing",
                        subtitle: "GPS active",
                        iconColor: AppColors.primaryGreen,
                      ).animate(delay: 500.ms).fade().slideX(begin: -0.1),

                      const SizedBox(height: 12),

                      const _FeatureStatusCard(
                        icon: Icons.sms_outlined,
                        title: "SMS Alerts",
                        subtitle: "Contacts configured",
                        iconColor: AppColors.primaryGreen,
                      ).animate(delay: 600.ms).fade().slideX(begin: -0.1),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Loading/Error states
              if (emergencyState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Activating emergency...",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              if (emergencyState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFff7351).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Error: ${emergencyState.error}",
                      style: const TextStyle(
                        color: Color(0xFFff7351),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // ── Activate Button ──
              GestureDetector(
                onTap: () {
                  if (!emergencyState.isLoading) {
                    ref
                        .read(emergencyViewModelProvider.notifier)
                        .triggerEmergency();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryGreen,
                        Color(0xFF0E8C3A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.shield, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text(
                        "ACTIVATE EMERGENCY",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 700.ms).fade().slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Voice commands hint
              Text(
                'Voice commands: "Help", "Bachao", "Emergency"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ).animate(delay: 800.ms).fade(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _FeatureStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b17),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
