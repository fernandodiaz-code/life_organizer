import 'package:flutter/material.dart';
import '../core/theme.dart';

class HorarioItem {
  final String id;
  final String dia;       // weekday ("lunes") — siempre presente
  final String horaInicio;
  final String horaFin;
  final String materia;   // nombre de clase o actividad
  final String tipo;
  final String? lugar;
  final DateTime? fecha;  // null = recurrente semanal | set = evento puntual

  const HorarioItem({
    required this.id,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.materia,
    required this.tipo,
    this.lugar,
    this.fecha,
  });

  bool get esPuntual => fecha != null;

  HorarioItem copyWith({
    String? id,
    String? dia,
    String? horaInicio,
    String? horaFin,
    String? materia,
    String? tipo,
    String? lugar,
    DateTime? fecha,
  }) =>
      HorarioItem(
        id: id ?? this.id,
        dia: dia ?? this.dia,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        materia: materia ?? this.materia,
        tipo: tipo ?? this.tipo,
        lugar: lugar ?? this.lugar,
        fecha: fecha ?? this.fecha,
      );

  Color get tipoColor {
    switch (tipo.toLowerCase()) {
      case 'laboratorio':
        return AppColors.purple;
      case 'taller':
        return AppColors.orange;
      case 'examen':
        return AppColors.red;
      case 'estudio':
        return AppColors.green;
      case 'trabajo':
        return AppColors.orange;
      case 'personal':
        return AppColors.purple;
      default:
        return AppColors.cyan; // clase
    }
  }

  factory HorarioItem.fromJson(Map<String, dynamic> j) => HorarioItem(
        id: j['id'].toString(),
        dia: j['dia'] as String? ?? '',
        horaInicio: j['hora_inicio'] as String? ?? '',
        horaFin: j['hora_fin'] as String? ?? '',
        materia: j['materia'] as String? ?? '',
        tipo: j['tipo'] as String? ?? 'clase',
        lugar: j['lugar'] as String?,
        fecha: j['fecha'] != null
            ? DateTime.tryParse(j['fecha'] as String)
            : null,
      );
}
