import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/shift_type.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final pid = provider.activeProfileId;
        if (pid == null) {
          return const Center(child: Text('No hay perfiles'));
        }

        final start = DateTime(_selectedYear, _selectedMonth, 1);
        final end = DateTime(_selectedYear, _selectedMonth + 1, 0);
        final stats = provider.getStatsForPeriod(pid, start, end);
        final totalHours = provider.getTotalHours(pid, start, end);
        final totalDays = stats.values.fold(0, (a, b) => a + b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth--;
                      if (_selectedMonth == 0) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    '${DateFormat('MMMM', 'es').format(DateTime(_selectedYear, _selectedMonth))} $_selectedYear',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth++;
                      if (_selectedMonth == 13) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Total días: $totalDays',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Total horas: ${totalHours.toStringAsFixed(1)}h',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Desglose por turno',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...ShiftType.defaults.map((type) {
              final count = stats[type.id] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type.color,
                    radius: 14,
                    child: Text(
                      type.abbreviation,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  title: Text(type.name),
                  trailing: Text(
                    '$count días',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
