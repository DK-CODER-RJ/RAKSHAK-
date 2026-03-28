import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/safety_controller.dart';
import '../widgets/status_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _contactsController = TextEditingController(
    text: '+911234567890,+919999999999',
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safetyControllerProvider);
    final controller = ref.read(safetyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Shurakshit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatusCard(
            title: 'Current Mode',
            value: state.mode.name,
            color: state.statusColor,
          ),
          if (state.lastEventSummary != null)
            StatusCard(
              title: 'Last Event',
              value: state.lastEventSummary!,
              color: Colors.blue,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactsController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Emergency Contacts (comma separated)',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Anonymous witness reporting'),
            value: state.anonymousWitness,
            onChanged: controller.setAnonymousWitness,
          ),
          FilledButton(
            onPressed: () {
              final contacts = _contactsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(growable: false);
              controller.setEmergencyContacts(contacts);
            },
            child: const Text('Save Contacts'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: controller.activateEmergency,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Emergency Mode'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: controller.activateWitness,
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Witness Mode'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Test Voice Keyword',
              hintText: 'help / bachao / witness mode',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () =>
                controller.simulateVoiceKeyword(_keywordController.text),
            child: const Text('Simulate Voice Trigger'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.syncNow,
            child: const Text('Sync Offline Events'),
          ),
          OutlinedButton(
            onPressed: controller.reset,
            child: const Text('Reset to Idle'),
          ),
        ],
      ),
    );
  }
}
