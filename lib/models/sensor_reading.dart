class SensorReading {
  const SensorReading({
    required this.deviceId,
    required this.horseId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.airQuality,
    this.sourceModuleId = '',
    this.moduleType = 'central',
    this.dust,
    this.pollen,
    this.acceleration,
  });

  final String deviceId;
  final String horseId;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double ammonia;
  final double airQuality;
  final String sourceModuleId;
  final String moduleType;
  final double? dust;
  final double? pollen;
  final double? acceleration;

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        deviceId: '${json['deviceId'] ?? ''}',
        horseId: '${json['horseId'] ?? ''}',
        timestamp: _date(json['timestamp']),
        temperature: _number(json['temperature']),
        humidity: _number(json['humidity']),
        ammonia: _number(json['ammonia']),
        airQuality: _number(json['airQuality']),
        sourceModuleId: '${json['sourceModuleId'] ?? json['deviceId'] ?? ''}',
        moduleType: '${json['moduleType'] ?? 'central'}',
        dust: _optionalNumber(json['dust']),
        pollen: _optionalNumber(json['pollen']),
        acceleration: _optionalNumber(json['acceleration']),
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'horseId': horseId,
        'timestamp': timestamp.toIso8601String(),
        'temperature': temperature,
        'humidity': humidity,
        'ammonia': ammonia,
        'airQuality': airQuality,
        'sourceModuleId': sourceModuleId,
        'moduleType': moduleType,
        if (dust != null) 'dust': dust,
        if (pollen != null) 'pollen': pollen,
        if (acceleration != null) 'acceleration': acceleration,
      };

  static double _number(dynamic value) => double.tryParse('$value') ?? 0;
  static double? _optionalNumber(dynamic value) => value == null ? null : _number(value);

  static DateTime _date(dynamic value) {
    final text = '$value';
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;
    final seconds = int.tryParse(text);
    return seconds == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}
