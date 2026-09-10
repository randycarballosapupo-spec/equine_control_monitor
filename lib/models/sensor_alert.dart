enum AlertType { environmental, physiological }

enum AlertSeverity { warning, critical }

class SensorAlert {
  const SensorAlert({
    required this.type,
    required this.severity,
    required this.horseId,
    required this.sensor,
    required this.value,
    required this.threshold,
    required this.message,
    required this.createdAt,
  });

  final AlertType type;
  final AlertSeverity severity;
  final String horseId;
  final String sensor;
  final double value;
  final double threshold;
  final String message;
  final DateTime createdAt;

  bool get isEnvironmental => type == AlertType.environmental;
  bool get isPhysiological => type == AlertType.physiological;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'severity': severity.name,
        'horseId': horseId,
        'sensor': sensor,
        'value': value,
        'threshold': threshold,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };
}
