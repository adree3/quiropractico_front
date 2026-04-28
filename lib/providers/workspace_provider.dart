import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quiropractico_front/config/api_config.dart';
import 'package:quiropractico_front/models/clinica_search_result.dart';
import 'package:quiropractico_front/services/api_service.dart';

class WorkspaceProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;

  List<ClinicaSearchResult> _searchResults = [];
  List<ClinicaSearchResult> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  CancelToken? _cancelToken;

  Future<void> searchClinicas(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isLoading = false;
      _errorMessage = null;
      _hasSearched = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _hasSearched = true;
    notifyListeners();

    // Cancel previous request if any
    _cancelToken?.cancel('Cancelled by new search');
    _cancelToken = CancelToken();

    try {
      final response = await ApiService.dio.get(
        '$_baseUrl/public/clinicas/search',
        queryParameters: {'query': query.trim()},
        cancelToken: _cancelToken,
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('JSON recibido de la API (Búsqueda Clínicas): $data');
        _searchResults = data.map((e) => ClinicaSearchResult.fromJson(e)).toList();
      } else {
        _errorMessage = 'Error al buscar clínicas. Inténtalo de nuevo.';
        _searchResults = [];
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Ignorar errores de cancelación
        return;
      }
      _errorMessage = 'Error de conexión. Verifica tu red.';
      _searchResults = [];
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _searchResults = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isLoading = false;
    _errorMessage = null;
    _hasSearched = false;
    notifyListeners();
  }
}
