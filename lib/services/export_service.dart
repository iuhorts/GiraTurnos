import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/profile.dart';
import '../models/shift.dart';
import '../models/note.dart';
import '../models/shift_type.dart';
import 'database_service.dart';

class ExportService {
  static Future<String> exportJson() async {
    return DatabaseService.exportToJson();
  }

  static Future<void> importJson(String content) async {
    await DatabaseService.importFromJson(content);
  }

  static Future<String> exportToCsv() async {
    final shifts = await DatabaseService.getShifts();
    final profiles = await DatabaseService.getProfiles();
    final profileMap = {for (final p in profiles) p.id: p.name};

    final rows = <List<String>>[
      ['Fecha', 'Perfil', 'Tipo', 'Inicio', 'Fin', 'Horas', 'Nota'],
    ];

    for (final shift in shifts) {
      final type = ShiftType.findById(shift.typeId);
      rows.add([
        shift.date.toIso8601String().substring(0, 10),
        profileMap[shift.profileId] ?? 'Desconocido',
        type?.name ?? shift.typeId,
        shift.startTime?.toIso8601String().substring(11, 16) ?? '',
        shift.endTime?.toIso8601String().substring(11, 16) ?? '',
        shift.hoursWorked.toStringAsFixed(1),
        shift.note ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<void> shareJson() async {
    final jsonStr = await exportJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/turnosfamilia_export.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'TurnosFamilia - Datos');
  }

  static Future<void> shareCsv() async {
    final csvStr = await exportToCsv();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/turnosfamilia_export.csv');
    await file.writeAsString(csvStr);
    await Share.shareXFiles([XFile(file.path)], text: 'TurnosFamilia - CSV');
  }

  static Future<void> sharePdf({String? profileId, DateTime? startDate, DateTime? endDate}) async {
    final profiles = await DatabaseService.getProfiles();
    final shifts = await DatabaseService.getShifts(
      profileId: profileId,
      startDate: startDate,
      endDate: endDate,
    );
    final notes = await DatabaseService.getAllNotes(profileId: profileId);
    final profileMap = {for (final p in profiles) p.id: p};

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('TurnosFamilia - Reporte',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Perfil', 'Turno', 'Inicio', 'Fin', 'Horas', 'Nota'],
            data: shifts.map((s) {
              final type = s.shiftType;
              final profile = profileMap[s.profileId];
              return [
                DateFormat('dd/MM/yyyy').format(s.date),
                profile?.name ?? '?',
                type?.abbreviation ?? s.typeId,
                s.startTime?.toIso8601String().substring(11, 16) ?? '-',
                s.endTime?.toIso8601String().substring(11, 16) ?? '-',
                s.hoursWorked.toStringAsFixed(1),
                s.note ?? '',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/turnosfamilia_reporte.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'TurnosFamilia - PDF');
  }
}
