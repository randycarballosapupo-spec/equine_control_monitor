import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/access_service.dart';
import '../service/app_language.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key, required this.languageController});
  final AppLanguageController languageController;
  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  static const animalTypes = {'Caballo': '🐴', 'Perro': '🐶', 'Ave': '🐦', 'Conejo': '🐰', 'Otro': '🐾'};
  List<Map<String, String>> animals = [];
  String? storageKey;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    storageKey = await AccessService.scopedKey('animals');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey!);
    if (raw != null && mounted) {
      setState(() => animals = (jsonDecode(raw) as List).map((item) => Map<String, String>.from(item as Map)).toList());
    }
  }

  Future<void> _save() async {
    await (await SharedPreferences.getInstance()).setString(storageKey!, jsonEncode(animals));
  }

  Future<void> _edit([int? index]) async {
    final language = widget.languageController.language;
    final old = index == null ? <String, String>{} : animals[index];
    final name = TextEditingController(text: old['name']);
    final breed = TextEditingController(text: old['breed']);
    final birthDate = TextEditingController(text: old['birthDate']);
    final chip = TextEditingController(text: old['chip']);
    final passport = TextEditingController(text: old['passport']);
    final observations = TextEditingController(text: old['observations']);
    final traits = TextEditingController(text: old['traits']);
    Uint8List? photoBytes;
    final savedPhoto = old['photo'];
    if (savedPhoto != null && savedPhoto.isNotEmpty) photoBytes = base64Decode(savedPhoto);
    var selectedType = old['type'] ?? 'Caballo';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppText.translate(language, index == null ? 'add_animal' : 'edit_animal')),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes!),
                      child: photoBytes == null ? Text(animalTypes[selectedType] ?? '🐾', style: const TextStyle(fontSize: 34)) : null,
                    ),
                    IconButton.filled(
                      tooltip: AppText.translate(language, 'upload_photo'),
                      onPressed: () async {
                        final picked = await FilePicker.pickFiles(type: FileType.image);
                        if (picked.isEmpty) return;
                        final bytes = await picked.first.readAsBytes();
                        setDialogState(() => photoBytes = bytes);
                      },
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: InputDecoration(labelText: AppText.translate(language, 'name'))),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: Text(AppText.translate(language, 'animal_type'))),
                Wrap(
                  spacing: 6,
                  children: animalTypes.entries.map((entry) => ChoiceChip(
                    label: Text('${entry.value} ${entry.key}'),
                    selected: selectedType == entry.key,
                    onSelected: (_) => setDialogState(() => selectedType = entry.key),
                  )).toList(),
                ),
                TextField(controller: breed, decoration: InputDecoration(labelText: AppText.translate(language, 'species_or_breed'))),
                TextField(
                  controller: birthDate,
                  readOnly: true,
                  decoration: InputDecoration(labelText: AppText.translate(language, 'birth_date'), suffixIcon: const Icon(Icons.calendar_month)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: DateTime.tryParse(birthDate.text) ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) birthDate.text = picked.toIso8601String().split('T').first;
                  },
                ),
                TextField(controller: chip, decoration: InputDecoration(labelText: AppText.translate(language, 'microchip'))),
                TextField(controller: passport, decoration: InputDecoration(labelText: AppText.translate(language, 'vet_passport'))),
                TextField(controller: observations, maxLines: 3, decoration: InputDecoration(labelText: AppText.translate(language, 'notes'))),
                TextField(controller: traits, maxLines: 3, decoration: InputDecoration(labelText: AppText.translate(language, 'traits'))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppText.translate(language, 'cancel'))),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'name': name.text.trim(),
                'type': selectedType,
                'breed': breed.text.trim(),
                'birthDate': birthDate.text.trim(),
                'chip': chip.text.trim(),
                'passport': passport.text.trim(),
                'observations': observations.text.trim(),
                'traits': traits.text.trim(),
                'photo': photoBytes == null ? '' : base64Encode(photoBytes!),
              }),
              child: Text(AppText.translate(language, 'save')),
            ),
          ],
        ),
      ),
    );
    for (final controller in [name, breed, birthDate, chip, passport, observations, traits]) {
      controller.dispose();
    }
    if (result == null || result['name']!.isEmpty || !mounted) return;
    setState(() {
      if (index == null) {
        animals.add(result);
      } else {
        animals[index] = result;
      }
    });
    await _save();
  }

  Future<void> _delete(int index) async {
    setState(() => animals.removeAt(index));
    await _save();
  }

  String _age(String? value, AppLanguage language) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return AppText.translate(language, 'not_specified');
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) years--;
    return '$years';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.languageController,
        builder: (context, _) {
          final language = widget.languageController.language;
          return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'your_friends'))),
          body: animals.isEmpty
              ? Center(child: Text(AppText.translate(language, 'add_first_animal')))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    final icon = animalTypes[animal['type']] ?? '🐾';
                    final photo = animal['photo'];
                    return Card(
                      child: ListTile(
                        leading: photo != null && photo.isNotEmpty
                            ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(photo)))
                            : Text(icon, style: const TextStyle(fontSize: 30)),
                        title: Text(animal['name'] ?? ''),
                        subtitle: Text('${animal['type']} · ${animal['breed']}\n${AppText.translate(language, 'age')}: ${_age(animal['birthDate'], language)} · ${AppText.translate(language, 'chip_label')}: ${animal['chip']}\n${AppText.translate(language, 'passport')}: ${animal['passport']}\n${animal['observations']}\n${AppText.translate(language, 'traits')}: ${animal['traits']}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit' ? _edit(index) : _delete(index),
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(AppText.translate(language, 'edit'))),
                            PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete'))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)),
        );
        },
      );
}
