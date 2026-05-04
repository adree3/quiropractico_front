import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

/// Pestaña "Perfil de Clínica" del módulo de configuración.
///
/// Contiene los formularios de:
/// - Información General (nombre, CIF/NIF, logo placeholder)
/// - Contacto y Ubicación (teléfono, email, dirección)
class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _cifCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dirCtrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    _nombreCtrl = TextEditingController(text: provider.nombre);
    _cifCtrl = TextEditingController(text: provider.cifNif);
    _telCtrl = TextEditingController(text: provider.telefono);
    _emailCtrl = TextEditingController(text: provider.emailContacto);
    _dirCtrl = TextEditingController(text: provider.direccion);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cifCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        // Banner de error
        if (provider.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sección: Información General
        const Text(
          'Información General',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Logo placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.business,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildTextField(
                    'Nombre de la Clínica',
                    'Ej. Quiropráctica Madrid',
                    _nombreCtrl,
                    (v) => provider.nombre = v,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'CIF / NIF',
                    'B-12345678',
                    _cifCtrl,
                    (v) => provider.cifNif = v,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),

        // Sección: Contacto y Ubicación
        const Text(
          'Contacto y Ubicación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Teléfono',
                '+34 600 000 000',
                _telCtrl,
                (v) => provider.telefono = v,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Email de Contacto',
                'contacto@clinica.com',
                _emailCtrl,
                (v) => provider.emailContacto = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Dirección Completa',
          'Calle Principal 123, Madrid',
          _dirCtrl,
          (v) => provider.direccion = v,
        ),

        const SizedBox(height: 32),

        // Botón Guardar
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    final success = await provider.saveSettings();
                    if (success && context.mounted) {
                      CustomSnackBar.show(
                        context,
                        message: 'Configuración guardada correctamente',
                        type: SnackBarType.success,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // Campo de texto reutilizable
  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
            ),
          ),
        ),
      ],
    );
  }
}
