import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final sync = provider.syncService;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Sincronización Google Drive',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sync.isSignedIn
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: sync.isSignedIn ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sync.isSignedIn
                              ? 'Conectado: ${sync.account?.email ?? ""}'
                              : 'No conectado',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (sync.isSyncing)
                      const LinearProgressIndicator()
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (sync.isSignedIn) {
                              await provider.manualSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sincronizado correctamente')),
                                );
                              }
                            } else {
                              await provider.signInAndSync();
                            }
                          },
                          icon: Icon(sync.isSignedIn ? Icons.sync : Icons.login),
                          label: Text(sync.isSignedIn ? 'Sincronizar ahora' : 'Iniciar sesión Google'),
                        ),
                      ),
                      if (sync.isSignedIn) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await sync.signOut();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sesión cerrada')),
                              );
                            }
                          },
                          child: const Text('Cerrar sesión',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ],
                    if (sync.lastError != null) ...[
                      const SizedBox(height: 8),
                      Text(sync.lastError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Exportar / Importar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.json),
                    title: const Text('Exportar JSON'),
                    subtitle: const Text('Copia de seguridad completa'),
                    trailing: const Icon(Icons.share),
                    onTap: () => provider.exportToJsonFile(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: const Text('Exportar CSV'),
                    subtitle: const Text('Tabla de turnos'),
                    trailing: const Icon(Icons.share),
                    onTap: () => provider.exportToCsvFile(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Exportar PDF'),
                    subtitle: const Text('Reporte mensual'),
                    trailing: const Icon(Icons.share),
                    onTap: () => provider.exportToPdf(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: const Text('Importar JSON'),
                    subtitle: const Text('Restaurar copia de seguridad'),
                    trailing: const Icon(Icons.upload_file),
                    onTap: () => _importFile(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Widget de pantalla de inicio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.widgets),
                title: const Text('Añadir widget'),
                subtitle: const Text('Muestra el turno de hoy en la pantalla principal'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  // home_widget package handles this via the app widget
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Añade el widget desde el menú de widgets de Android'),
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

  Future<void> _importFile(BuildContext context, AppProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        await provider.importFromJson(content);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos importados correctamente')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e')),
        );
      }
    }
  }
}
