import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/app_language.dart';

class CctvScreen extends StatefulWidget {
  const CctvScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<CctvScreen> createState() => _CctvScreenState();
}

class _CctvScreenState extends State<CctvScreen> {
  static const storageKey = 'cctv_cameras';
  List<Map<String, String>> cameras = [];

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(storageKey) ?? const [];
    if (!mounted) return;
    setState(() {
      cameras = values.map((value) {
        final parts = value.split('|');
        return {'name': parts.first, 'url': parts.length > 1 ? parts[1] : ''};
      }).toList();
    });
  }

  Future<void> _saveCameras() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, cameras.map((camera) => '${camera['name']}|${camera['url']}').toList());
  }

  Future<void> _addCamera(AppLanguage language) async {
    final name = TextEditingController();
    final url = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.translate(language, 'add_camera_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: AppText.translate(language, 'camera_name'))),
            TextField(controller: url, decoration: InputDecoration(labelText: AppText.translate(language, 'camera_url'), hintText: 'rtsp://... o http://192.168.1.20')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppText.translate(language, 'cancel'))),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || url.text.trim().isEmpty) return;
              cameras.add({'name': name.text.trim(), 'url': url.text.trim()});
              Navigator.pop(context, true);
            },
            child: Text(AppText.translate(language, 'save')),
          ),
        ],
      ),
    );
    name.dispose();
    url.dispose();
    if (result == true) {
      await _saveCameras();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCamera(String url, AppLanguage language) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppText.translate(language, 'camera_open_error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.translate(language, 'cctv')),
            actions: [IconButton(onPressed: () => _addCamera(language), icon: const Icon(Icons.add_a_photo), tooltip: AppText.translate(language, 'add_camera'))],
          ),
          body: cameras.isEmpty
              ? Center(child: Text(AppText.translate(language, 'no_cameras')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cameras.length,
                  itemBuilder: (context, index) {
                    final camera = cameras[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.videocam)),
                        title: Text(camera['name'] ?? ''),
                        subtitle: Text(camera['url'] ?? ''),
                        trailing: IconButton(onPressed: () => _openCamera(camera['url'] ?? '', language), icon: const Icon(Icons.open_in_new)),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(onPressed: () => _addCamera(language), child: const Icon(Icons.add_a_photo)),
        );
      },
    );
  }
}
