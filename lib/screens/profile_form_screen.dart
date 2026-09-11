import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/access_service.dart';
import '../service/app_language.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({
    super.key,
    required this.languageController,
    required this.isHorse,
    this.isOwner = false,
  });

  final AppLanguageController languageController;
  final bool isHorse;
  final bool isOwner;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final identifierController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final secondaryController = TextEditingController();
  final notesController = TextEditingController();
  Uint8List? photoBytes;
  String? storagePrefix;
  bool showPrivateIdentifier = false;

  String get profileType => widget.isOwner
      ? 'owner'
      : widget.isHorse
          ? 'horse'
          : 'veterinarian';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    storagePrefix = await AccessService.scopedKey(profileType);
    final prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString('${storagePrefix}_name') ?? '';
    dateController.text = prefs.getString('${storagePrefix}_birth_date') ?? '';
    identifierController.text = prefs.getString('${storagePrefix}_identifier') ?? '';
    addressController.text = prefs.getString('${storagePrefix}_address') ?? '';
    phoneController.text = prefs.getString('${storagePrefix}_phone') ?? '';
    secondaryController.text = prefs.getString('${storagePrefix}_secondary') ?? '';
    notesController.text = prefs.getString('${storagePrefix}_notes') ?? '';
    final photo = prefs.getString('${storagePrefix}_photo');
    if (photo != null && photo.isNotEmpty) photoBytes = base64Decode(photo);
    if (mounted) setState(() {});
  }

  Future<void> _saveProfile() async {
    final prefix = storagePrefix ?? await AccessService.scopedKey(profileType);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${prefix}_name', nameController.text.trim());
    await prefs.setString('${prefix}_birth_date', dateController.text.trim());
    await prefs.setString('${prefix}_identifier', identifierController.text.trim());
    await prefs.setString('${prefix}_address', addressController.text.trim());
    await prefs.setString('${prefix}_phone', phoneController.text.trim());
    await prefs.setString('${prefix}_secondary', secondaryController.text.trim());
    await prefs.setString('${prefix}_notes', notesController.text.trim());
    if (photoBytes != null) await prefs.setString('${prefix}_photo', base64Encode(photoBytes!));
    if (!mounted) return;
    final language = widget.languageController.language;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppText.translate(language, 'saved'))));
  }

  Future<void> _selectPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    final bytes = result.isEmpty ? null : await result.first.readAsBytes();
    if (bytes == null || !mounted) return;
    setState(() => photoBytes = bytes);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (picked == null || !mounted) return;
    setState(() => dateController.text = '${picked.day}/${picked.month}/${picked.year}');
  }

  @override
  void dispose() {
    for (final controller in [
      nameController,
      dateController,
      identifierController,
      addressController,
      phoneController,
      secondaryController,
      notesController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        final title = AppText.translate(language, widget.isOwner
            ? 'owner_card'
            : widget.isHorse
                ? 'horse_card'
                : 'veterinarian_card');
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes!),
                      child: photoBytes == null
                          ? (widget.isHorse
                              ? const Text('🐴', style: TextStyle(fontSize: 32))
                              : const Icon(Icons.person, size: 36))
                          : null,
                    ),
                    IconButton.filled(onPressed: _selectPhoto, icon: const Icon(Icons.edit)),
                  ],
                ),
                const SizedBox(height: 20),
                _field(nameController, AppText.translate(language, 'name')),
                const SizedBox(height: 14),
                _dateField(language),
                const SizedBox(height: 14),
                if (widget.isHorse || widget.isOwner) ...[
                  _privateIdentifierField(language),
                  const SizedBox(height: 14),
                ],
                _field(addressController, AppText.translate(language, widget.isHorse ? 'current_address' : 'address')),
                const SizedBox(height: 14),
                if (!widget.isHorse) ...[
                  _field(phoneController, AppText.translate(language, 'phone'), keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                ],
                if (widget.isHorse)
                  _field(secondaryController, AppText.translate(language, 'pathologies'), maxLines: 4)
                else if (widget.isOwner)
                  _field(secondaryController, AppText.translate(language, 'horses_owned'), maxLines: 2)
                else ...[
                  _field(secondaryController, AppText.translate(language, 'license_number')),
                  const SizedBox(height: 14),
                  _field(notesController, AppText.translate(language, 'clinic_address'), maxLines: 3),
                ],
                if (widget.isHorse || widget.isOwner) ...[
                  const SizedBox(height: 14),
                  _field(notesController, AppText.translate(language, 'notes'), maxLines: 4),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: Text(AppText.translate(language, 'save')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.edit)),
    );
  }

  Widget _dateField(AppLanguage language) {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: AppText.translate(language, 'birth_date'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(onPressed: _selectDate, icon: const Icon(Icons.calendar_month)),
      ),
    );
  }

  Widget _privateIdentifierField(AppLanguage language) {
    return TextField(
      controller: identifierController,
      obscureText: !showPrivateIdentifier,
      decoration: InputDecoration(
        labelText: AppText.translate(language, widget.isHorse ? 'horse_id' : 'national_id'),
        helperText: AppText.translate(language, 'private_data_notice'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: showPrivateIdentifier ? AppText.translate(language, 'hide_data') : AppText.translate(language, 'show_data'),
          onPressed: () => setState(() => showPrivateIdentifier = !showPrivateIdentifier),
          icon: Icon(showPrivateIdentifier ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
