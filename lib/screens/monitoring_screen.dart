import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../service/app_language.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final random = Random();
  Timer? timer;
  double temperature = 22.4;
  double humidity = 58.0;
  double ammonia = 2.1;
  double airQuality = 86.0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        temperature = 21 + random.nextDouble() * 4;
        humidity = 54 + random.nextDouble() * 10;
        ammonia = 1 + random.nextDouble() * 3;
        airQuality = 80 + random.nextDouble() * 17;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'monitoring'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(AppText.translate(language, 'connected_sensor')),
                  const Spacer(),
                  Chip(label: Text(AppText.translate(language, 'live'))),
                ],
              ),
              const SizedBox(height: 20),
              _readingCard(context, AppText.translate(language, 'temperature'), temperature, '°C', Icons.thermostat, Colors.orange),
              _readingCard(context, AppText.translate(language, 'humidity'), humidity, '%', Icons.water_drop, Colors.blue),
              _readingCard(context, AppText.translate(language, 'ammonia'), ammonia, 'ppm', Icons.warning_amber, Colors.red),
              _readingCard(context, AppText.translate(language, 'air_quality'), airQuality, '/100', Icons.air, Colors.teal),
              const SizedBox(height: 12),
              Text(AppText.translate(language, 'sensor_notice'), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  Widget _readingCard(BuildContext context, String title, double value, String unit, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: LinearProgressIndicator(value: (value / (unit == 'ppm' ? 10 : 100)).clamp(0, 1), color: color),
        trailing: Text('${value.toStringAsFixed(1)} $unit', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
