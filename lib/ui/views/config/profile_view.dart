import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _passFormKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersProvider>(context, listen: false).getMe();
    });
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final user = usersProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mi Perfil",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO CARD
                Expanded(
                  flex: 3,
                  child: _buildInfoCard(user),
                ),
                const SizedBox(width: 20),
                // PASSWORD CARD
                Expanded(
                  flex: 2,
                  child: _buildPasswordCard(usersProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(dynamic user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nombreCompleto ?? "Cargando...",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              (user?.rol ?? "").toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.badge_outlined, "Username", user?.username ?? "-"),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_month_outlined,
              "Última Conexión",
              user?.ultimaConexion != null 
                ? user!.ultimaConexion!.toString().split('.').first 
                : "Primera vez",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.check_circle_outline,
              "Estado de Cuenta",
              user?.activo == true ? "Activa" : "Inactiva",
              color: user?.activo == true ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordCard(UsersProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _passFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cambiar Contraseña",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Asegúrate de usar una contraseña segura que no utilices en otros sitios.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                controller: _currentPassCtrl,
                label: "Contraseña Actual",
                hint: "Tu contraseña actual",
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPassCtrl,
                label: "Nueva Contraseña",
                hint: "Mínimo 6 caracteres",
                validator: (v) {
                  if (v == null || v.length < 6) return "Mínimo 6 caracteres";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPassCtrl,
                label: "Confirmar Contraseña",
                hint: "Repite la nueva contraseña",
                validator: (v) {
                  if (v != _newPassCtrl.text) return "Las contraseñas no coinciden";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updatePassword(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text("Actualizar Contraseña"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  void _updatePassword(UsersProvider provider) async {
    if (!_passFormKey.currentState!.validate()) return;

    final result = await provider.updateMyPassword(
      _currentPassCtrl.text,
      _newPassCtrl.text,
    );

    if (!mounted) return;

    if (result == null) {
      CustomSnackBar.show(context, message: "Contraseña actualizada correctamente");
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    } else {
      String msg = result;
      if (result == "CONTRASEÑA_ACTUAL_INCORRECTA") {
        msg = "La contraseña actual no es válida";
      }
      CustomSnackBar.show(context, message: msg, type: SnackBarType.error);
    }
  }
}
