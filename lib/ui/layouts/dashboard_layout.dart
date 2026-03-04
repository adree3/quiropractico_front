import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/ui/shared/sidebar.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        final bool isMedium =
            constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),

          drawer:
              isMobile
                  ? const Drawer(
                    width: 230, // Evita espacio blanco a la derecha
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    child: Sidebar(inDrawerMode: true),
                  )
                  : null,

          // AppBar hamburguesa: solo en móvil
          appBar:
              isMobile
                  ? AppBar(
                    backgroundColor: Colors.white,
                    title: const Text(
                      "Quiropráctica",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                    ),
                  )
                  : null,

          body: Row(
            children: [
              // Sidebar: expandido en > 1100px, colapsado en 700-1100px
              if (!isMobile)
                Sidebar(
                  key: ValueKey(isMedium ? 'medium' : 'large'),
                  initialCollapsed: isMedium,
                ),

              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // Topbar
                    if (!isMobile)
                      Container(
                        height: 56,
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                              ),
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
