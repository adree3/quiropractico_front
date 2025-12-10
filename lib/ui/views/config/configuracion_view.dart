import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';

class ConfiguracionView extends StatelessWidget {
  const ConfiguracionView({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final int alertasSeguridad = usersProvider.blockedCountDisplay;
    
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1300 ? 3 : (width > 750 ? 2 : 1);
    return Padding(
      padding: const EdgeInsets.all(30), // Un poco de margen general
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la Sección
          const Text(
            "Panel de Control",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Configuración general de la clínica y gestión de recursos.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          
          const SizedBox(height: 40),

          // GRID DE TARJETAS
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
                  subtitle: 'Crea bonos, modifica precios y gestiona el catálogo.',
                  icon: Icons.price_change_outlined,
                  color: Colors.blue,
                  onTap: () => context.go('/configuracion/servicios'),
                ),

                // EQUIPO (USUARIOS)
                Badge(
                  isLabelVisible: alertasSeguridad > 0, // Solo visible si hay bloqueados y no se ha visto
                  label: Text(
                    alertasSeguridad.toString(), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  backgroundColor: Colors.red, // Rojo urgente
                  largeSize: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  offset: const Offset(-5, 5), // Ajuste visual para la esquina
                  child: _ConfigCard(
                    title: "Gestión de Equipo",
                    subtitle: "Administra empleados y permisos",
                    icon: Icons.people_alt,
                    color: Colors.orange, // Color base de la tarjeta
                    onTap: () => context.go('/configuracion/usuarios'),
                  ),
                ),

                // HORARIOS
                _ConfigCard(
                  title: 'Horarios y Turnos',
                  subtitle: 'Define cuándo trabaja cada doctor.',
                  icon: Icons.access_time,
                  color: Colors.purple,
                  onTap: () => context.go('/configuracion/horarios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConfigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        hoverColor: color.withOpacity(0.05), // Efecto hover sutil
        child: Container(
          width: 300, // Ancho fijo para que se vean uniformes en el Wrap
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono con fondo de color suave
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 20),
              
              // Textos
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey[600],
                  height: 1.4
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Flechita "Ir"
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Configurar", style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_forward, size: 18, color: color),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}