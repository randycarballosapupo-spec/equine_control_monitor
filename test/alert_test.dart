import 'package:flutter_test/flutter_test.dart';
import 'package:equine_control_monitor/models/sensor_alert.dart';
import 'package:equine_control_monitor/service/alert_service.dart';
import 'package:equine_control_monitor/service/esp32_protocol.dart';

void main() {
  test('la alerta ambiental se dirige solo a administradores', () {
    const payload = '{"moduleType":"central","sourceModuleId":"sub-1","deviceId":"central-1","horseId":"horse-1","timestamp":"1700000000","temperature":22,"humidity":60,"ammonia":30,"airQuality":90}';
    final alerts = Esp32Protocol.alertsFor(payload);

    expect(alerts, hasLength(1));
    expect(alerts.single.type, AlertType.environmental);
    expect(alerts.single.severity, AlertSeverity.critical);
    expect(AlertService.recipientsFor(alerts.single, ['+48111111111']), ['+48111111111']);
  });
}
