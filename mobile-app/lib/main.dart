import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF0A0A0A),
  ));
  runApp(const F650GsApp());
}

class F650GsApp extends StatelessWidget {
  const F650GsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleService(),
      child: MaterialApp(
        title: 'BMW F650GS ECU',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.redAccent,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111111),
            elevation: 0,
          ),
          tabBarTheme: const TabBarTheme(
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
          ),
        ),
        home: const _HomeShell(),
      ),
    );
  }
}

// Ícone do tab Config com badge vermelho quando há queda detectada
class _CrashBadge extends StatelessWidget {
  const _CrashBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (_, ble, __) => Badge(
        isLabelVisible: ble.data.crash,
        backgroundColor: Colors.red,
        child: const Icon(Icons.tune),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    MapsScreen(),
    LogsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF111111),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_on),
            label: 'Mapas',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Log',
          ),
          NavigationDestination(
            icon: _CrashBadge(),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
