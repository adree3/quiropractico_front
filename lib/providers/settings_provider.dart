import 'package:flutter/material.dart';
import 'package:quiropractico_front/services/clinica_settings_service.dart';

/// Provider que gestiona el estado del módulo de Configuración de Clínica.
/// - Cargar los datos de configuración desde el backend (GET /api/clinicas/settings).
/// - Persistir los cambios del formulario (PUT /api/clinicas/settings).
/// - Exponer el estado de carga, guardado y errores a la capa de presentación.
class SettingsProvider extends ChangeNotifier {
  final ClinicaSettingsService _settingsService = ClinicaSettingsService();

  // Estado de UI
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  // Datos de la Clínica
  String nombre = '';
  String cifNif = '';
  String telefono = '';
  String emailContacto = '';
  String direccion = '';
  int duracionCitaMinutos = 30;
  int limiteAlmacenamientoBytes = 5368709120;
  int almacenamientoUsadoBytes = 0;

  SettingsProvider() {
    loadSettings();
  }

  // Carga inicial
  Future<void> loadSettings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _settingsService.getSettings();
      nombre = data['nombre'] ?? '';
      cifNif = data['cifNif'] ?? '';
      telefono = data['telefono'] ?? '';
      emailContacto = data['emailContacto'] ?? '';
      direccion = data['direccion'] ?? '';
      duracionCitaMinutos = data['duracionCitaMinutos'] ?? 30;
      limiteAlmacenamientoBytes = data['limiteAlmacenamientoBytes'] ?? 5368709120;
      almacenamientoUsadoBytes = data['almacenamientoUsadoBytes'] ?? 0;
    } catch (e) {
      errorMessage = 'Error al cargar la configuración de la clínica';
    }

    isLoading = false;
    notifyListeners();
  }

  // Persistencia
  Future<bool> saveSettings() async {
    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _settingsService.updateSettings({
        'nombre': nombre,
        'cifNif': cifNif,
        'telefono': telefono,
        'emailContacto': emailContacto,
        'direccion': direccion,
        'duracionCitaMinutos': duracionCitaMinutos,
      });

      successMessage = 'Configuración guardada correctamente';
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error al guardar la configuración';
    }

    isSaving = false;
    notifyListeners();
    return false;
  }

  // Helpers
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
