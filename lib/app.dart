import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profiles_screen.dart';

class TurnosFamiliaApp extends StatelessWidget {
  const TurnosFamiliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..loadData(),
      child: MaterialApp(
        title: 'TurnosFamilia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    CalendarScreen(),
    StatsScreen(),
    NotesScreen(),
    ProfilesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text([
          'Calendario',
          'Estadísticas',
          'Notas',
          'Miembros',
          'Ajustes',
        ][_currentIndex]),
        actions: [
          Consumer<AppProvider>(
            builder: (ctx, provider, _) {
              final sync = provider.syncService;
              return IconButton(
                icon: Icon(
                  sync.isSignedIn ? Icons.cloud_sync : Icons.cloud_off,
                  color: sync.isSignedIn ? Colors.green : Colors.grey,
                ),
                tooltip: sync.isSignedIn ? 'Sincronizado' : 'Sin sincronización',
                onPressed: () {
                  if (!sync.isSignedIn) {
                    provider.signInAndSync();
                  } else {
                    provider.manualSync();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.note), label: 'Notas'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Miembros'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
