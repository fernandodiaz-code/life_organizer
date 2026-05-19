class WetFaceAlarm {
  const WetFaceAlarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final String id;
  final String label;
  final int hour;
  final int minute;
  final bool enabled;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

