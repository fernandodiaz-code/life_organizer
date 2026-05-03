import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tarea.dart';

class TareasService {
  static final _db = Supabase.instance.client;

  static Future<List<Tarea>> fetchAll() async {
    final data = await _db
        .from('tareas')
        .select()
        .order('prioridad', ascending: false)
        .order('deadline');
    return (data as List).map((j) => Tarea.fromJson(j)).toList();
  }

  static Future<List<Tarea>> fetchPendientes({int limit = 5}) async {
    final data = await _db
        .from('tareas')
        .select()
        .neq('estado', 'completada')
        .order('prioridad', ascending: false)
        .limit(limit);
    return (data as List).map((j) => Tarea.fromJson(j)).toList();
  }

  static Future<Tarea> crear(Tarea tarea) async {
    final data = await _db
        .from('tareas')
        .insert({
          ...tarea.toInsertJson(),
          'user_id': _db.auth.currentUser!.id,
        })
        .select()
        .single();
    return Tarea.fromJson(data);
  }

  static Future<void> completar(String id) async {
    await _db.from('tareas').update({
      'estado': 'completada',
      'completada_en': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> eliminar(String id) async {
    await _db.from('tareas').delete().eq('id', id);
  }

  static Future<void> actualizarEstado(String id, String estado) async {
    await _db.from('tareas').update({'estado': estado}).eq('id', id);
  }
}
