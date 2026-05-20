import 'package:flutter/material.dart';
import '../core/theme.dart';

class DeadlineItem {
  final String id;
  final String titulo;
  final String? materia;
  final DateTime fecha;
  final String tipo;
  final String estado;
  final String? proyectoId;

  const DeadlineItem({
    required this.id,
    required this.titulo,
    this.materia,
    required this.fecha,
    required this.tipo,
    required this.estado,
    this.proyectoId,
  });

  bool get isVencido => fecha.isBefore(DateTime.now());

  int get diasRestantes => fecha.difference(DateTime.now()).inDays;

  Color get urgenciaColor {
    if (isVencido) return AppColors.red;
    if (diasRestantes <= 2) return AppColors.orange;
    if (diasRestantes <= 7) return AppColors.cyan;
    return AppColors.green;
  }

  String get urgenciaLabel {
    if (isVencido) return 'Vencido';
    if (diasRestantes == 0) return 'Hoy';
    if (diasRestantes == 1) return 'Mañana';
    return 'En $diasRestantes días';
  }

  factory DeadlineItem.fromJson(Map<String, dynamic> j) => DeadlineItem(
        id: j['id'].toString(),
        titulo: j['titulo'] as String? ?? '',
        materia: j['materia'] as String?,
        fecha: DateTime.tryParse(j['fecha'] as String? ?? '') ?? DateTime.now(),
        tipo: j['tipo'] as String? ?? 'entrega',
        estado: j['estado'] as String? ?? 'pendiente',
        proyectoId: j['proyecto_id']?.toString(),
      );
}
