import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/services/navigation_service.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/ui/layouts/dashboard_layout.dart';
import 'package:quiropractico_front/ui/views/auth/auth_layout.dart';
import 'package:quiropractico_front/ui/views/auth/login_view.dart';
import 'package:quiropractico_front/ui/views/auth/workspace_finder_view.dart';
import 'package:quiropractico_front/ui/views/config/auditoria_view.dart';
import 'package:quiropractico_front/ui/views/settings/settings_view.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/ui/views/config/schedule_view.dart';
import 'package:quiropractico_front/ui/views/config/services_view.dart';
import 'package:quiropractico_front/ui/views/config/users_view.dart';
import 'package:quiropractico_front/ui/views/config/vacaciones_calendar_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/agenda_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/bonos_history_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/citas_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/cliente_detalle_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/clients_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/payments_view.dart';
import 'package:quiropractico_front/ui/views/config/profile_view.dart';
import 'package:quiropractico_front/ui/views/dashboard/kiosk_view.dart';

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: '/agenda',
    refreshListenable: authProvider,

    redirect: (context, state) {
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToFinder = state.matchedLocation == '/workspace-finder';
      final authStatus = authProvider.authStatus;
      final clinicaId = LocalStorage.getClinicaId();

      // 1. Si no hay clinicaId en caché y no estamos yendo al finder, redirigir al finder
      if (clinicaId == null && !isGoingToFinder) {
        return '/workspace-finder';
      }

      // 2. Si hay clinicaId, pero el usuario no está autenticado, y no estamos en login ni finder, redirigir a login
      if (clinicaId != null &&
          (authStatus == AuthStatus.notAuthenticated || authStatus == AuthStatus.locked) &&
          !isGoingToLogin && !isGoingToFinder) {
        return '/login';
      }

      // 3. Si el usuario está autenticado y trata de ir a login o finder, redirigir a agenda
      if (authStatus == AuthStatus.authenticated && (isGoingToLogin || isGoingToFinder)) {
        return '/agenda';
      }

      // 4. Proteger /configuracion solo para ADMIN / SUPER_ADMIN
      if (state.matchedLocation.startsWith('/configuracion')) {
        if (!authProvider.isAdmin) {
          return '/agenda';
        }
      }

      return null;
    },

    routes: [
      GoRoute(path: '/workspace-finder', builder: (context, state) => const AuthLayout(child: WorkspaceFinderView())),
      GoRoute(path: '/login', builder: (context, state) => const AuthLayout(child: LoginView())),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return DashboardLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/agenda',
            builder: (context, state) {
              final fechaStr = state.uri.queryParameters['fecha'];
              final initialDate =
                  fechaStr != null ? DateTime.tryParse(fechaStr) : null;
              return AgendaView(initialDate: initialDate);
            },
          ),
          GoRoute(
            path: '/citas',
            builder: (context, state) => const CitasView(),
          ),
          GoRoute(
            path: '/pacientes',
            builder: (context, state) => const ClientsView(),
          ),
          GoRoute(
            path: '/pacientes/:uid',
            builder: (context, state) {
              final String id = state.pathParameters['uid'] ?? '0';

              // Leer query parameters opcionales
              final tabParam =
                  state.uri.queryParameters['tab'] ??
                  state.uri.queryParameters['tabIndex'];
              final filtroParam = state.uri.queryParameters['filtro'];
              final showBonoParam = state.uri.queryParameters['showBono'];
              final resaltarCitaParam =
                  state.uri.queryParameters['resaltarCitaId'];

              final initialTab =
                  tabParam != null ? int.tryParse(tabParam) : null;
              final resaltarCitaId =
                  resaltarCitaParam != null
                      ? int.tryParse(resaltarCitaParam)
                      : null;

              return ClienteDetalleView(
                idCliente: int.parse(id),
                initialTab: initialTab,
                initialFilter: filtroParam,
                showBono: showBonoParam == 'true',
                resaltarCitaId: resaltarCitaId,
              );
            },
          ),
          GoRoute(
            path: '/pagos',
            builder: (context, state) => const PaymentsView(),
          ),
          GoRoute(
            path: '/bonos',
            builder: (context, state) => const BonosHistoryView(),
          ),
          GoRoute(
            path: '/servicios',
            builder: (context, state) => const ServicesView(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const UsersView(),
          ),
          GoRoute(
            path: '/horarios',
            builder: (context, state) => const ScheduleView(),
          ),
          GoRoute(
            path: '/vacaciones',
            builder: (context, state) => const VacacionesCalendarView(),
          ),
          GoRoute(
            path: '/logs',
            builder: (context, state) => const AuditoriaView(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const ProfileView(),
          ),
          GoRoute(
            path: '/perfil/:id',
            builder: (context, state) {
              final String id = state.pathParameters['id'] ?? '0';
              return ProfileView(targetUserId: int.tryParse(id));
            },
          ),
          GoRoute(
            path: '/configuracion',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
      GoRoute(
        path: '/kiosk',
        builder: (context, state) => const KioskView(),
      ),
    ],
  );
}
