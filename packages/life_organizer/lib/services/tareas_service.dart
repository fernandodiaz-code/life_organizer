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
    return (data as List<dynamic>)
        .map((j) => Tarea.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Tarea>> fetchPendientes({int limit = 5}) async {
    final data = await _db
        .from('tareas')
        .select()
        .neq('estado', 'completada')
        .order('prioridad', ascending: false)
        .limit(limit);
    return (data as List<dynamic>)
        .map((j) => Tarea.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Tarea> crear(Tarea tarea) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw StateError('Usuario no autenticado');
    final data = await _db
        .from('tareas')
        .insert({...tarea.toInsertJson(), 'user_id': userId})
        .select()
        .single();
    return Tarea.fromJson(data);
  }

  static Future<void> completar(String id) async {
    await _db
        .from('tareas')
        .update({
          'estado': 'completada',
          'completada_en': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> eliminar(String id) async {
    await _db.from('tareas').delete().eq('id', id);
  }

  static Future<void> actualizarEstado(String id, String estado) async {
    await _db.from('tareas').update({'estado': estado}).eq('id', id);
  }
}
