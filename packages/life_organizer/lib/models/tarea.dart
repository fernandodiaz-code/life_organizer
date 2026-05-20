import 'package:flutter/material.dart';
import '../core/theme.dart';

class Tarea {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? materia;
  final int prioridad; // 1=baja, 2=media, 3=alta
  final String estado; // pendiente | en_progreso | completada
  final DateTime? deadline;
  final DateTime? completadaEn;

  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.materia,
    required this.prioridad,
    required this.estado,
    this.deadline,
    this.completadaEn,
  });

  bool get isCompleted => estado == 'completada';

  Color get priorityColor {
    switch (prioridad) {
      case 3:
        return AppColors.red;
      case 2:
        return AppColors.orange;
      default:
        return AppColors.green;
    }
  }

  String get priorityLabel {
    switch (prioridad) {
      case 3:
        return 'Alta';
      case 2:
        return 'Media';
      default:
        return 'Baja';
    }
  }

  factory Tarea.fromJson(Map<String, dynamic> j) => Tarea(
        id: j['id'].toString(),
        titulo: j['titulo']?.toString() ?? '',
        descripcion: j['descripcion']?.toString(),
        materia: j['materia']?.toString(),
        prioridad: _parseInt(j['prioridad']) ?? 1,
        estado: j['estado']?.toString() ?? 'pendiente',
        deadline: j['deadline'] != null
            ? DateTime.tryParse(j['deadline'].toString())
            : null,
        completadaEn: j['completada_en'] != null
            ? DateTime.tryParse(j['completada_en'].toString())
            : null,
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toInsertJson() => {
        'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        if (materia != null) 'materia': materia,
        'prioridad': prioridad,
        'estado': estado,
        if (deadline != null) 'deadline': deadline!.toIso8601String(),
      };

  Tarea copyWith({String? estado, DateTime? completadaEn}) => Tarea(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        materia: materia,
        prioridad: prioridad,
        estado: estado ?? this.estado,
        deadline: deadline,
        completadaEn: completadaEn ?? this.completadaEn,
      );
}
