import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tareas/tareas_screen.dart';
import '../screens/horario/horario_screen.dart';
import '../screens/proyectos/proyectos_screen.dart';
import '../screens/jarvis/jarvis_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _dashKey = GlobalKey<DashboardScreenState>();
  final _tareasKey = GlobalKey<TareasScreenState>();
  final _horarioKey = GlobalKey<HorarioScreenState>();
  final _proyectosKey = GlobalKey<ProyectosScreenState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashKey),
      TareasScreen(key: _tareasKey),
      HorarioScreen(key: _horarioKey),
      ProyectosScreen(key: _proyectosKey),
      const JarvisScreen(),
    ];
  }

  void _onTabSelected(int i) {
    if (i != _index) {
      if (i == 0) _dashKey.currentState?.load();
      if (i == 1) _tareasKey.currentState?.load();
      if (i == 2) _horarioKey.currentState?.load();
      if (i == 3) _proyectosKey.currentState?.load();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch),
            label: 'Proyectos',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Jarvis',
          ),
        ],
      ),
    );
  }
}
