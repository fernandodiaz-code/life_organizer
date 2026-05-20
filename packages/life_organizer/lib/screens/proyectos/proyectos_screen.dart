import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/proyecto.dart';
import '../../services/proyectos_service.dart';

class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => ProyectosScreenState();
}

class ProyectosScreenState extends State<ProyectosScreen> {
  List<Proyecto> _proyectos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      final data = await ProyectosService.fetchAll();
      if (mounted) setState(() => _proyectos = data);
    } catch (e) {
      debugPrint('Error al cargar proyectos: $e');
      if (mounted) _snack('Error al cargar proyectos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.green : AppColors.red,
    ));
  }

  Future<void> _eliminar(Proyecto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Eliminar "${p.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProyectosService.eliminar(p.id);
      setState(() => _proyectos.removeWhere((x) => x.id == p.id));
      _snack('Proyecto eliminado');
    } catch (e) {
      debugPrint('Error al eliminar proyecto: $e');
      _snack('Error al eliminar');
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddProyectoSheet(
        onCreated: (p) {
          setState(() => _proyectos.insert(0, p));
          _snack('Proyecto creado', success: true);
        },
      ),
    );
  }

  void _showEditProgress(Proyecto p) {
    double progreso = p.progreso;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(p.nombre),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${progreso.round()}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.cyan,
                    ),
              ),
              Slider(
                value: progreso,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.cyan,
                inactiveColor: AppColors.card,
                onChanged: (v) => setDlg(() => progreso = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ProyectosService.actualizarProgreso(p.id, progreso);
                  await load();
                  _snack('Progreso actualizado', success: true);
                } catch (e) {
                  debugPrint('Error al actualizar progreso: $e');
                  _snack('Error al actualizar');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              color: AppColors.cyan,
              child: _proyectos.isEmpty
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
                                  const Icon(Icons.rocket_launch_outlined,
                                      color: AppColors.textMuted, size: 56),
                                  const SizedBox(height: 12),
                                  Text('Sin proyectos',
                                      style: Theme.of(ctx).textTheme.bodyLarge),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _proyectos.length,
                      itemBuilder: (_, i) => _ProyectoCard(
                        proyecto: _proyectos[i],
                        onDelete: () => _eliminar(_proyectos[i]),
                        onEditProgress: () => _showEditProgress(_proyectos[i]),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proyecto'),
      ),
    );
  }
}

class _ProyectoCard extends StatelessWidget {
  final Proyecto proyecto;
  final VoidCallback onDelete;
  final VoidCallback onEditProgress;

  const _ProyectoCard({
    required this.proyecto,
    required this.onDelete,
    required this.onEditProgress,
  });

  @override
  Widget build(BuildContext context) {
    final pct = proyecto.progreso / 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: glassCard(borderColor: proyecto.estadoColor.withOpacity(0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(proyecto.nombre,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: proyecto.estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  proyecto.estadoLabel,
                  style: TextStyle(
                    color: proyecto.estadoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textMuted, size: 20),
                color: AppColors.surface,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'progress',
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 18, color: AppColors.cyan),
                        SizedBox(width: 8),
                        Text('Editar progreso'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                        SizedBox(width: 8),
                        Text('Eliminar',
                            style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                  if (v == 'progress') onEditProgress();
                },
              ),
            ],
          ),
          if (proyecto.descripcion != null) ...[
            const SizedBox(height: 6),
            Text(
              proyecto.descripcion!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    valueColor: AlwaysStoppedAnimation(proyecto.estadoColor),
                    backgroundColor: AppColors.card,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onEditProgress,
                child: Text(
                  '${proyecto.progreso.round()}%',
                  style: TextStyle(
                    color: proyecto.estadoColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (proyecto.fechaInicio != null || proyecto.fechaFin != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  [
                    if (proyecto.fechaInicio != null)
                      DateFormat('d MMM', 'es').format(proyecto.fechaInicio!),
                    if (proyecto.fechaFin != null)
                      DateFormat('d MMM yyyy', 'es').format(proyecto.fechaFin!),
                  ].join(' → '),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProyectoSheet extends StatefulWidget {
  final Function(Proyecto) onCreated;
  const _AddProyectoSheet({required this.onCreated});

  @override
  State<_AddProyectoSheet> createState() => _AddProyectoSheetState();
}

class _AddProyectoSheetState extends State<_AddProyectoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _estado = 'en_progreso';
  double _progreso = 0;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final nuevo = Proyecto(
        id: '',
        nombre: _nombreCtrl.text.trim(),
        descripcion:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        estado: _estado,
        progreso: _progreso,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      final creado = await ProyectosService.crear(nuevo);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(creado);
      }
    } catch (e) {
      debugPrint('Error al crear proyecto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is PostgrestException
                ? 'Supabase: ${e.message}'
                : 'Error al crear proyecto'),
            backgroundColor: AppColors.red,
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Nuevo proyecto',
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
              controller: _nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              dropdownColor: AppColors.surface,
              items: const [
                DropdownMenuItem(
                    value: 'en_progreso', child: Text('En progreso')),
                DropdownMenuItem(
                    value: 'pausado', child: Text('Pausado')),
                DropdownMenuItem(
                    value: 'completado', child: Text('Completado')),
              ],
              onChanged: (v) => setState(() => _estado = v!),
            ),
            const SizedBox(height: 16),
            Text('Progreso inicial: ${_progreso.round()}%',
                style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _progreso,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppColors.cyan,
              inactiveColor: AppColors.card,
              onChanged: (v) => setState(() => _progreso = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Inicio',
                    date: _fechaInicio,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: 'Fin',
                    date: _fechaFin,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
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
                    : const Text('Crear proyecto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.textMuted, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('d MMM yy', 'es').format(date!)
                    : label,
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
