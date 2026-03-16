import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/bono_historico.dart';
import 'package:quiropractico_front/services/api_service.dart';
import 'package:quiropractico_front/utils/error_handler.dart';

class BonosProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<BonoHistorico> bonos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;
  int pageSize = 15;
  int totalElements = 0;

  String? lastSearch;
  Timer? _debounce;

  Future<void> getHistorial({String? search, bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
      hasMore = true;
      bonos.clear();
      isLoading = true;
    } else {
      if (!hasMore || isLoadingMore) return;
      isLoadingMore = true;
    }
    
    notifyListeners();

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/bonos/historial',
        queryParameters: {
          'page': currentPage,
          'size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final data = response.data;
      final List<dynamic> content = data['content'];
      final totalPages = data['totalPages'];
      totalElements = data['totalElements'];

      final newItems = content.map((e) => BonoHistorico.fromJson(e)).toList();
      bonos.addAll(newItems);

      hasMore = (currentPage + 1) < totalPages;
      if (hasMore) currentPage++;

    } catch (e) {
      print('Error cargando historial de bonos: ${ErrorHandler.extractMessage(e)}');
    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      lastSearch = query;
      getHistorial(search: query, refresh: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
