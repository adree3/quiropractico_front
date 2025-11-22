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
          if (size.width > 800)
            Expanded(
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
                      'Gestión integral de pacientes y citas',
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
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400), // Ancho máximo para que no se estire feo
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(32),
                    child: _LoginForm(),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Inicia sesión para acceder al panel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Usuario
          TextFormField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Ingresa tu nombre de usuario',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'El usuario es obligatorio';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Contraseña
          TextFormField(
            controller: _passController,
            obscureText: _isObscure,
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
          
          const SizedBox(height: 40),

          // Botón
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Validando credenciales...')),
                  );
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  
                  final success = await authProvider.login(
                    _userController.text.trim(), 
                    _passController.text.trim()
                  );

                  if (!success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Credenciales incorrectas'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('INICIAR SESIÓN'),
            ),
          ),
        ],
      ),
    );
  }
}