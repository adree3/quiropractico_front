class Historial {
  final int? idHistorial;
  final int idCita;
  final String? notasSubjetivo;
  final String? notasObjetivo;
  final String? ajustesRealizados;
  final String? planFuturo;

  Historial({this.idHistorial, required this.idCita, this.notasSubjetivo, this.notasObjetivo, this.ajustesRealizados, this.planFuturo});

  factory Historial.fromJson(Map<String, dynamic> json) {
    return Historial(
      idHistorial: json['idHistorial'],
      idCita: json['idCita'],
      notasSubjetivo: json['notasSubjetivo'],
      notasObjetivo: json['notasObjetivo'],
      ajustesRealizados: json['ajustesRealizados'],
      planFuturo: json['planFuturo'],
    );
  }
}