import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/ui/widgets/skeleton_loader.dart';

class PaginatedTable extends StatefulWidget {
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final int totalElements;
  final int pageSize;
  final int currentPage;
  final Function(int) onPageChanged;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double? dataRowHeight;

  // Parámetros opcionales para personalización estética
  final double rowSpacing;
  final double hoverElevation;
  final bool enableSmoothTransitions;

  const PaginatedTable({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.emptyMessage,
    required this.totalElements,
    required this.pageSize,
    required this.currentPage,
    required this.onPageChanged,
    required this.columns,
    required this.rows,
    this.dataRowHeight,
    this.rowSpacing = 0.0,
    this.hoverElevation = 0.0,
    this.enableSmoothTransitions = true,
  });

  @override
  State<PaginatedTable> createState() => _PaginatedTableState();
}

class _PaginatedTableState extends State<PaginatedTable> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPagination = widget.totalElements > widget.pageSize;
    final int totalPages = (widget.totalElements / widget.pageSize).ceil();

    final int startRecord = (widget.currentPage * widget.pageSize) + 1;
    final int endRecord = min(
      (widget.currentPage + 1) * widget.pageSize,
      widget.totalElements,
    );
    final double defaultHeight = widget.pageSize > 10 ? 57.5 : 55.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Column(
              children: [
                // TABLA
                Expanded(
                  child:
                      widget.isEmpty && !widget.isLoading
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.emptyMessage,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                          : widget.isLoading && widget.rows.isEmpty
                          ? const SkeletonLoader(rowCount: 6)
                          : Stack(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return ScrollbarTheme(
                                    data: ScrollbarThemeData(
                                      // Barra fina y discreta
                                      thickness: WidgetStateProperty.all(3),
                                      radius: const Radius.circular(4),
                                      thumbColor: WidgetStateProperty.all(
                                        Colors.grey.withOpacity(0.35),
                                      ),
                                      trackColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                      trackBorderColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                      thumbVisibility: WidgetStateProperty.all(
                                        true,
                                      ),
                                    ),
                                    child: Scrollbar(
                                      controller: _hScroll,
                                      child: SingleChildScrollView(
                                        controller: _hScroll,
                                        scrollDirection: Axis.horizontal,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
                                            ),
                                            child: DataTable(
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    const Color(0xFF00AEEF),
                                                  ),
                                              dataRowMinHeight:
                                                  (widget.dataRowHeight ??
                                                      defaultHeight) +
                                                  widget.rowSpacing,
                                              dataRowMaxHeight:
                                                  (widget.dataRowHeight ??
                                                      defaultHeight) +
                                                  widget.rowSpacing,
                                              showCheckboxColumn: false,
                                              columns: widget.columns,
                                              rows: widget.rows,
                                              border: TableBorder(
                                                horizontalInside: BorderSide(
                                                  color:
                                                      widget.rowSpacing > 0
                                                          ? Colors.transparent
                                                          : Colors
                                                              .grey
                                                              .shade200,
                                                  width: 0.5,
                                                ),
                                                bottom: const BorderSide(
                                                  color: Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (widget.isLoading && widget.rows.isNotEmpty)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              if (widget.isLoading && widget.rows.isNotEmpty)
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(minHeight: 3),
                                ),
                            ],
                          ),
                ),

                // PAGINACIÓN
                if (showPagination && !widget.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Mostrando $startRecord - $endRecord de ${widget.totalElements} registros",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        IgnorePointer(
                          ignoring: widget.isLoading,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed:
                                    widget.currentPage > 0
                                        ? () => widget.onPageChanged(
                                          widget.currentPage - 1,
                                        )
                                        : null,
                                padding: EdgeInsets.zero,
                                tooltip: "Anterior",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  "Página ${widget.currentPage + 1} de $totalPages",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed:
                                    widget.currentPage < totalPages - 1
                                        ? () => widget.onPageChanged(
                                          widget.currentPage + 1,
                                        )
                                        : null,
                                padding: EdgeInsets.zero,
                                tooltip: "Siguiente",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
