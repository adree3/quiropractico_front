import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/providers/horarios_provider.dart';
import 'package:quiropractico_front/providers/users_provider.dart';
import 'package:quiropractico_front/services/local_storage.dart';
import 'package:quiropractico_front/services/navigation_service.dart';
import 'package:quiropractico_front/ui/widgets/custom_snackbar.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:file_picker/file_picker.dart';

const _kBorder = Color(0xFFECECF0);
const _kSurface = Color(0xFFF8F9FB);
const _kTextMain = Color(0xFF1A1D23);
const _kTextSub = Color(0xFF9095A3);

class ProfileView extends StatefulWidget {
  final int? targetUserId;
  const ProfileView({super.key, this.targetUserId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _defaultView = LocalStorage.getDefaultAgendaView();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      if (widget.targetUserId == null) {
        usersProvider.getMe();
      } else {
        if (usersProvider.usuarios.isEmpty) {
          usersProvider.getUsers();
        }
      }

      // Cargar horarios (para sección quiro)
      Provider.of<HorariosProvider>(context, listen: false).loadAllHorariosGlobales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final horariosProvider = Provider.of<HorariosProvider>(context);
    
    final bool isCurrentUser = widget.targetUserId == null || widget.targetUserId == usersProvider.currentUser?.idUsuario;
    dynamic user;
    if (isCurrentUser) {
      user = usersProvider.currentUser;
    } else {
      try {
        user = usersProvider.usuarios.firstWhere((u) => u.idUsuario == widget.targetUserId);
      } catch (e) {
        user = null;
      }
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final esQuiro = user.rol.toLowerCase() == 'quiropráctico' || user.rol.toLowerCase() == 'quiropractico';

    // ── Horarios del quiro ────────────────────────────────────
    final horariosQuiro = user == null ? [] : horariosProvider.horariosGlobales
        .where((h) => h.idQuiropractico == user.idUsuario)
        .toList()
        ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header con botón atrás ────────────────────────
            Row(
              children: [
                _BackButton(),
                const SizedBox(width: 12),
                Text(
                  isCurrentUser ? 'Mi Perfil' : 'Perfil de ${user.nombreCompleto}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _kTextMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── ZONA 1: Hero card ─────────────────────────────
            _HeroCard(
              user: user,
              profilePictureVersion: isCurrentUser ? usersProvider.profilePictureVersion : 0,
              onAvatarTap: isCurrentUser ? () => _pickAndUploadAvatar(usersProvider) : () {},
              onEditName: isCurrentUser ? (newName) => _saveNameInline(usersProvider, newName) : (s) async => null,
              onChangePassword: isCurrentUser ? () => _openPasswordDialog() : () {},
              isCurrentUser: isCurrentUser,
            ),
            const SizedBox(height: 16),

            // ── ZONA 2: Horario quiro (solo quiropractico) ────
            if (esQuiro) ...[
              _ProfileCard(
                title: isCurrentUser ? 'Mi horario de trabajo' : 'Horario de trabajo de ${user.nombreCompleto}',
                icon: Icons.schedule_rounded,
                children: [
                  if (horariosQuiro.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No tienes horarios configurados. Ve a Configuración → Horarios.',
                        style: TextStyle(fontSize: 13, color: _kTextSub),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final groupedRow = <int, List<String>>{};
                        for (var h in horariosQuiro) {
                          groupedRow.putIfAbsent(h.diaSemana, () => []).add(h.formattedRange);
                        }
                        final entries = groupedRow.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
                        
                        return Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                          },
                          children: entries.map((entry) {
                            const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
                            final rangesJoined = entry.value.join(' | ');
                            return TableRow(children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  dias[entry.key.clamp(1, 7)],
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMain),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  rangesJoined,
                                  style: const TextStyle(fontSize: 13, color: _kTextSub),
                                ),
                              ),
                            ]);
                          }).toList(),
                        );
                      }
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: _kBorder, height: 1),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        CustomSnackBar.show(context, message: 'Función de solicitar bloqueo de agenda manual próximamente.', type: SnackBarType.info);
                      },
                      icon: const Icon(Icons.do_not_disturb_on_rounded, size: 16),
                      label: const Text('Solicitar Bloqueo de Agenda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (isCurrentUser) ...[
            // ── ZONA 4: Seguridad y Preferencias ──────────────────────────
            _ProfileCard(
              title: 'Seguridad y Privacidad',
              icon: Icons.security_rounded,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Contraseña de acceso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMain)),
                        SizedBox(height: 2),
                        Text('Último cambio hace más de 30 días', style: TextStyle(fontSize: 11, color: _kTextSub)),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => _openPasswordDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Actualizar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ProfileCard(
              title: 'Preferencias de Interfaz',
              icon: Icons.tune_rounded,
              children: [
                const Text(
                  'Vista por defecto de la agenda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMain),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'day', label: Text('Diaria'), icon: Icon(Icons.today, size: 16)),
                    ButtonSegment(value: 'week', label: Text('Semanal'), icon: Icon(Icons.view_week, size: 16)),
                    ButtonSegment(value: 'month', label: Text('Mensual'), icon: Icon(Icons.calendar_month, size: 16)),
                  ],
                  selected: {_defaultView},
                  onSelectionChanged: (sel) async {
                    final v = sel.first;
                    setState(() => _defaultView = v);
                    await LocalStorage.saveDefaultAgendaView(v);
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: _kBorder, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Notificaciones del navegador',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMain),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Recibe avisos aunque la pestaña esté en segundo plano',
                          style: TextStyle(fontSize: 11, color: _kTextSub),
                        ),
                      ],
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            ], // fin de isCurrentUser
          ],
        ),
      ),
    );
  }

  // ─── Acciones ────────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar(UsersProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, 
    );
    if (result != null && result.files.isNotEmpty) {
      var file = result.files.first;
      PlatformFile? currentFile = file;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirmar nueva foto de perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: MemoryImage(currentFile!.bytes!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 15,
                        bottom: 15,
                        child: Material(
                          color: AppTheme.primaryColor,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: () async {
                              final newResult = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (newResult != null && newResult.files.isNotEmpty) {
                                setStateDialog(() {
                                  currentFile = newResult.files.first;
                                });
                              }
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.edit, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('¿Estás seguro de que deseas utilizar esta imagen?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          }
        )
      );

      if (confirm == true && currentFile != null) {
        file = currentFile!;
        final err = await provider.uploadProfilePicture(file);
        if (!mounted) return;
        if (err != null) {
          CustomSnackBar.show(context, message: err, type: SnackBarType.error);
        } else {
          CustomSnackBar.show(context, message: 'Foto de perfil actualizada correctamente');
        }
      }
    }
  }

  Future<String?> _saveNameInline(UsersProvider provider, String newName) async {
    if (newName.isEmpty) return 'El nombre no puede estar vacío';
    final err = await provider.updateMyProfile(newName);
    if (!mounted) return err;
    if (err != null) {
      CustomSnackBar.show(context, message: err, type: SnackBarType.error);
    } else {
      CustomSnackBar.show(context, message: 'Nombre actualizado');
    }
    return err;
  }

  // _openEditNameDialog ha sido reemplazado por edición in-line

  void _openPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CambiarPasswordDialog(
        provider: Provider.of<UsersProvider>(context, listen: false),
      ),
    );
  }
}

// ─── Botón atrás ──────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/agenda');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _kTextMain),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  final dynamic user;
  final int profilePictureVersion;
  final VoidCallback onAvatarTap;
  final Future<String?> Function(String) onEditName;
  final VoidCallback onChangePassword;
  final bool isCurrentUser;

  const _HeroCard({
    required this.user,
    required this.profilePictureVersion,
    required this.onAvatarTap,
    required this.onEditName,
    required this.onChangePassword,
    this.isCurrentUser = true,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameNode = FocusNode();
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.nombreCompleto ?? '';
  }

  @override
  void didUpdateWidget(covariant _HeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName && oldWidget.user != widget.user) {
      _nameController.text = widget.user?.nombreCompleto ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameNode.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.user?.nombreCompleto) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isSavingName = true);
    final error = await widget.onEditName(newName);
    
    if (mounted) {
      setState(() {
        _isSavingName = false;
        if (error == null) {
          _isEditingName = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = "U";
    if (widget.user != null && widget.user.nombreCompleto.isNotEmpty) {
      final parts = widget.user.nombreCompleto.trim().split(" ");
      if (parts.length > 1) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      } else {
        initials = parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
      }
    }

    final hasPhoto = widget.user?.tieneFotoPerfil == true;
    final photoUrl = '${ApiConfig.baseUrl}/usuarios/${widget.user?.idUsuario}/foto-perfil?v=${widget.profilePictureVersion}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              MouseRegion(
                cursor: widget.isCurrentUser ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: widget.isCurrentUser ? Tooltip(
                  message: 'Seleccionar imagen de perfil',
                  child: GestureDetector(
                    onTap: widget.isCurrentUser ? widget.onAvatarTap : null,
                    child: _buildAvatarStack(hasPhoto, photoUrl, initials, widget.isCurrentUser),
                  ),
                ) : _buildAvatarStack(hasPhoto, photoUrl, initials, widget.isCurrentUser),
              ),
              const SizedBox(width: 24),

              // Datos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _isEditingName 
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 400,
                                    child: TextFormField(
                                      controller: _nameController,
                                      focusNode: _nameNode,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kTextMain),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        border: UnderlineInputBorder(),
                                      ),
                                      onFieldSubmitted: (_) => _saveName(),
                                    ),
                                  ),
                                  if (_isSavingName)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  else ...[
                                    IconButton(
                                      icon: const Icon(Icons.check, color: AppTheme.primaryColor, size: 24),
                                      onPressed: _saveName,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.grey, size: 24),
                                      onPressed: () {
                                        setState(() {
                                          _nameController.text = widget.user?.nombreCompleto ?? '';
                                          _isEditingName = false;
                                        });
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                  ],
                                ],
                              )
                            : GestureDetector(
                                onDoubleTap: widget.isCurrentUser ? () {
                                  setState(() {
                                    _isEditingName = true;
                                  });
                                  Future.delayed(const Duration(milliseconds: 50), () => _nameNode.requestFocus());
                                } : null,
                                child: Text(
                                  widget.user?.nombreCompleto ?? 'Cargando...',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _kTextMain,
                                  ),
                                ),
                              ),
                        ),
                        if (!_isEditingName && widget.isCurrentUser)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isEditingName = true;
                              });
                              Future.delayed(const Duration(milliseconds: 50), () => _nameNode.requestFocus());
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 22, color: _kTextSub),
                            tooltip: 'Editar nombre',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _RolBadge(rol: widget.user?.rol ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      '@${widget.user?.username ?? '—'}',
                      style: const TextStyle(fontSize: 14, color: _kTextSub, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    if (widget.user?.ultimaConexion != null)
                      Row(children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: _kTextSub),
                        const SizedBox(width: 4),
                        Text(
                          _formatConexion(widget.user!.ultimaConexion!),
                          style: const TextStyle(fontSize: 12, color: _kTextSub),
                        ),
                      ]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatConexion(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Último acceso hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Último acceso hace ${diff.inHours}h';
    return 'Último acceso ${DateFormat('dd/MM/yyyy').format(dt)}';
  }

  Widget _buildAvatarStack(bool hasPhoto, String photoUrl, String initials, bool isCurrentUser) {
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 3),
            image: hasPhoto ? DecorationImage(
              image: NetworkImage(photoUrl, headers: {
                'Authorization': 'Bearer ${LocalStorage.getToken()}'
              }),
              fit: BoxFit.cover,
            ) : null,
          ),
          child: !hasPhoto ? Center(
            child: Text(initials, style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ) : null,
        ),
        if (isCurrentUser)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: Icon(Icons.photo_camera_rounded, size: 16, color: AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }
}

// ─── Rol Badge ────────────────────────────────────────────────

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    switch (rol.toLowerCase().replaceAll('á', 'a')) {
      case 'admin':
        c = Colors.purple;
        label = 'Administrador';
        break;
      case 'quiropractico':
        c = AppTheme.primaryColor;
        label = 'Quiropráctico';
        break;
      default:
        c = Colors.teal;
        label = 'Recepción';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ─── Profile Card base ────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ProfileCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.primaryColor,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─── Cambiar Contraseña Dialog ────────────────────────────────

class _CambiarPasswordDialog extends StatefulWidget {
  final UsersProvider provider;
  const _CambiarPasswordDialog({required this.provider});

  @override
  State<_CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _visible = false;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _PasswordField(ctrl: _currentCtrl, label: 'Contraseña actual', visible: _visible, onToggle: _toggle),
            const SizedBox(height: 12),
            _PasswordField(
              ctrl: _newCtrl,
              label: 'Nueva contraseña',
              visible: _visible,
              onToggle: _toggle,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              ctrl: _confirmCtrl,
              label: 'Confirmar contraseña',
              visible: _visible,
              onToggle: _toggle,
              validator: (v) => v != _newCtrl.text ? 'No coinciden' : null,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Actualizar'),
        ),
      ],
    );
  }

  void _toggle() => setState(() => _visible = !_visible);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await widget.provider.updateMyPassword(_currentCtrl.text, _newCtrl.text);
    if (!mounted) return;
    final ctx = NavigationService.navigatorKey.currentContext ?? context;
    Navigator.pop(context);
    if (err != null) {
      final msg = err == 'CONTRASEÑA_ACTUAL_INCORRECTA' ? 'La contraseña actual no es válida' : err;
      CustomSnackBar.show(ctx, message: msg, type: SnackBarType.error);
    } else {
      CustomSnackBar.show(ctx, message: 'Contraseña actualizada correctamente');
    }
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  const _PasswordField({required this.ctrl, required this.label, required this.visible, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 18),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        isDense: true,
      ),
    );
  }
}
