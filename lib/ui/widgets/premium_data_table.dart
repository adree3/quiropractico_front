import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// **PremiumDataTable**
/// 
/// Componente de tabla de datos de nivel Enterprise diseñado bajo el principio
/// de composición y arquitectura desacoplada.
/// 
/// Características Principales:
/// - **Cabeceras Inmortales:** Las columnas permanecen visibles durante la carga (`isLoading`).
/// - **Gestión de Estados Líquida:** Soporta Esqueleto Shimmer, Estado Vacío elegante y Lista de Datos.
/// - **Scroll Infinito Integrado:** Detección automática mediante [NotificationListener].
/// - **Flexibilidad Visual:** Slots desacoplados `topContent` y `bottomContent` para TabBars, buscadores o paginadores.
class PremiumDataTable<T> extends StatelessWidget {
  /// Colección de elementos a renderizar.
  final List<T> items;

  /// Builder principal para renderizar cada fila de la tabla a partir de un objeto tipo [T].
  final Widget Function(BuildContext context, T item, int index) rowBuilder;

  /// Cabeceras estáticas ("Inmortales") de la tabla.
  final List<Widget>? columnHeaders;

  /// Pesos de distribución flex correspondientes a cada columna/cabecera.
  final List<int>? columnFlexes;

  /// Estado de carga (true cuando se obtienen datos iniciales o más páginas).
  final bool isLoading;

  /// Indica si existen más registros en el servidor para disparar el scroll infinito.
  final bool hasMore;

  /// Umbral en píxeles previo al borde inferior para activar [onLoadMore].
  final double loadMoreThreshold;

  /// Callback ejecutado cuando el usuario hace scroll cerca del final de la lista.
  final VoidCallback? onLoadMore;

  /// Slot superior opcional (Buscadores, TabBars, Filtros, Acciones masivas).
  final Widget? topContent;

  /// Slot inferior opcional (Paginador clásico, barra de resumen, totales).
  final Widget? bottomContent;

  /// Builder para personalizar el widget visualizado cuando no existen registros.
  final WidgetBuilder? emptyStateBuilder;

  /// Cantidad de filas simuladas en el Skeleton loader durante la carga inicial.
  final int skeletonRowCount;

  /// Altura predeterminada de las filas del esqueleto.
  final double skeletonRowHeight;

  /// Separador personalizado entre filas (por defecto un divisor fino sutil).
  final IndexedWidgetBuilder? separatorBuilder;

  /// Padding horizontal y vertical aplicado a las celdas y cabeceras.
  final EdgeInsetsGeometry contentPadding;

  /// Si es `true`, la lista ajusta su tamaño al contenido. Si es `false`, se expande para llenar el espacio.
  final bool shrinkWrap;

  /// Física de desplazamiento para la lista interna.
  final ScrollPhysics? physics;

  /// Envolver opcionalmente la tabla en un contenedor con borde y sombra sutil enterprise.
  final bool wrapInCard;

  /// Controlador de scroll opcional para gestionar listeners externos o scroll infinito manual.
  final ScrollController? scrollController;

  const PremiumDataTable({
    super.key,
    required this.items,
    required this.rowBuilder,
    this.columnHeaders,
    this.columnFlexes,
    this.isLoading = false,
    this.hasMore = false,
    this.loadMoreThreshold = 200.0,
    this.onLoadMore,
    this.topContent,
    this.bottomContent,
    this.emptyStateBuilder,
    this.skeletonRowCount = 5,
    this.skeletonRowHeight = 52.0,
    this.separatorBuilder,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    this.shrinkWrap = false,
    this.physics,
    this.wrapInCard = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    Widget tableWidget = Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabeceras Inmortales (Persisten durante estados de carga)
        if (columnHeaders != null && columnHeaders!.isNotEmpty)
          _buildImmortalHeaders(context),

        // 2. El Cuerpo Principal (Esqueleto / Estado Vacío / Lista con Scroll Infinito)
        _buildBody(context),

        // 3. Slot Bottom Content (Paginador tradicional, totales o footer)
        if (bottomContent != null) bottomContent!,
      ],
    );

    if (wrapInCard) {
      tableWidget = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: tableWidget,
      );
    }

    if (topContent == null) {
      return tableWidget;
    }

    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        topContent!,
        const SizedBox(height: 24),
        shrinkWrap ? tableWidget : Expanded(child: tableWidget),
      ],
    );
  }

  /// Construye las cabeceras estáticas ("Inmortales") con estilo SaaS Enterprise.
  Widget _buildImmortalHeaders(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      padding: contentPadding,
      child: Row(
        children: List.generate(columnHeaders!.length, (index) {
          final flex = (columnFlexes != null && index < columnFlexes!.length)
              ? columnFlexes![index]
              : 1;

          return Expanded(
            flex: flex,
            child: columnHeaders![index],
          );
        }),
      ),
    );
  }

  /// Determina y renderiza el cuerpo según el estado de la aplicación.
  Widget _buildBody(BuildContext context) {
    Widget bodyWidget;

    // Estado 1: Carga Inicial (Skeleton Loader preservando estructura)
    if (isLoading && items.isEmpty) {
      bodyWidget = PremiumTableSkeleton(
        rowCount: skeletonRowCount,
        rowHeight: skeletonRowHeight,
        columnFlexes: columnFlexes,
        padding: contentPadding,
      );
    } 
    // Estado 2: Lista Vacía (No data)
    else if (!isLoading && items.isEmpty) {
      bodyWidget = emptyStateBuilder?.call(context) ?? _buildDefaultEmptyState(context);
    } 
    // Estado 3: Lista Poblada (Datos activos)
    else {
      bodyWidget = NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (hasMore && !isLoading && onLoadMore != null) {
            final maxScroll = scrollInfo.metrics.maxScrollExtent;
            final currentScroll = scrollInfo.metrics.pixels;
            if (maxScroll - currentScroll <= loadMoreThreshold) {
              onLoadMore!();
            }
          }
          return false;
        },
        child: ListView.separated(
          controller: scrollController,
          padding: EdgeInsets.zero,
          shrinkWrap: shrinkWrap,
          physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics()),
          itemCount: items.length + (hasMore && isLoading ? 1 : 0),
          separatorBuilder: separatorBuilder ??
              (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
          itemBuilder: (context, index) {
            // Render de items de la lista
            if (index < items.length) {
              return rowBuilder(context, items[index], index);
            }

            // Indicador de carga inferior para Infinite Scroll
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Si shrinkWrap es falso, expandimos el cuerpo dentro del Column principal
    if (!shrinkWrap) {
      return Expanded(child: bodyWidget);
    }

    return bodyWidget;
  }

  /// Estado vacío elegante por defecto con estética Enterprise.
  Widget _buildDefaultEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No se encontraron registros para mostrar en esta vista.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **PremiumTableSkeleton**
/// 
/// Renderiza filas de esqueleto con animación Shimmer fluidas respetando
/// la alineación flex de la tabla para prevenir bruscos parpadeos (Layout Shifts).
class PremiumTableSkeleton extends StatelessWidget {
  /// Cantidad de filas a simular en la vista previa.
  final int rowCount;

  /// Altura de cada bloque de fila cuando no se especifican flexes de columna.
  final double rowHeight;

  /// Pesos de flex para alinear los bloques Shimmer con las columnas reales.
  final List<int>? columnFlexes;

  /// Padding de cada fila skeleton alineado con la tabla original.
  final EdgeInsetsGeometry padding;

  const PremiumTableSkeleton({
    super.key,
    this.rowCount = 5,
    this.rowHeight = 52.0,
    this.columnFlexes,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rowCount,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade300,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          period: const Duration(milliseconds: 1200),
          child: Padding(
            padding: padding,
            child: (columnFlexes != null && columnFlexes!.isNotEmpty)
                ? Row(
                    children: List.generate(columnFlexes!.length, (colIndex) {
                      final flex = columnFlexes![colIndex];
                      return Expanded(
                        flex: flex,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 16.0,
                            margin: const EdgeInsets.only(right: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                : Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
