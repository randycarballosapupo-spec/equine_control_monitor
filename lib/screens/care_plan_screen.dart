import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_language.dart';
import '../service/access_service.dart';

class CarePlanScreen extends StatefulWidget {
  const CarePlanScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> {
  String? storageKey;
  List<Map<String, String>> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    storageKey = await AccessService.scopedKey('care_plan_items');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey!);
    if (raw == null) return;
    final decoded = (jsonDecode(raw) as List)
        .map((item) => Map<String, String>.from(item as Map))
        .toList();
    if (mounted) setState(() => items = decoded);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey!, jsonEncode(items));
  }

  Future<void> _addMedication() async {
    final name = TextEditingController();
    final dose = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String frequency = 'daily';
    final language = widget.languageController.language;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppText.get(language, 'add_medication')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: AppText.get(language, 'medication')),
              ),
              TextField(
                controller: dose,
                decoration: InputDecoration(labelText: AppText.get(language, 'dose')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: selectedDate,
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: frequency,
                decoration: InputDecoration(labelText: AppText.get(language, 'frequency')),
                items: [
                  DropdownMenuItem(value: 'daily', child: Text(AppText.get(language, 'daily'))),
                  DropdownMenuItem(value: 'weekly', child: Text(AppText.get(language, 'weekly'))),
                  DropdownMenuItem(value: 'once', child: Text(AppText.get(language, 'once'))),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => frequency = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppText.get(language, 'cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'name': name.text.trim(),
                'dose': dose.text.trim(),
                'date': selectedDate.toIso8601String(),
                'frequency': frequency,
              }),
              child: Text(AppText.get(language, 'save')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    dose.dispose();
    if (result == null || result['name']!.isEmpty || !mounted) return;
    setState(() => items.add(result));
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.get(language, 'care_plan')),
            actions: [
              IconButton(onPressed: _addMedication, icon: const Icon(Icons.add), tooltip: AppText.get(language, 'add')),
            ],
          ),
          body: items.isEmpty
              ? Center(child: Text(AppText.get(language, 'no_medication')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final date = DateTime.parse(item['date']!);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.medication)),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('${item['dose'] ?? ''}\n${AppText.get(language, 'frequency')}: ${AppText.get(language, item['frequency'] ?? 'once')}\n${AppText.get(language, 'next_date')}: ${date.day}/${date.month}/${date.year}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addMedication,
            tooltip: AppText.get(language, 'add'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
