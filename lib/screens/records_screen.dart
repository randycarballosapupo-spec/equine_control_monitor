import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_language.dart';
import '../service/access_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String? storageKey;
  List<Map<String, String>> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    storageKey = await AccessService.scopedKey('clinical_records');
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey!);
    if (saved == null) return;
    final decoded = (jsonDecode(saved) as List).map((item) {
      return Map<String, String>.from(item as Map);
    }).toList();
    if (mounted) setState(() => records = decoded);
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey!, jsonEncode(records));
  }

  Future<void> _addRecord() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final language = widget.languageController.language;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.translate(language, 'add_record')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: AppText.translate(language, 'record_title')),
            ),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: InputDecoration(labelText: AppText.translate(language, 'details')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppText.translate(language, 'cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text.trim(),
              'details': detailsController.text.trim(),
              'date': DateTime.now().toIso8601String(),
            }),
            child: Text(AppText.translate(language, 'save')),
          ),
        ],
      ),
    );
    titleController.dispose();
    detailsController.dispose();
    if (result == null || result['title']!.isEmpty || !mounted) return;
    setState(() => records.insert(0, result));
    await _saveRecords();
  }

  Future<void> _editRecord(int index) async {
    final titleController = TextEditingController(text: records[index]['title']);
    final detailsController = TextEditingController(text: records[index]['details']);
    final language = widget.languageController.language;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.translate(language, 'edit_record')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleController, decoration: InputDecoration(labelText: AppText.translate(language, 'record_title'))),
          TextField(controller: detailsController, maxLines: 4, decoration: InputDecoration(labelText: AppText.translate(language, 'details'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppText.translate(language, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, {'title': titleController.text.trim(), 'details': detailsController.text.trim(), 'date': records[index]['date'] ?? DateTime.now().toIso8601String()}), child: Text(AppText.translate(language, 'save'))),
        ],
      ),
    );
    titleController.dispose();
    detailsController.dispose();
    if (result == null || !mounted) return;
    setState(() => records[index] = result);
    await _saveRecords();
  }

  Future<void> _deleteRecord(int index) async {
    setState(() => records.removeAt(index));
    await _saveRecords();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.translate(language, 'records')),
            actions: [
              IconButton(
                tooltip: AppText.translate(language, 'add'),
                onPressed: _addRecord,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: records.isEmpty
              ? Center(child: Text(AppText.translate(language, 'no_records')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.assignment)),
                        title: Text(record['title'] ?? ''),
                        subtitle: Text(record['details'] ?? ''),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_formatDate(record['date'])),
                          PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit' ? _editRecord(index) : _deleteRecord(index),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text(AppText.translate(language, 'edit_record'))),
                              PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete'))),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addRecord,
            tooltip: AppText.translate(language, 'add'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  String _formatDate(String? value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
