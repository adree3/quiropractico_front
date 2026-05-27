import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:quiropractico_front/ui/views/settings/widgets/settings_nav_item.dart';
import 'package:quiropractico_front/ui/views/settings/tabs/profile_tab.dart';
import 'package:quiropractico_front/ui/views/settings/tabs/storage_tab.dart';
import 'package:quiropractico_front/ui/views/settings/tabs/legal_tab.dart';
import 'package:quiropractico_front/ui/views/settings/tabs/audit_tab.dart';

/// Vista principal del módulo de Configuración.
///
/// Actúa exclusivamente como contenedor (Shell):
/// - Inyecta el [SettingsProvider] en el árbol.
/// - Renderiza el layout Master-Detail (sidebar + contenido).
/// - Delega todo el contenido de cada pestaña a sus respectivos tab widgets.
class SettingsView extends StatelessWidget {
  final String currentTab;

  const SettingsView({Key? key, required this.currentTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: _SettingsShell(currentTab: currentTab),
    );
  }
}

// Definición de secciones
class _SettingsSection {
  final String title;
  final IconData icon;
  final Widget tab;
  final String routePath;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.tab,
    required this.routePath,
  });
}

const List<_SettingsSection> _sections = [
  _SettingsSection(
    title: 'Perfil de Clínica',
    icon: Icons.business,
    tab: ProfileTab(),
    routePath: 'perfil',
  ),
  _SettingsSection(
    title: 'Almacenamiento',
    icon: Icons.cloud_outlined,
    tab: StorageTab(),
    routePath: 'almacenamiento',
  ),
  _SettingsSection(
    title: 'Textos Legales',
    icon: Icons.gavel_outlined,
    tab: LegalTab(),
    routePath: 'legal',
  ),
  _SettingsSection(
    title: 'Auditoría',
    icon: Icons.security_outlined,
    tab: AuditTab(),
    routePath: 'auditoria',
  ),
];

// Shell (Master-Detail layout)
class _SettingsShell extends StatelessWidget {
  final String currentTab;

  const _SettingsShell({Key? key, required this.currentTab}) : super(key: key);

  int get _selectedIndex {
    final index = _sections.indexWhere((s) => s.routePath == currentTab);
    return index != -1 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    // El provider sigue estando disponible si los tabs lo necesitan
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master: Menú lateral
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
                left: BorderSide(color: Colors.grey.shade300, width: 1),
                right: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      return SettingsNavItem(
                        icon: _sections[index].icon,
                        title: _sections[index].title,
                        isSelected: _selectedIndex == index,
                        onTap: () {
                          context.go('/configuracion/${_sections[index].routePath}');
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Detail: Contenido de la pestaña activa
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sections[_selectedIndex].title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _sections[_selectedIndex].tab,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

