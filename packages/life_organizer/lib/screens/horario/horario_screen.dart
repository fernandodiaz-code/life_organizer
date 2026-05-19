import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/horario.dart';
import '../../services/horario_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});

  @override
  State<HorarioScreen> createState() => HorarioScreenState();
}

class HorarioScreenState extends State<HorarioScreen> {
  late String _diaSeleccionado;
  Map<String, List<HorarioItem>> _semana = {};
  bool _loading = true;
  int _weekOffset = 0; // 0 = esta semana, -1 = anterior, +1 = siguiente
  Timer? _ticker;
  RealtimeChannel? _realtimeChannel;

  // ── Derived ──────────────────────────────────────────────────────────────

  DateTime get _lunesDeSemana {
    final now = DateTime.now();
    final lunes = now.subtract(Duration(days: now.weekday - 1));
    final base = DateTime(lunes.year, lunes.month, lunes.day);
    return base.add(Duration(days: _weekOffset * 7));
  }

  List<HorarioItem> get _clasesDelDia {
    final list = List<HorarioItem>.from(_semana[_diaSeleccionado] ?? []);
    list.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    return list;
  }

  int get _diaIndex => AppConstants.diasDb.indexOf(_diaSeleccionado);

  DateTime get _fechaDia => _lunesDeSemana.add(Duration(days: _diaIndex));

  HorarioItem? get _enCurso {
    if (_weekOffset != 0) return null;
    if (_diaSeleccionado != AppConstants.diaDeHoyDb()) return null;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final item in _clasesDelDia) {
      if (nowMin >= _toMinutes(item.horaInicio) &&
          nowMin < _toMinutes(item.horaFin)) {
        return item;
      }
    }
    return null;
  }

  static int _toMinutes(String hora) {
    final p = hora.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = AppConstants.diaDeHoyDb();
    load();
    // Refresca el indicador "en curso" cada minuto
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    // Suscripción realtime: recarga cuando Jarvis guarda en la tabla horario
    _realtimeChannel = Supabase.instance.client
        .channel('horario_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'horario',
          callback: (_) {
            if (mounted) load();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      final data = await HorarioService.fetchSemana(
        lunesDeSemana: _lunesDeSemana,
      );
      if (mounted) setState(() => _semana = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar horario'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _showForm([HorarioItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ClaseForm(
        item: item,
        diaInicial: _diaSeleccionado,
        onSaved: load,
      ),
    );
  }

  Future<void> _confirmarEliminar(HorarioItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text('¿Eliminar "${item.materia}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await HorarioService.eliminar(item.id);
      setState(() => _semana[item.dia]?.removeWhere((x) => x.id == item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clase eliminada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _WeekHeader(
            semana: _semana,
            diaSeleccionado: _diaSeleccionado,
            weekOffset: _weekOffset,
            lunesDeSemana: _lunesDeSemana,
            onDiaSelected: (dia) => setState(() => _diaSeleccionado = dia),
            onRefresh: load,
            onWeekChanged: (delta) {
              setState(() => _weekOffset += delta);
              load();
            },
            onHoy: () {
              setState(() {
                _weekOffset = 0;
                _diaSeleccionado = AppConstants.diaDeHoyDb();
              });
              load();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan))
                : _TimelineView(
                    items: _clasesDelDia,
                    fechaDia: _fechaDia,
                    weekOffset: _weekOffset,
                    enCurso: _enCurso,
                    onEdit: _showForm,
                    onDelete: _confirmarEliminar,
                    onRefresh: load,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        tooltip: 'Nueva clase',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// B — Week Header con navegación ← →
// ─────────────────────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  final Map<String, List<HorarioItem>> semana;
  final String diaSeleccionado;
  final int weekOffset;
  final DateTime lunesDeSemana;
  final ValueChanged<String> onDiaSelected;
  final VoidCallback onRefresh;
  final ValueChanged<int> onWeekChanged;
  final VoidCallback onHoy;

  const _WeekHeader({
    required this.semana,
    required this.diaSeleccionado,
    required this.weekOffset,
    required this.lunesDeSemana,
    required this.onDiaSelected,
    required this.onRefresh,
    required this.onWeekChanged,
    required this.onHoy,
  });

  String get _rangoSemana {
    final domingo = lunesDeSemana.add(const Duration(days: 6));
    final fmt = DateFormat("d 'de' MMM", 'es');
    return '${fmt.format(lunesDeSemana)} – ${fmt.format(domingo)}';
  }

  @override
  Widget build(BuildContext context) {
    final hoyDb = AppConstants.diaDeHoyDb();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 52, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título + navegación de semana ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary, size: 28),
                  onPressed: () => onWeekChanged(-1),
                  tooltip: 'Semana anterior',
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Horario',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rangoSemana,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 28),
                  onPressed: () => onWeekChanged(1),
                  tooltip: 'Semana siguiente',
                ),
                // Botón "Hoy" si no estamos en la semana actual, si no refresh
                if (weekOffset != 0)
                  TextButton(
                    onPressed: onHoy,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Hoy',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Actualizar',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Selector de días ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: AppConstants.diasDb.asMap().entries.map((entry) {
                final idx = entry.key;
                final diaDb = entry.value;
                final sel = diaDb == diaSeleccionado;
                final esHoy = diaDb == hoyDb && weekOffset == 0;
                final fechaDia = lunesDeSemana.add(Duration(days: idx));
                final numDia = fechaDia.day.toString();
                final tieneClases = semana.containsKey(diaDb) &&
                    semana[diaDb]!.isNotEmpty;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDiaSelected(diaDb),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.cyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: esHoy && !sel
                            ? Border.all(
                                color: AppColors.cyan.withOpacity(0.5),
                                width: 1.5)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.diasCortos[idx],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? AppColors.bg
                                  : esHoy
                                      ? AppColors.cyan
                                      : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            numDia,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? AppColors.bg
                                  : esHoy
                                      ? AppColors.cyan
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tieneClases
                                  ? (sel
                                      ? AppColors.bg.withOpacity(0.5)
                                      : AppColors.cyan)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A — Timeline View
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineView extends StatefulWidget {
  final List<HorarioItem> items;
  final DateTime fechaDia;
  final int weekOffset;
  final HorarioItem? enCurso;
  final void Function(HorarioItem) onEdit;
  final void Function(HorarioItem) onDelete;
  final Future<void> Function() onRefresh;

  const _TimelineView({
    required this.items,
    required this.fechaDia,
    required this.weekOffset,
    required this.enCurso,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  static const double kHourH = 64.0;
  static const int kStart = 7;
  static const int kEnd = 22;
  static const double kLabelW = 46.0;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
  }

  @override
  void didUpdateWidget(covariant _TimelineView old) {
    super.didUpdateWidget(old);
    if (old.fechaDia != widget.fechaDia || old.weekOffset != widget.weekOffset) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Desplaza al tiempo actual o a la primera clase
  void _autoScroll() {
    if (!_scroll.hasClients) return;
    double target;
    final timeY = _currentTimeY();
    if (timeY != null) {
      target = (timeY - 100).clamp(0.0, double.infinity);
    } else if (widget.items.isNotEmpty) {
      target = (_toY(widget.items.first.horaInicio) - 48)
          .clamp(0.0, double.infinity);
    } else {
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  double _toY(String hora) {
    final p = hora.split(':');
    return ((int.parse(p[0]) - kStart) + int.parse(p[1]) / 60.0) * kHourH;
  }

  double? _currentTimeY() {
    if (widget.weekOffset != 0) return null;
    final now = DateTime.now();
    final fd = widget.fechaDia;
    if (now.year != fd.year || now.month != fd.month || now.day != fd.day) {
      return null;
    }
    if (now.hour < kStart || now.hour >= kEnd) return null;
    return ((now.hour - kStart) + now.minute / 60.0) * kHourH;
  }

  double get _totalH => (kEnd - kStart) * kHourH;

  void _showOptions(HorarioItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.tipoColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.materia,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${item.horaInicio} – ${item.horaFin}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.cyan),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text('Eliminar',
                  style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _EmptyTimeline(onRefresh: widget.onRefresh);
    }

    final timeY = _currentTimeY();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.cyan,
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 120),
        child: SizedBox(
          height: _totalH + 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Columna de horas ─────────────────────────────────────
              SizedBox(
                width: kLabelW,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i <= kEnd - kStart; i++)
                      Positioned(
                        top: i * kHourH - 8,
                        right: 6,
                        child: Text(
                          '${(kStart + i).toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Área de eventos ─────────────────────────────────────
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Líneas de hora completa
                    for (int i = 0; i <= kEnd - kStart; i++)
                      Positioned(
                        top: i * kHourH,
                        left: 0,
                        right: 0,
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.cardBorder
                              .withOpacity(i == 0 ? 0.8 : 0.4),
                        ),
                      ),
                    // Líneas de media hora (más sutiles)
                    for (int i = 0; i < kEnd - kStart; i++)
                      Positioned(
                        top: i * kHourH + kHourH / 2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: AppColors.cardBorder.withOpacity(0.15),
                        ),
                      ),
                    // Cards de eventos
                    ...widget.items.map((item) {
                      final top = _toY(item.horaInicio);
                      final height = (_toY(item.horaFin) - top)
                          .clamp(30.0, double.infinity);
                      final activo = widget.enCurso?.id == item.id;

                      return Positioned(
                        top: top + 2,
                        left: 2,
                        right: 2,
                        height: height - 4,
                        child: GestureDetector(
                          onTap: () => _showOptions(item),
                          child: _EventTile(item: item, activo: activo),
                        ),
                      );
                    }),
                    // C — Línea de tiempo actual
                    if (timeY != null)
                      Positioned(
                        top: timeY - 5,
                        left: -6,
                        right: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.red,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// C — Event Tile con badge "EN CURSO"
// ─────────────────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final HorarioItem item;
  final bool activo;
  const _EventTile({required this.item, required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = item.tipoColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: color.withOpacity(activo ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(activo ? 1.0 : 0.30),
          width: activo ? 1.5 : 1.0,
        ),
        boxShadow: activo
            ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge "EN CURSO"
          if (activo)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EN CURSO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          // Nombre de materia
          Text(
            item.materia,
            style: TextStyle(
              color: activo ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Lugar
          if (item.lugar != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 9, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    item.lugar!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          // Horario
          Text(
            '${item.horaInicio} – ${item.horaFin}',
            style: TextStyle(
              color: color.withOpacity(activo ? 0.95 : 0.65),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTimeline extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyTimeline({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.cyan,
      child: LayoutBuilder(
        builder: (_, c) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: c.maxHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: AppColors.textMuted, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin clases este día',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toca + para añadir una clase',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D — Formulario añadir / editar clase
// ─────────────────────────────────────────────────────────────────────────────

class _ClaseForm extends StatefulWidget {
  final HorarioItem? item;
  final String diaInicial;
  final VoidCallback onSaved;

  const _ClaseForm({
    required this.item,
    required this.diaInicial,
    required this.onSaved,
  });

  @override
  State<_ClaseForm> createState() => _ClaseFormState();
}

class _ClaseFormState extends State<_ClaseForm> {
  final _nombreCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  late String _dia;
  late String _tipo;
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  DateTime? _fecha; // null = recurrente, set = puntual
  bool _loading = false;

  // Tipos académicos (recurrentes por día de semana)
  static const _tiposRecurrentes = {'clase', 'laboratorio', 'taller', 'examen'};
  bool get _esPuntual => !_tiposRecurrentes.contains(_tipo);

  @override
  void initState() {
    super.initState();
    final e = widget.item;
    _tipo = e?.tipo ?? 'clase';
    _dia = e?.dia ?? widget.diaInicial;
    _fecha = e?.fecha;
    _nombreCtrl.text = e?.materia ?? '';
    _lugarCtrl.text = e?.lugar ?? '';
    _inicio = e != null ? _parseTime(e.horaInicio) : const TimeOfDay(hour: 8, minute: 0);
    _fin = e != null ? _parseTime(e.horaFin) : const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? _inicio : _fin,
    );
    if (picked != null) setState(() => isInicio ? _inicio = picked : _fin = picked);
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
        _dia = HorarioService.diaDesdeDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido'),
            backgroundColor: AppColors.red),
      );
      return;
    }
    if (_esPuntual && _fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha'),
            backgroundColor: AppColors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'dia': _dia,
        'hora_inicio': _fmtTime(_inicio),
        'hora_fin': _fmtTime(_fin),
        'materia': nombre,
        'tipo': _tipo,
        'lugar': _lugarCtrl.text.trim().isEmpty ? null : _lugarCtrl.text.trim(),
        'fecha': _esPuntual && _fecha != null
            ? HorarioService.formatFecha(_fecha!)
            : null,
      };
      if (widget.item != null) {
        await HorarioService.actualizar(widget.item!.id, payload);
      } else {
        await HorarioService.crear(payload);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.item != null;
    final labelNombre = _esPuntual ? 'Actividad *' : 'Materia *';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Encabezado
          Row(
            children: [
              Text(isEdit ? 'Editar entrada' : 'Nueva entrada',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          // Tipo — primero para que cambie el resto del form
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            dropdownColor: AppColors.surface,
            items: const [
              DropdownMenuItem(value: 'clase',        child: Text('Clase')),
              DropdownMenuItem(value: 'laboratorio',  child: Text('Laboratorio')),
              DropdownMenuItem(value: 'taller',       child: Text('Taller')),
              DropdownMenuItem(value: 'examen',       child: Text('Examen')),
              DropdownMenuItem(value: 'estudio',      child: Text('Estudio autónomo')),
              DropdownMenuItem(value: 'trabajo',      child: Text('Trabajo')),
              DropdownMenuItem(value: 'personal',     child: Text('Personal')),
            ],
            onChanged: (v) => setState(() {
              _tipo = v!;
              // Si cambia a puntual, limpiar fecha para que la pida de nuevo
              if (_esPuntual) _fecha = null;
            }),
          ),
          const SizedBox(height: 12),
          // Nombre / Materia
          TextField(
            controller: _nombreCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: labelNombre),
          ),
          const SizedBox(height: 12),
          // Día (recurrente) O Fecha (puntual)
          if (!_esPuntual)
            DropdownButtonFormField<String>(
              value: _dia,
              decoration: const InputDecoration(labelText: 'Día de la semana'),
              dropdownColor: AppColors.surface,
              items: AppConstants.diasDb.asMap().entries.map((e) {
                return DropdownMenuItem(
                  value: e.value,
                  child: Text(AppConstants.diasSemana[e.key]),
                );
              }).toList(),
              onChanged: (v) => setState(() => _dia = v!),
            )
          else
            GestureDetector(
              onTap: _pickFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fecha == null
                        ? AppColors.red.withOpacity(0.6)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16,
                        color: _fecha == null
                            ? AppColors.red.withOpacity(0.8)
                            : AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _fecha == null
                          ? 'Selecciona una fecha *'
                          : '${AppConstants.diasSemana[_fecha!.weekday - 1]}, '
                              '${_fecha!.day} de '
                              '${_mesNombre(_fecha!.month)} ${_fecha!.year}',
                      style: TextStyle(
                        color: _fecha == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Hora inicio – fin
          Row(
            children: [
              Expanded(child: _TimeButton(label: 'Inicio', time: _inicio, onTap: () => _pickTime(true))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
              ),
              Expanded(child: _TimeButton(label: 'Fin', time: _fin, onTap: () => _pickTime(false))),
            ],
          ),
          const SizedBox(height: 12),
          // Lugar
          TextField(
            controller: _lugarCtrl,
            decoration: const InputDecoration(
              labelText: 'Lugar (opcional)',
              prefixIcon: Icon(Icons.place_outlined, size: 18, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.bg))
                  : Text(isEdit ? 'Actualizar' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  String _mesNombre(int mes) => const [
    '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ][mes];
}

// ── Time picker button ────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.textMuted, size: 15),
            const SizedBox(width: 6),
            Text(
              time.format(context),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
