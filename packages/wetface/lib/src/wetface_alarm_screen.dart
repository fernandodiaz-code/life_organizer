import 'package:flutter/material.dart';

import 'wetface_alarm.dart';
import 'wetface_validation_service.dart';

class WetFaceAlarmScreen extends StatefulWidget {
  const WetFaceAlarmScreen({super.key});

  @override
  State<WetFaceAlarmScreen> createState() => _WetFaceAlarmScreenState();
}

class _WetFaceAlarmScreenState extends State<WetFaceAlarmScreen> {
  final _validationService = const WetFaceValidationService();
  final _alarms = const [
    WetFaceAlarm(id: 'morning', label: 'Despertar WetFace', hour: 7, minute: 0),
  ];

  bool _validating = false;
  WetFaceValidationResult? _lastResult;

  Future<void> _runMockValidation() async {
    setState(() => _validating = true);
    final result = await _validationService.validateMock();
    if (!mounted) return;
    setState(() {
      _lastResult = result;
      _validating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('WetFace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Alarmas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          for (final alarm in _alarms)
            Card(
              child: ListTile(
                leading: Icon(Icons.water_drop, color: colorScheme.primary),
                title: Text(alarm.label),
                subtitle: Text('Programada a las ${alarm.formattedTime}'),
                trailing: Switch(value: alarm.enabled, onChanged: (_) {}),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _validating ? null : _runMockValidation,
            icon: _validating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_validating ? 'Validando...' : 'Simular selfie mojada'),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: colorScheme.primary),
                title: const Text('Validación mock aprobada'),
                subtitle: const Text(
                  'Sprint 1 deja listo el flujo visual; Gemini real va por Cloudflare en Sprint 2.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

