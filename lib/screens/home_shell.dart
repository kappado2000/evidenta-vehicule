import 'package:flutter/material.dart';

import 'costuri/costuri_screen.dart';
import 'dashboard/dashboard_screen.dart';
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
      // Banner plutitor: margine pe toate laturile + colțuri rotunjite +
      // umbră, în loc de bara clasică lipită de marginea ecranului. Ton
      // închis de teal (nu doar accentul deschis din AppBar), cerut explicit.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            color: const Color(0xFF064A59).withValues(alpha: 0.92),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.white70,
                    ),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      fontSize: 11,
                      color: states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  indicatorColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                height: 64,
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
            ),
          ),
        ),
      ),
    );
  }
}
