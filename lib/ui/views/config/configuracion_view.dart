import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';

class ConfiguracionView extends StatelessWidget {
  const ConfiguracionView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1300 ? 3 : (width > 750 ? 2 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panel de Administración', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        const Text(
          'Gestiona los recursos de tu clínica desde aquí.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),

        Expanded(
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              
              // SERVICIOS Y TARIFAS
              _ConfigCard(
                title: 'Servicios y Tarifas',
                description: 'Crea bonos, modifica precios y gestiona el catálogo.',
                icon: Icons.price_change_outlined,
                color: Colors.blue,
                onTap: () => context.go('/configuracion/servicios'),
              ),

              // EQUIPO (USUARIOS)
              _ConfigCard(
                title: 'Equipo y Usuarios',
                description: 'Da de alta nuevos doctores o recepcionistas.',
                icon: Icons.people_outline,
                color: Colors.orange,
                onTap: () {
                   // context.go('/configuracion/usuarios');
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente")));
                },
              ),

              // HORARIOS
              _ConfigCard(
                title: 'Horarios y Turnos',
                description: 'Define cuándo trabaja cada doctor.',
                icon: Icons.access_time,
                color: Colors.purple,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente")));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConfigCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(description, style: const TextStyle(color: Colors.grey, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}