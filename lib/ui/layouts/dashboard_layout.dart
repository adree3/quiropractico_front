import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/auth_provider.dart';
import 'package:quiropractico_front/ui/shared/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quiropractico_front/ui/widgets/user_avatar_widget.dart';

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
                    width: 230,
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
                      Consumer<UsersProvider>(
                        builder: (context, usersProvider, child) {
                          final user = usersProvider.currentUser;
                          if (user == null && !usersProvider.isLoading) {
                            Future.microtask(() {
                              usersProvider.getMe();
                              context.read<AuthProvider>().refreshGlobalData(context);
                            });
                          }
                          return Container(
                            height: 56,
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context, rootNavigator: true).popUntil((route) => route is! PopupRoute);
                                      context.push('/perfil');
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    hoverColor: AppTheme.primaryColor.withOpacity(0.05),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: GoRouterState.of(context).uri.toString() == '/perfil' ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          UserAvatarWidget(
                                            usuario: user,
                                            profilePictureVersion: usersProvider.profilePictureVersion,
                                            radius: 16,
                                            fontSize: 14,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            user?.nombreCompleto ?? "Cargando...",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    Expanded(
                      child: Padding(
                        padding: GoRouterState.of(context).uri.toString().startsWith('/configuracion')
                            ? EdgeInsets.zero
                            : const EdgeInsets.all(20),
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
