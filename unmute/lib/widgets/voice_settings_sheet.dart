import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class VoiceSettingsSheet extends StatelessWidget {
  final double speechRate;
  final double pitch;
  final List<Map<String, String>> voices;
  final String? selectedVoice;
  final Function(double) onRateChanged;
  final Function(double) onPitchChanged;
  final Function(String) onVoiceChanged;

  const VoiceSettingsSheet({
    super.key,
    required this.speechRate,
    required this.pitch,
    required this.voices,
    required this.selectedVoice,
    required this.onRateChanged,
    required this.onPitchChanged,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: AppTheme.glassEffect,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildVoiceSelector(),
            const SizedBox(height: 20),
            _buildSlider(
              'Speech Rate',
              speechRate,
              0.0,
              1.0,
              onRateChanged,
            ),
            const SizedBox(height: 20),
            _buildSlider(
              'Pitch',
              pitch,
              0.5,
              2.0,
              onPitchChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Voice',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: selectedVoice,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: voices
                    .map((voice) => DropdownMenuItem(
                          value: voice['name'],
                          child: Text(voice['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    onVoiceChanged(value);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ],
    );
  }
}
