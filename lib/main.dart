import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/date_provider.dart';
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
      child: const _Poarta(),
    );
  }
}

/// Alege ecranul potrivit în funcție de starea de autentificare.
///
/// Când userul e autentificat, `DateProvider` e creat AICI, deasupra
/// `MaterialApp` (deci deasupra Navigator-ului), nu în `HomeShell`: rutele
/// deschise cu `Navigator.push` (ex. VehiculDetaliuScreen) devin intrări noi
/// în Overlay-ul Navigator-ului, frați cu ruta „home", nu descendenți ai ei
/// — un provider declarat sub Scaffold-ul din HomeShell nu e vizibil pentru
/// ele (`ProviderNotFoundError`).
class _Poarta extends StatelessWidget {
  const _Poarta();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.stare == StareAuth.autentificat) {
      return ChangeNotifierProvider<DateProvider>(
        key: ValueKey(auth.dataOwnerUid),
        create: (_) => DateProvider(dataOwnerUid: auth.dataOwnerUid!),
        child: const _App(home: HomeShell()),
      );
    }
    final home = auth.stare == StareAuth.seIncarca
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const LoginScreen();
    return _App(home: home);
  }
}

class _App extends StatelessWidget {
  final Widget home;
  const _App({required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evidență Vehicule',
      debugShowCheckedModeBanner: false,
      theme: _temaCu(Brightness.light),
      darkTheme: _temaCu(Brightness.dark),
      home: home,
    );
  }
}

/// Material3 pune implicit subtitlurile din ListTile pe `onSurfaceVariant`,
/// un gri estompat cu contrast slab (semnalat explicit de user). Le ridicăm
/// pe `onSurface` la opacitate mare, ca să rămână lizibile peste tot unde
/// apar (alerte, liste de vehicule, secțiunile din ecranul de detaliu).
ThemeData _temaCu(Brightness brightness) {
  final tema = ThemeData(
    colorSchemeSeed: const Color(0xFF0891B2),
    useMaterial3: true,
    brightness: brightness,
  );
  return tema.copyWith(
    listTileTheme: tema.listTileTheme.copyWith(
      subtitleTextStyle: tema.textTheme.bodyMedium?.copyWith(
        color: tema.colorScheme.onSurface.withValues(alpha: 0.82),
      ),
    ),
  );
}
