import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_language.dart';
import '../service/access_service.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  Future<pw.Document> _buildReport() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsKey = await AccessService.scopedKey('clinical_records');
    final medicationsKey = await AccessService.scopedKey('care_plan_items');
    final ownerKey = await AccessService.scopedKey('owner');
    final horseKey = await AccessService.scopedKey('horse');
    final veterinarianKey = await AccessService.scopedKey('veterinarian');
    final records = jsonDecode(prefs.getString(recordsKey) ?? '[]') as List;
    final medications = jsonDecode(prefs.getString(medicationsKey) ?? '[]') as List;
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Equi_Harmony_Monitor'),
          pw.Text('Clinical and monitoring report'),
          pw.SizedBox(height: 18),
          pw.Text('Owner: ${prefs.getString('${ownerKey}_name') ?? ''}'),
          pw.Text('Horse: ${prefs.getString('${horseKey}_name') ?? ''}'),
          pw.Text('Veterinarian: ${prefs.getString('${veterinarianKey}_name') ?? ''}'),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Treatment and medication'),
          if (medications.isEmpty)
            pw.Text('No medication scheduled.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Medication', 'Dose', 'Date'],
              data: medications.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                final date = DateTime.tryParse('${map['date']}');
                return [map['name'] ?? '', map['dose'] ?? '', date == null ? '' : '${date.day}/${date.month}/${date.year}'];
              }).toList(),
            ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Clinical records'),
          if (records.isEmpty)
            pw.Text('No clinical records.')
          else
            ...records.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return pw.Bullet(text: '${map['title'] ?? ''}: ${map['details'] ?? ''}');
            }),
        ],
      ),
    );
    return document;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final language = languageController.language;
        return Scaffold(
          appBar: AppBar(title: Text(AppText.translate(language, 'report'))),
          body: Center(
            child: FilledButton.icon(
              onPressed: () async {
                final document = await _buildReport();
                await Printing.layoutPdf(onLayout: (_) => document.save());
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(AppText.translate(language, 'generate_report')),
            ),
          ),
        );
      },
    );
  }
}
