import 'package:flutter/material.dart';

class UiProvider extends ChangeNotifier {
  // Estado para el drawer de KPIs en Citas
  bool _isCitasSidePanelCollapsed = false;

  // Estado para el drawer de KPIs/Herramientas en Agenda
  bool _isAgendaSidePanelCollapsed = true;

  bool get isCitasSidePanelCollapsed => _isCitasSidePanelCollapsed;

  set isCitasSidePanelCollapsed(bool value) {
    _isCitasSidePanelCollapsed = value;
    notifyListeners();
  }

  bool get isAgendaSidePanelCollapsed => _isAgendaSidePanelCollapsed;

  set isAgendaSidePanelCollapsed(bool value) {
    _isAgendaSidePanelCollapsed = value;
    notifyListeners();
  }

  void toggleCitasSidePanel() {
    _isCitasSidePanelCollapsed = !_isCitasSidePanelCollapsed;
    notifyListeners();
  }

  void toggleAgendaSidePanel() {
    _isAgendaSidePanelCollapsed = !_isAgendaSidePanelCollapsed;
    notifyListeners();
  }
}
