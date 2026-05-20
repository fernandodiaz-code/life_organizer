import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/proyecto.dart';

class ProyectosService {
  static final _db = Supabase.instance.client;

  static Future<List<Proyecto>> fetchAll() async {
    final data = await _db
        .from('proyectos')
        .select()
        .order('fecha_inicio', ascending: false);
    return (data as List<dynamic>)
        .map((j) => Proyecto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Proyecto> crear(Proyecto proyecto) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw StateError('Usuario no autenticado');
    final data = await _db
        .from('proyectos')
        .insert({...proyecto.toInsertJson(), 'user_id': userId})
        .select()
        .single();
    return Proyecto.fromJson(data);
  }

  static Future<void> actualizarProgreso(String id, double progreso) async {
    await _db.from('proyectos').update({'progreso': progreso}).eq('id', id);
  }

  static Future<void> actualizarEstado(String id, String estado) async {
    await _db.from('proyectos').update({'estado': estado}).eq('id', id);
  }

  static Future<void> eliminar(String id) async {
    await _db.from('proyectos').delete().eq('id', id);
  }
}
