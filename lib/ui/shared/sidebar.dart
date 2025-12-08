import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final authProvider = Provider.of<AuthProvider>(context);
    final String? userRole = authProvider.role; 
    final bool isAdminOrQuiro = userRole == 'admin' || userRole == 'quiropráctico';
    
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // LOGO
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                const Icon(Icons.health_and_safety, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  'QUIROPRÁCTICA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2
                  ),
                ),
                Text(
                  'Valladolid',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // OPCIONES DEL MENÚ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                if (isAdminOrQuiro) 
                _SidebarItem(
                  icon: Icons.dashboard_outlined, 
                  title: 'Inicio',
                  isActive: location == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_month_outlined, 
                  title: 'Agenda',
                  isActive: location.startsWith('/agenda'),
                  onTap: () => context.go('/agenda'),
                ),
                _SidebarItem(
                  icon: Icons.people_alt_outlined, 
                  title: 'Pacientes',
                  isActive: location.startsWith('/pacientes'),
                  onTap: () => context.go('/pacientes'),
                ),
                
                _SidebarItem(
                  icon: Icons.payment_outlined, 
                  title: 'Pagos',
                  isActive: location.startsWith('/pagos'),
                  onTap: () => context.go('/pagos'),
                ),
                
                if (isAdminOrQuiro) ...[
                   const Divider(height: 30, color: Colors.grey),
                
                   _SidebarItem(
                     icon: Icons.settings_outlined, 
                     title: 'Panel',
                     isActive: location.startsWith('/configuracion'),
                     onTap: () => context.go('/configuracion'), 
                   ),
                ]
              ],
            ),
          ),

          // CERRAR SESIÓN
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Widget para cada boton
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback? onTap;

  const _SidebarItem({required this.icon, required this.title,this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : Colors.grey[600];
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;
    final bg = isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), 
      child: Material( 
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppTheme.primaryColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10), 
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    color: color, 
                    fontWeight: fontWeight,
                    fontSize: 15
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ]
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}