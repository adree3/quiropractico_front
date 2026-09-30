import 'package:flutter/material.dart';

/// **FinancialKpiCard**
///
/// Tarjeta de resumen financiero de nivel Enterprise diseñada bajo el estándar
/// Flat Desktop del proyecto.
///
/// Reglas de diseño y negocio:
/// - Estética Flat Desktop: Cero sombras exageradas. Borde sutil y sólido (`Colors.grey.shade300`).
/// - Sombra extremadamente tenue o nula para máxima limpieza visual.
/// - RBAC Integrado: Si `isGestor` es verdadero, se muestra el importe monetario
///   en gran tamaño con el número de operaciones en texto secundario. Si no es gestor,
///   se ocultan los importes monetarios y se resalta el conteo de registros.
class FinancialKpiCard extends StatelessWidget {
  /// Título contextual de la métrica (ej. "Cobrado (Hoy)" o "Ventas (Hoy)").
  final String title;

  /// Importe formateado con divisa (ej. "2.450,00 €"). Visible únicamente si [isGestor] es `true`.
  final String? importeText;

  /// Conteo o recuento de ventas/operaciones (ej. "14 ventas" o "14").
  final String countText;

  /// Etiqueta explicativa secundaria cuando se ocultan las finanzas para usuarios estándar.
  final String? countLabel;

  /// Flag que determina si el usuario en sesión tiene permisos de visualización financiera.
  final bool isGestor;

  /// Color representativo de la métrica (ej. Verde para ingresos, Naranja para pendientes).
  final Color accentColor;

  /// Icono descriptivo del indicador.
  final IconData icon;

  const FinancialKpiCard({
    super.key,
    required this.title,
    this.importeText,
    required this.countText,
    this.countLabel,
    required this.isGestor,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        // Estética Flat Desktop: sombra extremadamente tenue para máxima sobriedad
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono representativo contenido en cápsula suave
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(width: 12),
          // Contenido con RBAC
          Expanded(
            child: isGestor
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        importeText ?? "0,00 €",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        countText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      if (countLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          countLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
