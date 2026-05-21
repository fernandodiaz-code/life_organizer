import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario.dart';

class HorarioService {
  // Este servicio aun usa Supabase directo. Es candidato natural para migrar a
  // Cloudflare cuando se cierre la arquitectura de credenciales.
  static final _db = Supabase.instance.client;
  static final _fmt = DateFormat('yyyy-MM-dd');

  static const _diasDb = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];

  // ── Fetch ───────────────────────────────────────────────────────────────

  /// Devuelve todos los ítems de la semana que empieza en [lunesDeSemana]:
  ///   - Recurrentes (fecha IS NULL): aparecen en su día de siempre.
  ///   - Puntuales (fecha IS NOT NULL): solo si la fecha cae en esa semana.
  static Future<Map<String, List<HorarioItem>>> fetchSemana({
    required DateTime lunesDeSemana,
  }) async {
    final domingo = lunesDeSemana.add(const Duration(days: 6));

    final data = await _db
        .from('horario')
        .select()
        .order('hora_inicio', ascending: true);

    final items = (data as List<dynamic>)
        .map((j) => HorarioItem.fromJson(j as Map<String, dynamic>))
        .toList();
    final Map<String, List<HorarioItem>> porDia = {};

    // Un item puede ser recurrente semanal o puntual por fecha. Por eso se
    // separan ambos casos antes de agrupar por dia.
    for (final item in items) {
      if (item.fecha != null) {
        // Evento puntual: solo mostrar si cae dentro de esta semana
        final f = DateTime(
          item.fecha!.year,
          item.fecha!.month,
          item.fecha!.day,
        );
        if (!f.isBefore(lunesDeSemana) && !f.isAfter(domingo)) {
          porDia.putIfAbsent(item.dia, () => []).add(item);
        }
      } else {
        // Recurrente semanal
        if (item.dia.isNotEmpty) {
          porDia.putIfAbsent(item.dia, () => []).add(item);
        }
      }
    }
    return porDia;
  }

  /// Para el Dashboard: clases + actividades de hoy.
  static Future<List<HorarioItem>> fetchHoy() async {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final diaActual = _diasDb[now.weekday - 1];

    final data = await _db
        .from('horario')
        .select()
        .order('hora_inicio', ascending: true);

    final items = (data as List<dynamic>)
        .map((j) => HorarioItem.fromJson(j as Map<String, dynamic>))
        .toList();

    return items.where((item) {
      if (item.fecha != null) {
        final f = DateTime(
          item.fecha!.year,
          item.fecha!.month,
          item.fecha!.day,
        );
        return f == hoy;
      }
      return item.dia == diaActual;
    }).toList();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  static Future<HorarioItem> crear(Map<String, dynamic> data) async {
    final res = await _db.from('horario').insert(data).select().single();
    return HorarioItem.fromJson(res);
  }

  static Future<void> actualizar(String id, Map<String, dynamic> data) async {
    await _db.from('horario').update(data).eq('id', id);
  }

  static Future<void> eliminar(String id) async {
    await _db.from('horario').delete().eq('id', id);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Convierte un DateTime en el nombre de día para Supabase ("martes").
  static String diaDesdeDate(DateTime date) => _diasDb[date.weekday - 1];

  /// Formatea una fecha para Supabase ("2026-04-28").
  static String formatFecha(DateTime date) => _fmt.format(date);
}
