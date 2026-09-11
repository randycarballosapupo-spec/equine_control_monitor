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

  Future<void> _editMedication([int? index]) async {
    final existing = index == null ? <String, String>{} : items[index];
    final name = TextEditingController(text: existing['name']);
    final dose = TextEditingController(text: existing['dose']);
    DateTime selectedDate = DateTime.tryParse(existing['date'] ?? '') ?? DateTime.now();
    String frequency = existing['frequency'] ?? 'daily';
    final language = widget.languageController.language;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppText.translate(language, index == null ? 'add_medication' : 'edit_medication')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: AppText.translate(language, 'medication')),
              ),
              TextField(
                controller: dose,
                decoration: InputDecoration(labelText: AppText.translate(language, 'dose')),
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
                decoration: InputDecoration(labelText: AppText.translate(language, 'frequency')),
                items: [
                  DropdownMenuItem(value: 'daily', child: Text(AppText.translate(language, 'daily'))),
                  DropdownMenuItem(value: 'weekly', child: Text(AppText.translate(language, 'weekly'))),
                  DropdownMenuItem(value: 'once', child: Text(AppText.translate(language, 'once'))),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => frequency = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppText.translate(language, 'cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'name': name.text.trim(),
                'dose': dose.text.trim(),
                'date': selectedDate.toIso8601String(),
                'frequency': frequency,
              }),
              child: Text(AppText.translate(language, 'save')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    dose.dispose();
    if (result == null || result['name']!.isEmpty || !mounted) return;
    setState(() {
      if (index == null) {
        items.add(result);
      } else {
        items[index] = result;
      }
    });
    await _saveItems();
  }

  Future<void> _deleteMedication(int index, AppLanguage language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.translate(language, 'delete')),
        content: Text(AppText.translate(language, 'delete_medication_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.translate(language, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppText.translate(language, 'delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => items.removeAt(index));
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
            title: Text(AppText.translate(language, 'care_plan')),
            actions: [
              IconButton(onPressed: _editMedication, icon: const Icon(Icons.add), tooltip: AppText.translate(language, 'add')),
            ],
          ),
          body: items.isEmpty
              ? Center(child: Text(AppText.translate(language, 'no_medication')))
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
                        subtitle: Text('${item['dose'] ?? ''}\n${AppText.translate(language, 'frequency')}: ${AppText.translate(language, item['frequency'] ?? 'once')}\n${AppText.translate(language, 'next_date')}: ${date.day}/${date.month}/${date.year}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit' ? _editMedication(index) : _deleteMedication(index, language),
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(AppText.translate(language, 'edit'))),
                            PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete'))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _editMedication,
            tooltip: AppText.translate(language, 'add'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
