import 'dart:convert';
import '../models/sensor_reading.dart';
import '../models/sensor_alert.dart';
import 'alert_service.dart';

class Esp32Protocol {
  const Esp32Protocol._();

  static SensorReading? decode(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map) return null;
      return SensorReading.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  static String encode(SensorReading reading) => jsonEncode(reading.toJson());

  static List<SensorAlert> alertsFor(String payload) {
    final reading = decode(payload);
    return reading == null ? const [] : AlertService.environmentalAlerts(reading);
  }
}
