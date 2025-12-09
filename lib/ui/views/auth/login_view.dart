import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Row(
        children: [
          if (size.width > 900)
            Expanded(
              flex: 2,
              child: Container(
                color: AppTheme.primaryColor, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.health_and_safety_outlined, size: 100, color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Quiropráctica Valladolid',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Gestión Clínica y Citas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Formulario
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[50],
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.all(24),
                    child: const Padding(
                      padding: EdgeInsets.all(40),
                      child: _LoginForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget del formulario
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isObscure = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.primaryColor
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Introduce tus credenciales',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Usuario
          TextFormField(
            controller: _userController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Ingresa tu nombre de usuario',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 20),

          // Contraseña
          TextFormField(
            controller: _passController,
            obscureText: _isObscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: '********',
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
              return null;
            },
          ),
          
          const SizedBox(height: 30),

          if (authProvider.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Botón
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: authProvider.isLoginLoading ? null : _submit,
              child: authProvider.isLoginLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}