import 'package:flutter/material.dart';
import '../core/theme.dart';

class Proyecto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String estado;
  final double progreso; // 0–100
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const Proyecto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.estado,
    required this.progreso,
    this.fechaInicio,
    this.fechaFin,
  });

  Color get estadoColor {
    switch (estado.toLowerCase()) {
      case 'completado':
        return AppColors.green;
      case 'pausado':
        return AppColors.orange;
      case 'cancelado':
        return AppColors.red;
      default:
        return AppColors.cyan;
    }
  }

  String get estadoLabel {
    switch (estado.toLowerCase()) {
      case 'completado':
        return 'Completado';
      case 'pausado':
        return 'Pausado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'En progreso';
    }
  }

  factory Proyecto.fromJson(Map<String, dynamic> j) => Proyecto(
        id: j['id'].toString(),
        nombre: j['nombre'] as String? ?? '',
        descripcion: j['descripcion'] as String?,
        estado: j['estado'] as String? ?? 'en_progreso',
        progreso: (j['progreso'] as num?)?.toDouble() ?? 0,
        fechaInicio: j['fecha_inicio'] != null
            ? DateTime.tryParse(j['fecha_inicio'] as String)
            : null,
        fechaFin: j['fecha_fin'] != null
            ? DateTime.tryParse(j['fecha_fin'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'estado': estado,
        'progreso': progreso,
        if (fechaInicio != null)
          'fecha_inicio': fechaInicio!.toIso8601String().split('T').first,
        if (fechaFin != null)
          'fecha_fin': fechaFin!.toIso8601String().split('T').first,
      };
}
