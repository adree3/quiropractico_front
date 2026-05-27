import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/settings_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/ui/shared/custom_phone_field.dart';
import 'package:quiropractico_front/ui/shared/skeletons.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _hasAttemptedSubmit = false;

  late TextEditingController _nombreCtrl;
  late TextEditingController _cifCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dirCtrl;
  String? _telefonoValue;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SettingsProvider>();
    _nombreCtrl = TextEditingController(text: provider.nombre);
    _cifCtrl = TextEditingController(text: provider.cifNif);
    _emailCtrl = TextEditingController(text: provider.emailContacto);
    _dirCtrl = TextEditingController(text: provider.direccion);
    _telefonoValue = provider.telefono;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cifCtrl.dispose();
    _emailCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Form(
      key: _formKey,
      autovalidateMode:
          _hasAttemptedSubmit
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: ListView(
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
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
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
              provider.isLoading
                  ? const SkeletonAvatar(size: 100)
                  : Container(
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
                    provider.isLoading
                        ? const SkeletonInput()
                        : _buildTextField(
                            label: 'Nombre de la Clínica',
                            hint: 'Ej. Quiropráctica Madrid',
                            controller: _nombreCtrl,
                            onChanged: (v) => provider.nombre = v,
                            validator: (v) {
                              if (v == null || v.trim().length < 3) {
                                return 'Mínimo 3 caracteres';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),
                    provider.isLoading
                        ? const SkeletonInput()
                        : _buildTextField(
                            label: 'CIF / NIF',
                            hint: 'B-12345678',
                            controller: _cifCtrl,
                            onChanged: (v) => provider.cifNif = v,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: provider.isLoading
                    ? const SkeletonInput()
                    : CustomPhoneField(
                        label: 'Teléfono',
                        initialValue: _telefonoValue,
                        onChanged: (v) {
                          _telefonoValue = v;
                          provider.telefono = v;
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Introduce un número de teléfono válido';
                          }
                          final cleanPhone = v.replaceAll(' ', '');
                          if (cleanPhone.length < 9) {
                            return 'Introduce un número de teléfono válido';
                          }
                          return null;
                        },
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: provider.isLoading
                    ? const SkeletonInput()
                    : _buildTextField(
                        label: 'Email de Contacto',
                        hint: 'contacto@clinica.com',
                        controller: _emailCtrl,
                        onChanged: (v) => provider.emailContacto = v,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          provider.isLoading
              ? const SkeletonInput()
              : _buildTextField(
                  label: 'Dirección Completa',
                  hint: 'Calle Principal 123, Madrid',
                  controller: _dirCtrl,
                  onChanged: (v) => provider.direccion = v,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),

          const SizedBox(height: 32),

          // Botón Guardar
          Align(
            alignment: Alignment.centerRight,
            child: provider.isLoading
                ? const SkeletonBox(width: 200, height: 50, borderRadius: 8)
                : ElevatedButton(
                    onPressed:
                        provider.isSaving
                            ? null
                            : () async {
                                setState(() {
                                  _hasAttemptedSubmit = true;
                                });

                                if (_formKey.currentState!.validate()) {
                                  final success = await provider.saveSettings();
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message:
                                          success
                                              ? 'Configuración guardada correctamente'
                                              : 'Error al guardar la configuración',
                                      type:
                                          success
                                              ? SnackBarType.success
                                              : SnackBarType.error,
                                    );
                                  }
                                }
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        provider.isSaving
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
      ),
    );
  }

  // Campo de texto reutilizable con validación
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
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
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
