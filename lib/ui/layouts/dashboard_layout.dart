import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/ui/shared/sidebar.dart';

class DashboardLayout extends StatelessWidget {
  // Vista cambiante
  final Widget child; 

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool esPantallaPequena = constraints.maxWidth < 950;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          
          drawer: esPantallaPequena 
              ? const Drawer(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  child: Sidebar() 
                ) 
              : null,

          appBar: esPantallaPequena
              ? AppBar(
                  backgroundColor: Colors.white,
                  title: const Text("Quiropráctica", style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppTheme.primaryColor),
                      onPressed: () => Scaffold.of(context).openDrawer(), // Abre el menú
                    ),
                  ),
                )
              : null,

          body: Row(
            children: [
              if (!esPantallaPequena) 
                const Sidebar(),

              Expanded(
                child: Column(
                  children: [
                    if (!esPantallaPequena)
                      Container(
                        height: 60,
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 20, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text("Usuario Conectado"),
                          ],
                        ),
                      ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}