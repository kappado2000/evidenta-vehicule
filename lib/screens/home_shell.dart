import 'package:flutter/material.dart';

import 'costuri/costuri_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'garaj/garaj_screen.dart';
import 'setari/setari_screen.dart';
import 'vehicule/lista_vehicule_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  static const _ecrane = [
    DashboardScreen(),
    ListaVehiculeScreen(),
    GarajScreen(),
    CosturiScreen(),
    SetariScreen(),
  ];

  // Dacă userul e într-un ecran deschis cu Navigator.push (detaliu vehicul,
  // formular etc.), revine întâi la ecranul de bază al tabului curent -
  // altfel schimbarea tabului ar rămâne ascunsă sub ecranul deschis, fiindcă
  // toate tab-urile împart același Navigator imbricat (vezi comentariul de
  // pe `Navigator` mai jos).
  void _schimbaTab(int i) {
    _navigatorKey.currentState?.popUntil((r) => r.isFirst);
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Navigator imbricat: orice `Navigator.of(context).push(...)` apelat
      // din ecranele tab-urilor (ex. VehiculDetaliuScreen) găsește ACEST
      // Navigator ca cel mai apropiat ascendent, nu pe cel al MaterialApp -
      // deci ecranele împinse rămân în interiorul `body`-ului, sub bara de
      // jos, care astfel rămâne vizibilă permanent pe toate paginile
      // aplicației, nu doar pe cele 5 ecrane de bază ale tab-urilor.
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => IndexedStack(index: _index, children: _ecrane),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer
            .withValues(alpha: 0.8),
        selectedIndex: _index,
        onDestinationSelected: _schimbaTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerte',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Vehicule',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Garaj',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Costuri',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Setări',
          ),
        ],
      ),
    );
  }
}
