import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/ui/layouts/dashboard_layout.dart';
import 'package:quiropractico_front/ui/views/auth/login_view.dart';
import 'package:quiropractico_front/ui/views/config/configuracion_view.dart';
import 'package:quiropractico_front/ui/views/config/schedule_view.dart';
import 'package:quiropractico_front/ui/views/config/services_view.dart';
import 'package:quiropractico_front/ui/views/config/users_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/cliente_detalle_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/clients_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/home_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/payments_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/agenda',
    refreshListenable: authProvider,
    
    redirect: (context, state) {
      final isGoingToLogin = state.matchedLocation == '/login';
      final authStatus = authProvider.authStatus;
      final role = authProvider.role;

      if ((authStatus == AuthStatus.notAuthenticated || authStatus == AuthStatus.locked) && !isGoingToLogin) {
        return '/login';
      }

      if (authStatus == AuthStatus.authenticated && isGoingToLogin) {
        if (role == 'admin' || role == 'quiropráctico') {
           return '/agenda';
        } else {
           return '/agenda';
        }
      }

      return null; 
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return DashboardLayout(child: child); 
        },
        routes: [
          GoRoute(
             path: '/dashboard',
             builder: (context, state) => const HomeView(),
           ),
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaView(),
          ),
          GoRoute(
            path: '/pacientes',
            builder: (context, state) => const ClientsView(),
          ),
          GoRoute(
            path: '/pacientes/:uid',
            builder: (context, state) {
              final String id = state.pathParameters['uid'] ?? '0';
              return ClienteDetalleView(idCliente: int.parse(id));
            },
          ),
          GoRoute(
            path: '/pagos',
            builder: (context, state) => const PaymentsView(), // <--- CONECTAR AQUÍ
          ),
          GoRoute(
            path: '/configuracion',
            builder: (context, state) => const ConfiguracionView(),
            routes: [
              GoRoute(
                path: 'servicios',
                builder: (context, state) => const ServicesView(), 
              ),
              GoRoute(
                path: 'usuarios',
                builder: (context, state) => const UsersView(),
              ),
              GoRoute(
                path: 'horarios',
                builder: (context, state) => const ScheduleView(),
              ),
            ]
          ),
        ],
      ),
    ],
  );
}