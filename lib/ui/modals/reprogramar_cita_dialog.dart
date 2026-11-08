import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiropractico_front/config/theme/app_theme.dart';
import 'package:quiropractico_front/models/cita.dart';
import 'package:quiropractico_front/models/usuario.dart';
import 'package:quiropractico_front/providers/agenda_provider.dart';
import 'package:quiropractico_front/ui/widgets/user_avatar_widget.dart';

class ReprogramarCitaDialog extends StatefulWidget {
  final Cita cita;
  final DateTime fechaDestino;
  final AgendaProvider agendaProvider;
  final void Function(Usuario doctor)? onDoctorSelected;

  const ReprogramarCitaDialog({
    super.key,
    required this.cita,
    required this.fechaDestino,
    required this.agendaProvider,
    this.onDoctorSelected,
  });

  @override
  State<ReprogramarCitaDialog> createState() => _ReprogramarCitaDialogState();
}

class _ReprogramarCitaDialogState extends State<ReprogramarCitaDialog> {
  Usuario? _selectedQuiro;
  Map<String, String>? _selectedHueco;
  late int _duracionMinutos;

  @override
  void initState() {
    super.initState();
    _duracionMinutos = widget.cita.fechaHoraFin
        .difference(widget.cita.fechaHoraInicio)
        .inMinutes;
    if (_duracionMinutos <= 0) _duracionMinutos = 30;

    // Buscar doctor de la cita o asignar el primero disponible
    try {
      _selectedQuiro = widget.agendaProvider.quiropracticos.firstWhere(
        (u) => u.idUsuario == widget.cita.idQuiropractico,
      );
    } catch (_) {
      if (widget.agendaProvider.quiropracticos.isNotEmpty) {
        _selectedQuiro = widget.agendaProvider.quiropracticos.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarHuecos();
    });
  }

  void _cargarHuecos() {
    if (_selectedQuiro != null) {
      widget.agendaProvider.cargarHuecos(
        _selectedQuiro!.idUsuario,
        widget.fechaDestino,
        duracionMinutos: _duracionMinutos,
        idCitaExcluir: widget.cita.idCita,
      );
    }
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;
    final fechaDestino = widget.fechaDestino;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── CABECERA ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_calendar_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reprogramar Cita',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cita.nombreClienteCompleto,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context, null),
                    visualDensity: VisualDensity.compact,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),

            // ── COMPARATIVA VISUAL DE FECHAS ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  // Bloque Fecha Original
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history, size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Fecha original',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _capitalizar(
                              DateFormat('E, d MMM yyyy • HH:mm', 'es_ES').format(cita.fechaHoraInicio),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppTheme.primaryColor),
                  ),
                  // Bloque Fecha Destino (Destacado)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.event_available, size: 13, color: AppTheme.primaryColor),
                              SizedBox(width: 4),
                              Text(
                                'Nueva fecha destino',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _capitalizar(
                              DateFormat("E, d 'de' MMMM", 'es_ES').format(fechaDestino),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // ── SELECTOR MÉDICO ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: DropdownButtonFormField<Usuario>(
                value: _selectedQuiro,
                decoration: const InputDecoration(
                  labelText: 'Quiropráctico',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: 280,
                items: widget.agendaProvider.quiropracticos.map((u) {
                  return DropdownMenuItem<Usuario>(
                    value: u,
                    child: Row(
                      children: [
                        UserAvatarWidget(
                          usuario: u,
                          radius: 12,
                          fontSize: 10,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          u.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedQuiro) {
                    setState(() {
                      _selectedQuiro = val;
                      _selectedHueco = null;
                    });
                    widget.onDoctorSelected?.call(val);
                    _cargarHuecos();
                  }
                },
              ),
            ),

            // ── CUADRÍCULA DE HUECOS (INLINE) ──────────────────────────────
            Consumer<AgendaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingHuecos) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }

                final huecos = provider.huecosDisponibles;
                if (huecos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No hay huecos disponibles para esta fecha con este quiropráctico.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Horas disponibles (${huecos.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: huecos.map((hueco) {
                            final bool isSelected = _selectedHueco == hueco;
                            final texto = hueco['texto'] ?? '';
                            final horaCorta = texto.split('–').first.trim();

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedHueco = hueco;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 98,
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.primaryColor.withValues(alpha: 0.25),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    horaCorta,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),

            // ── BOTONES DE ACCIÓN ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedHueco == null
                        ? null
                        : () {
                            final parts = _selectedHueco!['horaInicio']!.split(':');
                            final int hour = int.parse(parts[0]);
                            final int minute = int.parse(parts[1]);
                            final fechaConfirmada = DateTime(
                              fechaDestino.year,
                              fechaDestino.month,
                              fechaDestino.day,
                              hour,
                              minute,
                            );
                            if (widget.onDoctorSelected != null && _selectedQuiro != null) {
                              widget.onDoctorSelected!(_selectedQuiro!);
                            }
                            Navigator.pop(context, fechaConfirmada);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

