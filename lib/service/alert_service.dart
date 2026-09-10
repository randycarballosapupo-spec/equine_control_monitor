import '../models/sensor_alert.dart';
import '../models/sensor_reading.dart';

class AlertService {
  const AlertService._();

  static const ammoniaWarning = 10.0;
  static const ammoniaCritical = 25.0;
  static const airQualityWarning = 50.0;
  static const humidityWarning = 85.0;

  static List<SensorAlert> environmentalAlerts(SensorReading reading) {
    final alerts = <SensorAlert>[];
    if (reading.ammonia >= ammoniaCritical) {
      alerts.add(_environmental(reading, 'ammonia', reading.ammonia, ammoniaCritical, AlertSeverity.critical));
    } else if (reading.ammonia >= ammoniaWarning) {
      alerts.add(_environmental(reading, 'ammonia', reading.ammonia, ammoniaWarning, AlertSeverity.warning));
    }
    if (reading.airQuality <= airQualityWarning) {
      alerts.add(_environmental(reading, 'airQuality', reading.airQuality, airQualityWarning, AlertSeverity.warning));
    }
    if (reading.humidity >= humidityWarning) {
      alerts.add(_environmental(reading, 'humidity', reading.humidity, humidityWarning, AlertSeverity.warning));
    }
    return alerts;
  }

  static List<String> recipientsFor(SensorAlert alert, Iterable<String> adminPhones) {
    if (alert.isEnvironmental) return adminPhones.toList();
    return const [];
  }

  static SensorAlert _environmental(
    SensorReading reading,
    String sensor,
    double value,
    double threshold,
    AlertSeverity severity,
  ) {
    return SensorAlert(
      type: AlertType.environmental,
      severity: severity,
      horseId: reading.horseId,
      sensor: sensor,
      value: value,
      threshold: threshold,
      message: 'Environmental alert: $sensor=${value.toStringAsFixed(1)}',
      createdAt: reading.timestamp,
    );
  }
}
