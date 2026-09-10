import '../models/sensor_reading.dart';

abstract interface class DataRepository {
  Future<void> saveSensorReading(SensorReading reading);
  Future<List<SensorReading>> sensorHistory(String horseId);
}

class LocalDataRepository implements DataRepository {
  final List<SensorReading> _readings = [];

  @override
  Future<void> saveSensorReading(SensorReading reading) async {
    _readings.add(reading);
  }

  @override
  Future<List<SensorReading>> sensorHistory(String horseId) async {
    return _readings.where((reading) => reading.horseId == horseId).toList();
  }
}

