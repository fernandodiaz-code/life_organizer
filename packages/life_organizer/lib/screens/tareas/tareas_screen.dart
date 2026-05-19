import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/tarea.dart';
import '../../services/tareas_service.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => TareasScreenState();
}

class TareasScreenState extends State<TareasScreen> {
  List<Tarea> _tareas = [];
  bool _loading = true;
  String _filtro = 'todas';

  final _filtros = {
    'todas': 'Todas',
    'pendiente': 'Pendientes',
    'en_progreso': 'En progreso',
    'completada': 'Completadas',
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      final data = await TareasService.fetchAll();
      if (mounted) setState(() => _tareas = data);
    } catch (e) {
      if (mounted) _snack('Error al cargar tareas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Tarea> get _filtered {
    if (_filtro == 'todas') return _tareas;
    return _tareas.where((t) => t.estado == _filtro).toList();
  }

  Future<void> _completar(Tarea t) async {
    try {
      await TareasService.completar(t.id);
      setState(() {
        final i = _tareas.indexWhere((x) => x.id == t.id);
        if (i != -1) {
          _tareas[i] = t.copyWith(
            estado: 'completada',
            completadaEn: DateTime.now(),
          );
        }
      });
      _snack('Tarea completada', success: true);
    } catch (_) {
      _snack('Error al completar tarea');
    }
  }

  Future<void> _eliminar(Tarea t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${t.titulo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TareasService.eliminar(t.id);
      setState(() => _tareas.removeWhere((x) => x.id == t.id));
      _snack('Tarea eliminada');
    } catch (_) {
      _snack('Error al eliminar');
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.green : AppColors.red,
    ));
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddTareaSheet(
        onCreated: (t) {
          setState(() => _tareas.insert(0, t));
          _snack('Tarea creada', success: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filtros.entries.map((e) {
                  final sel = _filtro == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: sel,
                      onSelected: (_) => setState(() => _filtro = e.key),
                      selectedColor: AppColors.cyanGlow,
                      labelStyle: TextStyle(
                        color: sel ? AppColors.cyan : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              color: AppColors.cyan,
              child: filtered.isEmpty
                  ? LayoutBuilder(
                      builder: (ctx, constraints) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.task_alt,
                                      color: AppColors.textMuted, size: 56),
                                  const SizedBox(height: 12),
                                  Text('Sin tareas',
                                      style: Theme.of(ctx).textTheme.bodyLarge),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _TareaListTile(
                        tarea: filtered[i],
                        onComplete: () => _completar(filtered[i]),
                        onDelete: () => _eliminar(filtered[i]),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }
}

class _TareaListTile extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TareaListTile({
    required this.tarea,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = tarea.isCompleted;
    return Dismissible(
      key: ValueKey(tarea.id),
      direction: DismissDirection.horizontal,
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.check_circle_outline, color: AppColors.green),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd && !done) {
          onComplete();
        } else if (dir == DismissDirection.endToStart) {
          onDelete();
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: glassCard(),
        child: Row(
          children: [
            GestureDetector(
              onTap: done ? null : onComplete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.green.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: done ? AppColors.green : tarea.priorityColor,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: AppColors.green)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarea.titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                  ),
                  if (tarea.materia != null || tarea.deadline != null)
                    const SizedBox(height: 3),
                  Row(
                    children: [
                      if (tarea.materia != null)
                        Text(tarea.materia!,
                            style: Theme.of(context).textTheme.bodySmall),
                      if (tarea.materia != null && tarea.deadline != null)
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      if (tarea.deadline != null)
                        Text(
                          DateFormat('d MMM', 'es').format(tarea.deadline!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: tarea.deadline!.isBefore(DateTime.now()) && !done
                                    ? AppColors.red
                                    : AppColors.textMuted,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tarea.priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    tarea.priorityLabel,
                    style: TextStyle(
                      color: tarea.priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textMuted),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTareaSheet extends StatefulWidget {
  final Function(Tarea) onCreated;
  const _AddTareaSheet({required this.onCreated});

  @override
  State<_AddTareaSheet> createState() => _AddTareaSheetState();
}

class _AddTareaSheetState extends State<_AddTareaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _materiaCtrl = TextEditingController();
  int _prioridad = 2;
  DateTime? _deadline;
  bool _loading = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _materiaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final nueva = Tarea(
        id: '',
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        materia: _materiaCtrl.text.trim().isEmpty ? null : _materiaCtrl.text.trim(),
        prioridad: _prioridad,
        estado: 'pendiente',
        deadline: _deadline,
      );
      final creada = await TareasService.crear(nueva);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(creada);
      }
    } catch (e) {
      debugPrint('❌ Error al crear tarea: $e');
      if (mounted) {
        final msg = e is PostgrestException
            ? 'Supabase: ${e.message}\n(code: ${e.code})'
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Nueva tarea',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _materiaCtrl,
              decoration: const InputDecoration(labelText: 'Materia'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Prioridad:',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                ...{1: 'Baja', 2: 'Media', 3: 'Alta'}.entries.map((e) {
                  final sel = _prioridad == e.key;
                  final color = e.key == 3
                      ? AppColors.red
                      : e.key == 2
                          ? AppColors.orange
                          : AppColors.green;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _prioridad = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? color.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(
                              color: sel ? color : AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                              color: sel ? color : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _deadline == null
                          ? 'Fecha límite (opcional)'
                          : DateFormat('d MMMM yyyy', 'es').format(_deadline!),
                      style: TextStyle(
                        color: _deadline == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (_deadline != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Crear tarea'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
