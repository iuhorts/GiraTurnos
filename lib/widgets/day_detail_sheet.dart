import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../models/shift_type.dart';
import '../models/shift.dart';
import '../models/note.dart';
import '../providers/app_provider.dart';

class DayDetailSheet extends StatefulWidget {
  final AppProvider provider;
  final DateTime date;
  final String profileId;

  const DayDetailSheet({
    super.key,
    required this.provider,
    required this.date,
    required this.profileId,
  });

  @override
  State<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<DayDetailSheet> {
  late TextEditingController _noteController;
  Shift? _shift;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _shift = widget.provider.getShiftForDate(widget.profileId, widget.date);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.provider.profiles
        .firstWhere((p) => p.id == widget.profileId);
    final dayNotes = widget.provider.getNotesForDate(widget.profileId, widget.date);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'es').format(widget.date),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: profile.color,
                child: Text(profile.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              Text(profile.name, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Turno', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ShiftType.defaults.map((type) {
              final isActive = _shift?.typeId == type.id;
              return GestureDetector(
                onTap: () {
                  widget.provider.setShift(
                    widget.profileId, widget.date, type.id,
                    startTime: _shift?.startTime,
                    endTime: _shift?.endTime,
                    note: _shift?.note,
                  );
                  setState(() => _shift =
                      widget.provider.getShiftForDate(widget.profileId, widget.date));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? type.color.withValues(alpha: 0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? type.color : Colors.grey[300]!,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    type.name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? type.color : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_shift != null && _shift!.startTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_shift!.startTime!.toIso8601String().substring(11, 16)} - '
                  '${_shift!.endTime!.toIso8601String().substring(11, 16)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Text('${_shift!.hoursWorked.toStringAsFixed(1)}h',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('Notas', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Añadir nota...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_noteController.text.trim().isNotEmpty) {
                    widget.provider.addNote(
                      widget.profileId, widget.date, _noteController.text.trim());
                    _noteController.clear();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
          if (dayNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...dayNotes.map((note) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(note.content, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => widget.provider.deleteNote(note.id),
                  ),
                )),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
