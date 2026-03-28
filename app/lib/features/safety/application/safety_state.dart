import 'package:flutter/material.dart';

import '../domain/entities/safety_mode.dart';

class SafetyState {
  const SafetyState({
    this.mode = SafetyMode.idle,
    this.lastEventSummary,
    this.isListening = false,
    this.anonymousWitness = true,
    this.emergencyContacts = const [],
  });

  final SafetyMode mode;
  final String? lastEventSummary;
  final bool isListening;
  final bool anonymousWitness;
  final List<String> emergencyContacts;

  Color get statusColor => switch (mode) {
        SafetyMode.idle => Colors.green,
        SafetyMode.emergency => Colors.red,
        SafetyMode.witness => Colors.orange,
      };

  SafetyState copyWith({
    SafetyMode? mode,
    String? lastEventSummary,
    bool? isListening,
    bool? anonymousWitness,
    List<String>? emergencyContacts,
  }) {
    return SafetyState(
      mode: mode ?? this.mode,
      lastEventSummary: lastEventSummary ?? this.lastEventSummary,
      isListening: isListening ?? this.isListening,
      anonymousWitness: anonymousWitness ?? this.anonymousWitness,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
