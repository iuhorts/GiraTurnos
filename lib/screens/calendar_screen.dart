import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/shift_type.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/shift_legend.dart';
import '../widgets/day_detail_sheet.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Column(
          children: [
            _ProfileSelector(provider: provider),
            _Calendar(provider: provider),
            const SizedBox(height: 8),
            _Legend(provider: provider),
            const Divider(height: 1),
            _DayInfo(provider: provider),
          ],
        );
      },
    );
  }
}

class _ProfileSelector extends StatelessWidget {
  final AppProvider provider;
  const _ProfileSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final profiles = provider.activeProfiles;
    if (profiles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: profiles.map((p) {
          final isActive = p.id == provider.activeProfileId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ProfileAvatar(
              profile: p,
              radius: 22,
              isSelected: isActive,
              onTap: () => provider.setActiveProfile(p.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final AppProvider provider;
  const _Calendar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: provider.selectedDate,
      selectedDayPredicate: (day) =>
          day.year == provider.selectedDate.year &&
          day.month == provider.selectedDate.month &&
          day.day == provider.selectedDate.day,
      onDaySelected: (selectedDay, _) {
        provider.setSelectedDate(selectedDay);
        _showDaySheet(context, provider, selectedDay);
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final profileId = provider.activeProfileId;
          if (profileId == null) return null;
          final shift = provider.getShiftForDate(profileId, date);
          if (shift == null) return null;
          final type = ShiftType.findById(shift.typeId);
          if (type == null) return null;
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: type.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                type.abbreviation,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) =>
            DateFormat('MMMM yyyy', 'es').format(date),
      ),
      locale: 'es',
    );
  }

  void _showDaySheet(BuildContext context, AppProvider provider, DateTime date) {
    final pid = provider.activeProfileId;
    if (pid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: DayDetailSheet(provider: provider, date: date, profileId: pid),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final AppProvider provider;
  const _Legend({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: ShiftType.defaults.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: t.color,
                radius: 6,
              ),
              label: Text(t.abbreviation, style: const TextStyle(fontSize: 12)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayInfo extends StatelessWidget {
  final AppProvider provider;
  const _DayInfo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pid = provider.activeProfileId;
    if (pid == null) return const SizedBox.shrink();
    final shift = provider.getShiftForDate(pid, provider.selectedDate);
    final notes = provider.getNotesForDate(pid, provider.selectedDate);
    final dateStr = DateFormat('d MMMM yyyy', 'es').format(provider.selectedDate);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          if (shift != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: shift.shiftType?.color ?? Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shift.shiftType?.name ?? shift.typeId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                if (shift.startTime != null)
                  Text(
                    '${shift.startTime!.toIso8601String().substring(11, 16)}-${shift.endTime!.toIso8601String().substring(11, 16)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(width: 8),
                Text('${shift.hoursWorked.toStringAsFixed(1)}h',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ] else
            Text('Sin turno asignado', style: TextStyle(color: Colors.grey[500])),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...notes.map((n) => Row(
                  children: [
                    const Icon(Icons.note, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(n.content, style: const TextStyle(fontSize: 12))),
                  ],
                )),
          ],
        ],
      ),
    );
  }
}
