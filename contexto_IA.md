# Context Snapshot - Proyecto SaaS Clínica Quiropráctica

## 1. Contexto del Proyecto
* **Dominio:** SaaS Desktop diseñado para la digitalización y gestión de una clínica quiropráctica.
* **Stack Tecnológico:** 
  * **Frontend:** Flutter Desktop.
  * **Backend:** Java + Spring Boot.
  * **Base de Datos:** MySQL.

## 2. Estándares de UI/UX (Frontend - Flutter)
* **Arquitectura `PremiumDataTable`:**
  * Arquitectura PremiumDataTable y Celdas:
  * **Uso de Expanded en la raíz de cada celda para respetar los ratios matemáticos (columnFlexes).
  * **REGLA DE ORO INTERNA: Dentro de la celda, para textos que van acompañados de Chips o Iconos en fila (Row), usar SIEMPRE Flexible (con maxLines: 1 y TextOverflow.ellipsis) en lugar de Expanded. Esto garantiza que el texto se trunque si es largo, pero no obligue a empujar a los Chips al extremo derecho si el texto es corto.
  * **Cabeceras inmortales:** Fijas y separadas del scroll de contenido, garantizando que el usuario nunca pierda el contexto de las columnas.
  * **Skeletons (Shimmer):** Uso obligatorio de estados de carga tipo esqueleto para prevenir Layout Shifts, manteniendo la estructura general de la tabla durante llamadas asíncronas.
  * **Paginación Híbrida/Delegada:** Soporte para paginación clásica (controles en `bottomContent`). Se favorece la paginación servida desde el backend enviando `page`/`size`, con fallback de slicing local en caso de persistir listados planos antiguos.

* **Diseño Visual de Filas y Jerarquías:**
  * **PROHIBICIÓN ESTRICTA:** No está permitido colorear el fondo completo de la fila (`rowColor`). El fondo base debe mantenerse blanco/transparente. Únicamente se permite la retroalimentación al pasar el cursor (`hoverColor` sutil del `InkWell`).
  * **Patrón 'Left Accent Border':** Todo contenedor raíz dentro del padding del `InkWell` debe llevar un borde izquierdo de 4px de grosor (`BorderSide(width: 4.0)`). 
    * Este borde cromático indica jerarquías y tipos (ej. Usuarios: Admin = `Colors.purple.shade400`, Quiropráctico = `Colors.blue.shade400`. Servicios: Bono = `Colors.blue.shade400`, Sesión = `Colors.purple.shade400`).

* **Consistencia de Tamaños (Sizing & Typography):**
  * **Padding de Fila:** Obligatorio mantener el padding base estandarizado, usualmente `EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)` (calibrado en vertical para mantener alturas consistentes de ~64px por fila según la densidad del contenido).
  * **Fuentes:** 
    * Cabeceras: `fontSize: 16`, `fontWeight: FontWeight.w600`, color `Colors.blueGrey.shade800`. 
    * Celdas de datos: `fontSize: 15`. 
    * Identificadores (IDs): Familia tipográfica monospace y color gris.

* **Manejo de Tooltips y Estados (Bloqueo/Inactividad):**
  * **Tooltips:** Un Tooltip maestro envuelve la fila completa con `waitDuration: const Duration(milliseconds: 600)`. Los mini-tooltips anidados se permiten solo para tags ultra-específicos.
  * **Estados:** Registros inactivos o borrados lógicamente se renderizan atenuados (borde izquierdo gris, tipografía gris y decoración `TextDecoration.lineThrough`).
  * **Badges de Seguridad:** Las cuentas bloqueadas llevan un tag discreto ("Bloq.") estilizado con contenedor rojo tenue (`Colors.red.shade50`) y texto rojo fuerte (`Colors.red.shade700`).

## 3. Estándares de Arquitectura (Backend - Spring Boot)
* **Integridad de Capas y Mitigación N+1:**
  * **PROHIBICIÓN ESTRICTA:** Nunca devolver entidades JPA (`@Entity`) de forma cruda desde los Controladores (`@RestController`).
  * Obligatoriedad de mapeo usando objetos **DTO** (Data Transfer Objects).
  * Prevención proactiva del problema N+1 desde la capa Repository (fetching estratégico).

* **Estándar de Paginación:**
  * Uso normativo de la anotación `@PageableDefault` para la inyección de `Pageable` en la capa de Controladores.
  * Propagación de la interfaz `Pageable` intacta a lo largo del Servicio hasta el Repositorio JPA.
  * Uso de consultas JPQL paramétricas dinámicas (ej. `WHERE (:activo IS NULL OR s.activo = :activo)`) para delegar el filtrado exhaustivo y el `LIMIT`/`OFFSET` al motor de base de datos MySQL.

## 4. Estado Actual y Próximo Paso
* **Completado:** Consolidación arquitectónica UI/UX. Las tablas de Pacientes (`clients_view`), Usuarios (`users_view`) y Servicios (`services_view`) han sido exitosamente migradas al componente `PremiumDataTable`, estandarizadas visualmente y sincronizadas lógicamente con el backend.
* **Siguiente Objetivo Estratégico:** Iniciar el desarrollo/refactorización del módulo de **Calendario y Citas**, la vista de mayor fricción funcional, aplicando rigurosamente los estándares de estado, UI limpia y jerarquía visual definidos.

