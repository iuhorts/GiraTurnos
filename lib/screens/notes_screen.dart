import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _selectedProfileId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final profiles = provider.activeProfiles;
        final notes = _selectedProfileId != null
            ? provider.notes.where((n) => n.profileId == _selectedProfileId).toList()
            : provider.notes;

        return Column(
          children: [
            if (profiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _selectedProfileId == null,
                        onSelected: (_) => setState(() => _selectedProfileId = null),
                      ),
                      const SizedBox(width: 8),
                      ...profiles.map((p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p.name),
                              selected: _selectedProfileId == p.id,
                              onSelected: (_) =>
                                  setState(() => _selectedProfileId = p.id),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: notes.isEmpty
                  ? const Center(child: Text('Sin notas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: notes.length,
                      itemBuilder: (ctx, i) {
                        final note = notes[i];
                        final profile = profiles.firstWhere(
                          (p) => p.id == note.profileId,
                          orElse: () => profiles.first,
                        );
                        return Dismissible(
                          key: Key(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => provider.deleteNote(note.id),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: profile.color,
                                radius: 16,
                                child: Text(
                                  profile.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(note.content),
                              subtitle: Text(
                                DateFormat('d MMM yyyy', 'es').format(note.date),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => provider.deleteNote(note.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
