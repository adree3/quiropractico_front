import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/ui/layouts/dashboard_layout.dart';
import 'package:quiropractico_front/ui/views/auth/login_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/cliente_detalle_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/clients_view.dart';

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

      if (authStatus == AuthStatus.notAuthenticated && !isGoingToLogin) {
        return '/login';
      }

      if (authStatus == AuthStatus.authenticated && isGoingToLogin) {
        return '/agenda';
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
            path: '/agenda',
            builder: (context, state) => const AgendaView(),
          ),
          GoRoute(
            path: '/pacientes',
            builder: (context, state) => const ClientsView(),
          ),
          GoRoute(
            path: '/pacientes/:uid', // :uid es el placeholder
            builder: (context, state) {
              final String id = state.pathParameters['uid'] ?? '0';
              return ClienteDetalleView(idCliente: int.parse(id));
            },
          ),
        ],
      ),
    ],
  );
}