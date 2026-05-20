import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deadline_item.dart';

class DeadlinesService {
  static final _db = Supabase.instance.client;

  static Future<List<DeadlineItem>> fetchProximos({int dias = 14}) async {
    final ahora = DateTime.now();
    final limite = ahora.add(Duration(days: dias));
    final data = await _db
        .from('deadlines')
        .select()
        .gte('fecha', ahora.toIso8601String().split('T').first)
        .lte('fecha', limite.toIso8601String().split('T').first)
        .neq('estado', 'completado')
        .order('fecha');
    return (data as List<dynamic>)
        .map((j) => DeadlineItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<List<DeadlineItem>> fetchAll() async {
    final data = await _db.from('deadlines').select().order('fecha');
    return (data as List<dynamic>)
        .map((j) => DeadlineItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
