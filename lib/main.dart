import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/router/app_router.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/clients_provider.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/services_provider.dart';
import 'package:quiropractico_front/providers/ventas_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.configurePrefs();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => AgendaProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => HorariosProvider()),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appRouter = AppRouter(authProvider);
    return MaterialApp.router(
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Quiripráctico Valladolid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      routerConfig: appRouter.router,
    );
  }
}