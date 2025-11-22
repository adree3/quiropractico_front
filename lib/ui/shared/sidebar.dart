import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
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
              children: [
                _SidebarItem(
                  icon: Icons.calendar_month_outlined, 
                  title: 'Agenda',
                  onTap: () => context.go('/agenda'),
                ),
                _SidebarItem(
                  icon: Icons.people_alt_outlined, 
                  title: 'Pacientes',
                  onTap: () => context.go('/pacientes'),
                ),
                const _SidebarItem(icon: Icons.payment_outlined, title: 'Pagos y Bonos'),
                const Divider(),
                const _SidebarItem(icon: Icons.settings_outlined, title: 'Configuración'),
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
  final VoidCallback? onTap;

  const _SidebarItem({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondaryColor),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w500),
      ),
      hoverColor: AppTheme.primaryColor.withOpacity(0.1), // Efecto hover sutil
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      onTap: onTap ?? () {}, 
    );
  }
}