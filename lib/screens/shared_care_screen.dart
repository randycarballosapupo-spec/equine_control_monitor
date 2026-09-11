import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../service/app_language.dart';
import '../service/auth_service.dart';
import '../service/notification_service.dart';
import '../service/shared_care_service.dart';

class SharedCareScreen extends StatefulWidget {
  const SharedCareScreen({super.key, required this.languageController});
  final AppLanguageController languageController;

  @override
  State<SharedCareScreen> createState() => _SharedCareScreenState();
}

class _SharedCareScreenState extends State<SharedCareScreen> {
  List<SharedCareTask> tasks = [];
  List<AppUser> users = [];
  String? currentUserId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final currentUser = await AuthService.currentUser();
      final fetchedUsers = await AuthService.users();
      final fetchedTasks = await SharedCareService.fetchTasks();
      if (mounted) setState(() { currentUserId = currentUser?.id; users = fetchedUsers.where((user) => user.id != null).toList(); tasks = fetchedTasks; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addTask(AppLanguage language) async {
    final horse = TextEditingController();
    final item = TextEditingController();
    final notes = TextEditingController();
    var ownerId = currentUserId;
    var caregiverId = users.isEmpty ? null : users.first.id;
    var category = 'medication';
    var scheduled = DateTime.now().add(const Duration(hours: 1));
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(AppText.translate(language, 'shared_care')),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: horse, decoration: InputDecoration(labelText: AppText.translate(language, 'horse_name'))),
            DropdownButtonFormField<String>(initialValue: ownerId, decoration: InputDecoration(labelText: AppText.translate(language, 'horse_owner')), items: users.map((user) => DropdownMenuItem(value: user.id, child: Text(user.name))).toList(), onChanged: (value) => update(() => ownerId = value)),
            TextField(controller: item, decoration: InputDecoration(labelText: AppText.translate(language, 'care_item'))),
            DropdownButtonFormField<String>(initialValue: category, decoration: InputDecoration(labelText: AppText.translate(language, 'care_type')), items: [
              DropdownMenuItem(value: 'medication', child: Text(AppText.translate(language, 'medication'))),
              DropdownMenuItem(value: 'food', child: Text(AppText.translate(language, 'extra_food'))),
              DropdownMenuItem(value: 'supplement', child: Text(AppText.translate(language, 'extra_supplement'))),
            ], onChanged: (value) => update(() => category = value ?? category)),
            DropdownButtonFormField<String>(initialValue: caregiverId, decoration: InputDecoration(labelText: AppText.translate(language, 'assigned_user')), items: users.map((user) => DropdownMenuItem(value: user.id, child: Text(user.name))).toList(), onChanged: (value) => update(() => caregiverId = value)),
            ListTile(title: Text(AppText.translate(language, 'schedule')), subtitle: Text('${scheduled.day}/${scheduled.month}/${scheduled.year} ${TimeOfDay.fromDateTime(scheduled).format(context)}'), trailing: const Icon(Icons.calendar_month), onTap: () async {
              final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: scheduled);
              if (date == null) return;
              if (!context.mounted) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduled));
              if (time != null) update(() => scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            }),
            TextField(controller: notes, maxLines: 2, decoration: InputDecoration(labelText: AppText.translate(language, 'notes'))),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.translate(language, 'cancel'))), FilledButton(onPressed: caregiverId == null || ownerId == null ? null : () => Navigator.pop(dialogContext, true), child: Text(AppText.translate(language, 'save')))],
        ),
      ),
    );
    if (created == true && horse.text.trim().isNotEmpty && item.text.trim().isNotEmpty && caregiverId != null && ownerId != null) {
      try { await SharedCareService.createTask(ownerId: ownerId!, caregiverId: caregiverId!, horseName: horse.text, itemName: item.text, category: category, scheduledFor: scheduled, notes: notes.text); await _load(); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppText.translate(language, 'shared_care_error')))); }
    }
    horse.dispose(); item.dispose(); notes.dispose();
  }

  Future<void> _complete(SharedCareTask task, AppLanguage language) async {
    try {
      await SharedCareService.completeTask(task.id);
      await NotificationService.notifyCareCompleted(taskId: task.id);
      await NotificationService.show(AppText.translate(language, 'care_completed'), '${task.horseName}: ${task.itemName}');
      await _load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppText.translate(language, 'shared_care_error')))); }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.languageController, builder: (context, _) {
    final language = widget.languageController.language;
    final completed = tasks.where((task) => task.isCompleted).length;
    return Scaffold(appBar: AppBar(title: Text(AppText.translate(language, 'shared_care'))), floatingActionButton: FloatingActionButton(onPressed: () => _addTask(language), child: const Icon(Icons.add)), body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.summarize), title: Text(AppText.translate(language, 'monthly_summary')), subtitle: Text('${AppText.translate(language, 'completed')}: $completed / ${tasks.length}'))),
      if (tasks.isEmpty) Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(AppText.translate(language, 'no_shared_care')))),
      ...tasks.map((task) {
        final matchingOwners = users.where((user) => user.id == task.ownerId);
        final ownerName = matchingOwners.isEmpty ? AppText.translate(language, 'not_specified') : matchingOwners.first.name;
        return Card(child: ListTile(leading: Icon(task.isCompleted ? Icons.check_circle : Icons.alarm, color: task.isCompleted ? Colors.green : Colors.orange), title: Text('${task.horseName} - ${task.itemName}'), subtitle: Text('${AppText.translate(language, 'horse_owner')}: $ownerName\n${task.scheduledFor.day}/${task.scheduledFor.month}/${task.scheduledFor.year} ${TimeOfDay.fromDateTime(task.scheduledFor).format(context)}${task.notes.isEmpty ? '' : '\n${task.notes}'}'), isThreeLine: true, trailing: task.isCompleted ? null : task.caregiverId == currentUserId ? IconButton(tooltip: AppText.translate(language, 'mark_completed'), icon: const Icon(Icons.check), onPressed: () => _complete(task, language)) : null));
      }),
    ])));
  });
}