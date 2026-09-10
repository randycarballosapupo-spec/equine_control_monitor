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
          title: Text(index == null ? 'Añadir animal' : 'Editar ficha animal'),
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
                      tooltip: 'Subir foto',
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
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 10),
                const Align(alignment: Alignment.centerLeft, child: Text('Tipo de animal')),
                Wrap(
                  spacing: 6,
                  children: animalTypes.entries.map((entry) => ChoiceChip(
                    label: Text('${entry.value} ${entry.key}'),
                    selected: selectedType == entry.key,
                    onSelected: (_) => setDialogState(() => selectedType = entry.key),
                  )).toList(),
                ),
                TextField(controller: breed, decoration: const InputDecoration(labelText: 'Raza o especie')),
                TextField(
                  controller: birthDate,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fecha de nacimiento', suffixIcon: Icon(Icons.calendar_month)),
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
                TextField(controller: chip, decoration: const InputDecoration(labelText: 'Número de chip')),
                TextField(controller: passport, decoration: const InputDecoration(labelText: 'Pasaporte veterinario / código')),
                TextField(controller: observations, maxLines: 3, decoration: const InputDecoration(labelText: 'Observaciones')),
                TextField(controller: traits, maxLines: 3, decoration: const InputDecoration(labelText: 'Rasgos característicos')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
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
              child: const Text('Guardar'),
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

  String _age(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return 'no indicada';
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) years--;
    return '$years años';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.languageController,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Tus amigos')),
          body: animals.isEmpty
              ? const Center(child: Text('Añade tu primer animal'))
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
                        subtitle: Text('${animal['type']} · ${animal['breed']}\nEdad: ${_age(animal['birthDate'])} · Chip: ${animal['chip']}\nPasaporte: ${animal['passport']}\n${animal['observations']}\nRasgos: ${animal['traits']}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit' ? _edit(index) : _delete(index),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)),
        ),
      );
}
