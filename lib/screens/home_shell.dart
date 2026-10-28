import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/date_provider.dart';
import 'costuri/costuri_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'garaj/garaj_screen.dart';
import 'setari/setari_screen.dart';
import 'vehicule/lista_vehicule_screen.dart';

class HomeShell extends StatefulWidget {
  final String dataOwnerUid;

  const HomeShell({super.key, required this.dataOwnerUid});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _ecrane = [
    DashboardScreen(),
    ListaVehiculeScreen(),
    GarajScreen(),
    CosturiScreen(),
    SetariScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(widget.dataOwnerUid),
      create: (_) => DateProvider(dataOwnerUid: widget.dataOwnerUid),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _ecrane),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: 'Alerte'),
            NavigationDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car),
                label: 'Vehicule'),
            NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Garaj'),
            NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Costuri'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Setări'),
          ],
        ),
      ),
    );
  }
}
