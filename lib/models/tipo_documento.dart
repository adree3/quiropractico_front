import 'package:flutter/material.dart';

enum TipoDocumento {
  pruebaMedica(
    codigo: 'PRUEBA_MEDICA',
    nombreLegible: 'Prueba Médica',
    icono: Icons.image_rounded,
    color: Colors.purple,
  ),
  justificanteAsistencia(
    codigo: 'JUSTIFICANTE_ASISTENCIA',
    nombreLegible: 'Cita Firmada / Asistencia',
    icono: Icons.draw_rounded,
    color: Colors.teal,
  ),
  consentimientoLopd(
    codigo: 'CONSENTIMIENTO_LOPD',
    nombreLegible: 'Consentimiento LOPD',
    icono: Icons.gavel_rounded,
    color: Colors.orange,
  ),
  consentimientoTratamiento(
    codigo: 'CONSENTIMIENTO_TRATAMIENTO',
    nombreLegible: 'Consentimiento de Tratamiento',
    icono: Icons.health_and_safety_rounded,
    color: Colors.deepOrange,
  ),
  informeMedico(
    codigo: 'INFORME_MEDICO',
    nombreLegible: 'Informe Clínico',
    icono: Icons.medical_information_rounded,
    color: Colors.blue,
  ),
  facturacion(
    codigo: 'FACTURACION',
    nombreLegible: 'Facturación / Pago',
    icono: Icons.euro_rounded,
    color: Colors.green,
  ),
  otro(
    codigo: 'OTRO',
    nombreLegible: 'Otros Archivos',
    icono: Icons.folder_copy_rounded,
    color: Colors.blueGrey,
  );

  final String codigo;
  final String nombreLegible;
  final IconData icono;
  final Color color;

  const TipoDocumento({
    required this.codigo,
    required this.nombreLegible,
    required this.icono,
    required this.color,
  });

  static TipoDocumento fromString(String? value) {
    if (value == null || value.trim().isEmpty) return TipoDocumento.otro;
    final normalized = value.trim().toUpperCase();

    switch (normalized) {
      case 'PRUEBA_MEDICA':
      case 'PRUEBAMEDICA':
      case 'RADIOGRAFIA':
      case 'RESONANCIA':
      case 'IMAGEN_MEDICA':
        return TipoDocumento.pruebaMedica;

      case 'JUSTIFICANTE_ASISTENCIA':
      case 'JUSTIFICANTEASISTENCIA':
      case 'FIRMA':
      case 'FIRMAS':
        return TipoDocumento.justificanteAsistencia;

      case 'CONSENTIMIENTO_LOPD':
      case 'CONSENTIMIENTOLOPD':
      case 'LOPD':
        return TipoDocumento.consentimientoLopd;

      case 'CONSENTIMIENTO_TRATAMIENTO':
      case 'CONSENTIMIENTOTRATAMIENTO':
      case 'TRATAMIENTO':
        return TipoDocumento.consentimientoTratamiento;

      case 'INFORME_MEDICO':
      case 'INFORMEMEDICO':
      case 'INFORME':
        return TipoDocumento.informeMedico;

      case 'FACTURACION':
      case 'FACTURA':
      case 'JUSTIFICANTE_PAGO':
      case 'JUSTIFICANTEPAGO':
      case 'PAGO':
        return TipoDocumento.facturacion;

      case 'OTRO':
      default:
        return TipoDocumento.otro;
    }
  }
}
