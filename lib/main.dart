import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EvidentaVehiculeApp());
}

class EvidentaVehiculeApp extends StatelessWidget {
  const EvidentaVehiculeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Evidență Vehicule',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0891B2),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF0891B2),
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const _Poarta(),
      ),
    );
  }
}

/// Alege ecranul potrivit în funcție de starea de autentificare.
class _Poarta extends StatelessWidget {
  const _Poarta();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.stare) {
      case StareAuth.seIncarca:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case StareAuth.neautentificat:
        return const LoginScreen();
      case StareAuth.autentificat:
        return HomeShell(dataOwnerUid: auth.dataOwnerUid!);
    }
  }
}
