import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const _SettingsShell(),
    );
  }
}

// Definición de secciones
class _SettingsSection {
  final String title;
  final IconData icon;
  final Widget tab;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.tab,
  });
}

const List<_SettingsSection> _sections = [
  _SettingsSection(
    title: 'Perfil de Clínica',
    icon: Icons.business,
    tab: ProfileTab(),
  ),
  _SettingsSection(
    title: 'Almacenamiento',
    icon: Icons.cloud_outlined,
    tab: StorageTab(),
  ),
  _SettingsSection(
    title: 'Textos Legales',
    icon: Icons.gavel_outlined,
    tab: LegalTab(),
  ),
  _SettingsSection(
    title: 'Auditoría',
    icon: Icons.security_outlined,
    tab: AuditTab(),
  ),
];

// Shell (Master-Detail layout)
class _SettingsShell extends StatefulWidget {
  const _SettingsShell({Key? key}) : super(key: key);

  @override
  State<_SettingsShell> createState() => _SettingsShellState();
}

class _SettingsShellState extends State<_SettingsShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                        onTap: () => setState(() => _selectedIndex = index),
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
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _sections[_selectedIndex].tab,
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
