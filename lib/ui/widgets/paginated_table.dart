import 'dart:math';
import 'package:flutter/material.dart';

class PaginatedTable extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final bool showPagination = totalElements > pageSize;
    final int totalPages = (totalElements / pageSize).ceil();

    final int startRecord = (currentPage * pageSize) + 1;
    final int endRecord = min((currentPage + 1) * pageSize, totalElements);
    final double defaultHeight = pageSize > 10 ? 57.5 : 55.0;

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
                      isEmpty && !isLoading
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
                                  emptyMessage,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                          : SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
                              child: IgnorePointer(
                                ignoring: isLoading,
                                child: Opacity(
                                  opacity: isLoading ? 0.5 : 1.0,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      const Color(0xFF00AEEF),
                                    ),
                                    columnSpacing: 20,
                                    dataRowMinHeight:
                                        dataRowHeight ?? defaultHeight,
                                    dataRowMaxHeight:
                                        dataRowHeight ?? defaultHeight,
                                    columns: columns,
                                    rows: rows,
                                    border: const TableBorder(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                ),

                // PAGINACIÓN
                if (showPagination && !isEmpty)
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
                          "Mostrando $startRecord - $endRecord de $totalElements registros",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        IgnorePointer(
                          ignoring: isLoading,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed:
                                    currentPage > 0
                                        ? () => onPageChanged(currentPage - 1)
                                        : null,
                                padding: EdgeInsets.zero,
                                tooltip: "Anterior",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  "Página ${currentPage + 1} de $totalPages",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed:
                                    currentPage < totalPages - 1
                                        ? () => onPageChanged(currentPage + 1)
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

            // LOADING OVERLAY
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
