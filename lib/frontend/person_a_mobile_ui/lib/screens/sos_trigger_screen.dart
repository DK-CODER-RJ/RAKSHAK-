import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/sos_state_provider.dart';

/// SOS Trigger Screen — Emergency Mode activation.
/// Full red background with shield icon, feature list, and activate button.
class SosTriggerScreen extends StatefulWidget {
  const SosTriggerScreen({super.key});

  @override
  State<SosTriggerScreen> createState() => _SosTriggerScreenState();
}

class _SosTriggerScreenState extends State<SosTriggerScreen> {

  Future<void> _handleSosAction(SosStateProvider provider) async {
    if (provider.isActive) {
      // Just cancel SOS directly — no PIN needed
      await provider.cancelSos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Cancelled. You are safe now.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await provider.triggerSos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Protocol Activated! Alerting contacts...'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SosStateProvider>(
      builder: (context, provider, child) {
        final bool isActivated = provider.isActive;
        
        return Scaffold(
          backgroundColor: isActivated ? Colors.black87 : const Color(0xFFD32F2F),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isActivated ? 'SOS ACTIVE' : 'Emergency Mode',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Shield icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isActivated ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: isActivated ? Colors.redAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    isActivated ? 'TRANSMITTING...\n${_formatTime(provider.elapsedSeconds)}' : 'Emergency Mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isActivated ? Colors.redAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isActivated)
                    Text(
                      'Tap the button below to activate\nemergency mode instantly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  if (isActivated)
                    Text(
                      'Live Location Sharing Active\nAudio Recording Active\nSMS sent to Emergency Contacts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.greenAccent.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Feature list card
                  if (!isActivated)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          _FeatureRow(
                            icon: Icons.mic_outlined,
                            label: 'Audio Recording',
                          ),
                          SizedBox(height: 16),
                          _FeatureRow(
                            icon: Icons.location_on_outlined,
                            label: 'Live Location via SMS',
                          ),
                          SizedBox(height: 16),
                          _FeatureRow(
                            icon: Icons.sms_outlined,
                            label: 'Auto SMS to Contacts',
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Activate / Cancel button — single tap
                  GestureDetector(
                    onTap: () => _handleSosAction(provider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isActivated ? Colors.white12 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isActivated ? Border.all(color: Colors.redAccent) : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isActivated ? Icons.stop_circle_outlined : Icons.shield_outlined,
                            size: 40,
                            color: isActivated
                                ? Colors.redAccent
                                : const Color(0xFFD32F2F),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isActivated ? 'TAP TO CANCEL SOS' : 'TAP TO ACTIVATE\nEMERGENCY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isActivated
                                  ? Colors.redAccent
                                  : const Color(0xFFD32F2F),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Voice commands: Say "Help" or "Bachao" 3 times',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
