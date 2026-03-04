import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/providers/payments_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';

const double _kExpandedWidth = 230.0;
const double _kCollapsedWidth = 68.0;
const Duration _kDuration = Duration(milliseconds: 190);

class Sidebar extends StatefulWidget {
  final bool initialCollapsed;
  final bool inDrawerMode;

  const Sidebar({
    super.key,
    this.initialCollapsed = false,
    this.inDrawerMode = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initialCollapsed;
    _ctrl = AnimationController(
      vsync: this,
      duration: _kDuration,
      value: _collapsed ? 0.0 : 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_collapsed) {
      setState(() {
        _collapsed = false;
      });
      _ctrl.forward();
    } else {
      setState(() {
        _collapsed = true;
      });
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── MODO DRAWER (móvil) ─────────────────────────────────────────────────
    // Estático, sin toggle, sin AnimatedBuilder. No afecta al sidebar normal.
    if (widget.inDrawerMode) {
      return _buildDrawerContent(context);
    }

    final String location = GoRouterState.of(context).uri.toString();
    final authProvider = Provider.of<AuthProvider>(context);
    final pagosPendientes =
        Provider.of<PaymentsProvider>(context).globalPendingCount;
    final alertasEquipo =
        Provider.of<UsersProvider>(context).blockedCountDisplay;
    final bool isAdminOrQuiro =
        authProvider.role == 'admin' || authProvider.role == 'quiropráctico';

    // ── Items precompilados ────────────────────────────────────────────────
    // Se construyen una sola vez por setState (toggle/hover),
    // NO en cada frame de animación. AnimatedBuilder los pasa como `child`.
    final itemsList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _SidebarItem(
          icon: Icons.calendar_month_outlined,
          title: 'Agenda',
          isActive: location.startsWith('/agenda'),
          isCollapsed: _collapsed,
          onTap: () => context.go('/agenda'),
        ),
        _SidebarItem(
          icon: Icons.date_range,
          title: 'Citas',
          isActive: location.startsWith('/citas'),
          isCollapsed: _collapsed,
          onTap: () => context.go('/citas'),
        ),
        _SidebarItem(
          icon: Icons.people_alt_outlined,
          title: 'Pacientes',
          isActive: location.startsWith('/pacientes'),
          isCollapsed: _collapsed,
          onTap: () => context.go('/pacientes'),
        ),
        _SidebarItem(
          icon: Icons.payment_outlined,
          title: 'Pagos',
          isActive: location.startsWith('/pagos'),
          isCollapsed: _collapsed,
          onTap: () => context.go('/pagos'),
          badgeCount: pagosPendientes,
          badgeColor: Colors.orange,
        ),
        if (isAdminOrQuiro) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Divider(thickness: 0.5, height: 1),
          ),
          _SidebarItem(
            icon: Icons.manage_accounts_outlined,
            title: 'Equipo',
            isActive: location.startsWith('/usuarios'),
            isCollapsed: _collapsed,
            badgeCount: alertasEquipo,
            badgeColor: Colors.red,
            onTap: () => context.go('/usuarios'),
          ),
          _SidebarItem(
            icon: Icons.euro,
            title: 'Servicios',
            isActive: location.startsWith('/servicios'),
            isCollapsed: _collapsed,
            onTap: () => context.go('/servicios'),
          ),
          _SidebarItem(
            icon: Icons.access_time,
            title: 'Horarios',
            isActive: location.startsWith('/horarios'),
            isCollapsed: _collapsed,
            onTap: () => context.go('/horarios'),
          ),
          _SidebarItem(
            icon: Icons.beach_access_outlined,
            title: 'Vacaciones',
            isActive: location.startsWith('/vacaciones'),
            isCollapsed: _collapsed,
            onTap: () => context.go('/vacaciones'),
          ),
          _SidebarItem(
            icon: Icons.file_present_sharp,
            title: 'Logs',
            isActive: location.startsWith('/logs'),
            isCollapsed: _collapsed,
            onTap: () => context.go('/logs'),
          ),
        ],
      ],
    );

    return MouseRegion(
      child: AnimatedBuilder(
        animation: _ctrl,
        child: itemsList, // ← Solo se reconstruye en setState, no por frame
        builder: (context, child) {
          final t = _ctrl.value;
          final w = lerpDouble(_kCollapsedWidth, _kExpandedWidth, t)!;

          return SizedBox(
            width: w,
            child: ClipRect(
              // OverflowBox: contenido interior siempre 250px.
              // ClipRect recorta a 'w' sin errores de RenderFlex.
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: _kExpandedWidth,
                maxWidth: _kExpandedWidth,
                child: SizedBox(
                  width: _kExpandedWidth,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildHeader(context, t),
                        const SizedBox(height: 8),
                        Expanded(child: child!), // Items precompilados
                        const Divider(height: 0),
                        _buildLogout(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Drawer mode: sidebar estático sin toggle ──────────────────────────────
  Widget _buildDrawerContent(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final authProvider = Provider.of<AuthProvider>(context);
    final pagosPendientes =
        Provider.of<PaymentsProvider>(context).globalPendingCount;
    final alertasEquipo =
        Provider.of<UsersProvider>(context).blockedCountDisplay;
    final bool isAdminOrQuiro =
        authProvider.role == 'admin' || authProvider.role == 'quiropráctico';

    return Container(
      width: _kExpandedWidth,
      color: Colors.white,
      child: Column(
        children: [
          // Header sin toggle
          Container(
            color: AppTheme.primaryColor,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'QUIROPRÁCTICA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Valladolid',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _SidebarItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Agenda',
                  isActive: location.startsWith('/agenda'),
                  onTap: () => GoRouter.of(context).go('/agenda'),
                ),
                _SidebarItem(
                  icon: Icons.date_range,
                  title: 'Gestión Citas',
                  isActive: location.startsWith('/citas'),
                  onTap: () => GoRouter.of(context).go('/citas'),
                ),
                _SidebarItem(
                  icon: Icons.people_alt_outlined,
                  title: 'Pacientes',
                  isActive: location.startsWith('/pacientes'),
                  onTap: () => GoRouter.of(context).go('/pacientes'),
                ),
                _SidebarItem(
                  icon: Icons.payment_outlined,
                  title: 'Pagos',
                  isActive: location.startsWith('/pagos'),
                  onTap: () => GoRouter.of(context).go('/pagos'),
                  badgeCount: pagosPendientes,
                  badgeColor: Colors.orange,
                ),
                if (isAdminOrQuiro) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Divider(thickness: 0.5, height: 1),
                  ),
                  _SidebarItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Equipo',
                    isActive: location.startsWith('/usuarios'),
                    badgeCount: alertasEquipo,
                    badgeColor: Colors.red,
                    onTap: () => GoRouter.of(context).go('/usuarios'),
                  ),
                  _SidebarItem(
                    icon: Icons.euro,
                    title: 'Servicios',
                    isActive: location.startsWith('/servicios'),
                    onTap: () => GoRouter.of(context).go('/servicios'),
                  ),
                  _SidebarItem(
                    icon: Icons.access_time,
                    title: 'Horarios',
                    isActive: location.startsWith('/horarios'),
                    onTap: () => GoRouter.of(context).go('/horarios'),
                  ),
                  _SidebarItem(
                    icon: Icons.beach_access_outlined,
                    title: 'Vacaciones',
                    isActive: location.startsWith('/vacaciones'),
                    onTap: () => GoRouter.of(context).go('/vacaciones'),
                  ),
                  _SidebarItem(
                    icon: Icons.file_present_sharp,
                    title: 'Logs',
                    isActive: location.startsWith('/logs'),
                    onTap: () => GoRouter.of(context).go('/logs'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          _buildLogout(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double t) {
    final showContent = t > 0.15;

    return AnimatedSize(
      duration: _kDuration,
      curve: Curves.easeOut,
      child: Container(
        color: AppTheme.primaryColor,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: 4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    // Fondo siempre visible en botón hamburguesa
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Tooltip(
                    message: _collapsed ? 'Expandir menú' : 'Ocultar menú',
                    child: InkWell(
                      onTap: _toggle,
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white24,
                      hoverColor: Colors.white12,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          t > 0.5 ? Icons.menu_open : Icons.menu,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Icono + texto: solo cuando el sidebar está abierto
            if (showContent) ...[
              const SizedBox(height: 6),
              const Center(
                child: Icon(
                  Icons.health_and_safety,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'QUIROPRÁCTICA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Valladolid',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Widget _buildLogout(BuildContext context) {
    return Tooltip(
      message: _collapsed ? 'Cerrar Sesión' : '',
      child: InkWell(
        onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: const [
              Icon(Icons.logout, color: AppTheme.errorColor),
              // 16(pad) + 24(icon) + 28(gap) = 68px →
              // texto empieza exactamente en el borde del ClipRect
              SizedBox(width: 28),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sidebar Item ───────────────────────────────────────────────────────────────
// Siempre renderiza el Row completo — el ClipRect del padre recorta visualmente.
// Activo: borde izquierdo de acento (funciona en modos colapsado y expandido).
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final int badgeCount;
  final Color badgeColor;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.isCollapsed = false,
    this.onTap,
    this.badgeCount = 0,
    this.badgeColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : Colors.grey[600];
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    final iconWidget =
        badgeCount > 0
            ? Badge(
              label: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: badgeColor,
              offset: const Offset(6, -6),
              child: Icon(icon, color: color, size: 22),
            )
            : Icon(icon, color: color, size: 22);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: isCollapsed ? title : '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            // Sin borderRadius en activo para que el borde izquierdo quede limpio
            borderRadius: isActive ? null : BorderRadius.circular(10),
            hoverColor: AppTheme.primaryColor.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isActive
                        ? AppTheme.primaryColor.withOpacity(0.08)
                        : Colors.transparent,
                // Borde izquierdo de acento en modo activo.
                // Sin borderRadius para evitar conflicto con Border parcial.
                border:
                    isActive
                        ? const Border(
                          left: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 3,
                          ),
                        )
                        : null,
                borderRadius: isActive ? null : BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  iconWidget,
                  // 16(pad) + 22(icon) + 30(gap) = 68px →
                  // texto empieza en el borde del ClipRect cuando está colapsado
                  const SizedBox(width: 30),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: fontWeight,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
