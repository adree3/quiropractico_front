# Reglas de Arquitectura Frontend - Flutter Desktop (Quiropráctico)

1. **Estética Flat Desktop Obligatoria**
   - Fondo de contenedores principales y áreas de trabajo: `#F8FAFC` (`Color(0xFFF8FAFC)`).
   - Tarjetas (`Card` / `Container`): `elevation: 0`, fondo `Colors.white`, borde `Colors.grey.shade200` y `Left Accent Border` de 4px según estado semántico. Prohibido usar sombras pesadas o `FloatingActionButton` flotantes si la acción pertenece al Header.

2. **Reactividad Silenciosa (Cero Parpadeos)**
   - Tras crear, editar, cobrar o cancelar en un modal, PROHIBIDO recargar toda la vista con Shimmers destructivos (`loadFullData`). Usa siempre métodos granulares con `silent: true` (`refreshCitas(silent: true)`, `refreshBonos(silent: true)`, `refreshCliente(silent: true)`).

3. **Roles Oficiales del Backend**
   - Los únicos valores válidos de `rol` en el JSON de la API son: `'super_admin'`, `'admin'`, `'doctor'`, `'recepcion'` (en minúsculas y sin tildes).

4. **Verificación**
   - Ejecuta siempre `dart analyze` tras cualquier modificación antes de dar por cerrada una tarea.
