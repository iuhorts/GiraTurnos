import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';
import '../widgets/profile_avatar.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final profiles = provider.profiles;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Miembros de la familia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...profiles.map((p) => _ProfileCard(
                  profile: p,
                  provider: provider,
                )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showAddProfileDialog(context, provider),
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir miembro'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    Color selectedColor = Colors.blue;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Nuevo miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Color:'),
              const SizedBox(height: 8),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (c) => setDState(() => selectedColor = c),
                enableAlpha: false,
                labelTypes: const [],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  provider.addProfile(nameCtrl.text.trim(), selectedColor);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final AppProvider provider;
  const _ProfileCard({required this.profile, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ProfileAvatar(profile: profile, radius: 18, showName: false),
        title: Text(profile.name),
        subtitle: Text(profile.isActive ? 'Activo' : 'Inactivo'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context),
            ),
            Switch(
              value: profile.isActive,
              onChanged: (v) {
                provider.updateProfile(profile.copyWith(isActive: v));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: profile.name);
    Color selectedColor = profile.color;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Editar miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (c) => setDState(() => selectedColor = c),
                enableAlpha: false,
                labelTypes: const [],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            if (provider.profiles.length > 1)
              TextButton(
                onPressed: () {
                  provider.deleteProfile(profile.id);
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  provider.updateProfile(
                    profile.copyWith(name: nameCtrl.text.trim(), color: selectedColor),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
