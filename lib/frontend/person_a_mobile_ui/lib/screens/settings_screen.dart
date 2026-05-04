import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/settings_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/auth_provider.dart';

/// Settings Screen — App configuration with toggles.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showChangePinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change SOS PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'New 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length == 4) {
                await context.read<SettingsProvider>().setSosPin(pinController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SOS PIN updated successfully')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showKeywordsDialog(SettingsProvider settings) {
    final controller = TextEditingController(text: settings.voiceKeywords.join(', '));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Trigger Keywords'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter keywords separated by commas (e.g., help, bachao, emergency).', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Keywords',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final keywords = controller.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              await settings.updateVoiceKeywords(keywords);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS Keywords updated successfully')),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
            style: TextStyle(color: Color(0xFF1A1C1C), fontWeight: FontWeight.w600)),
      ),
      body: settings.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1C))),
                const SizedBox(height: 24),
                _sectionTitle('Safety Features'),
                const SizedBox(height: 12),
                _toggleTile('Voice Activation', 'Say "Help" or "Bachao" to trigger SOS',
                    Icons.mic_outlined, settings.voiceActivation, (v) => settings.toggleVoiceActivation(v)),
                _toggleTile('Shake Detection', 'Shake phone vigorously to trigger SOS',
                    Icons.vibration, settings.shakeDetection, (v) => settings.toggleShakeDetection(v)),
                _toggleTile('Night Mode Alerts', 'Alert when leaving safe zone at night',
                    Icons.nightlight_outlined, settings.nightModeAlerts, (v) => settings.toggleNightModeAlerts(v)),
                _toggleTile('Background Guardian', 'Keep safety monitoring active',
                    Icons.shield_outlined, settings.backgroundService, (v) => settings.toggleBackgroundService(v)),
                GestureDetector(
                  onTap: () => _showKeywordsDialog(settings),
                  child: _actionTile('SOS Keywords', 'Manage voice trigger words (${settings.voiceKeywords.join(", ")})', Icons.keyboard_voice),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Security'),
                const SizedBox(height: 12),
                _toggleTile('Biometric Lock', 'Require fingerprint to cancel SOS',
                    Icons.fingerprint, settings.biometricLock, (v) => settings.toggleBiometricLock(v)),
                GestureDetector(
                  onTap: _showChangePinDialog,
                  child: _actionTile('Change SOS PIN', 'Update your 4-digit cancellation PIN', Icons.lock_outlined),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Account'),
                const SizedBox(height: 12),
                _actionTile('Profile', 'Edit your personal information', Icons.person_outlined),
                _actionTile('Privacy Policy', 'Read our privacy policy', Icons.privacy_tip_outlined),
                _actionTile('About RAKSHAK', 'Version 1.0.0', Icons.info_outlined),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1976D2)));
  }

  Widget _toggleTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1A1C1C), size: 22),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF388E3C)),
      ]),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1A1C1C), size: 22),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ])),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ]),
    );
  }
}

