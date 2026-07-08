import 'package:home_widget/home_widget.dart';
import '../models/shift_type.dart';
import 'database_service.dart';

class HomeWidgetService {
  static const _widgetName = 'TurnoHoy';

  static Future<void> update({String? profileId}) async {
    try {
      final today = DateTime.now();
      final profiles = await DatabaseService.getProfiles();
      final targetProfileId = profileId ?? (profiles.isNotEmpty ? profiles.first.id : null);
      if (targetProfileId == null) return;

      final shift = await DatabaseService.getShift(targetProfileId, today);
      final profile = profiles.firstWhere((p) => p.id == targetProfileId);

      String title = profile.name;
      String body = 'Sin turno';
      if (shift != null) {
        final type = ShiftType.findById(shift.typeId);
        body = type?.name ?? shift.typeId;
        if (shift.startTime != null && shift.endTime != null) {
          body += '\n${shift.startTime!.toIso8601String().substring(11, 16)} - '
              '${shift.endTime!.toIso8601String().substring(11, 16)}';
        }
      }

      await HomeWidget.saveWidgetData('${_widgetName}_title', title);
      await HomeWidget.saveWidgetData('${_widgetName}_body', body);
      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: _widgetName,
      );
    } catch (_) {}
  }
}
