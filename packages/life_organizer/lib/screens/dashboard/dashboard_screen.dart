import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/tarea.dart';
import '../../models/horario.dart';
import '../../models/deadline_item.dart';
import '../../services/tareas_service.dart';
import '../../services/horario_service.dart';
import '../../services/deadlines_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashData> _future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    _future = Future.wait([
      HorarioService.fetchHoy(),
      TareasService.fetchPendientes(limit: 4),
      DeadlinesService.fetchProximos(dias: 7),
    ]).then((results) => _DashData(
          horario: results[0] as List<HorarioItem>,
          tareas: results[1] as List<Tarea>,
          deadlines: results[2] as List<DeadlineItem>,
        ));
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final emailName = user?.email?.split('@').first ?? 'Usuario';
    final hoy = DateFormat('EEEE, d MMM', 'es').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_saludo()}, $emailName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              hoy,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => setState(load),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => Supabase.instance.client.auth.signOut(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: FutureBuilder<_DashData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Error al cargar datos',
                      style: Theme.of(context).textTheme.bodyLarge),
                  TextButton(
                    onPressed: () => setState(load),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(load),
            color: AppColors.cyan,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SectionHeader(
                  icon: Icons.today,
                  title: 'Clases de hoy · ${AppConstants.diaDeHoy()}',
                ),
                const SizedBox(height: 8),
                if (data.horario.isEmpty)
                  _EmptyCard(icon: Icons.beach_access, text: 'Sin clases hoy')
                else
                  ...data.horario.map((h) => _HorarioCard(item: h)),

                const SizedBox(height: 20),
                _SectionHeader(
                  icon: Icons.check_circle_outline,
                  title: 'Tareas pendientes',
                  badge: data.tareas.length,
                ),
                const SizedBox(height: 8),
                if (data.tareas.isEmpty)
                  _EmptyCard(icon: Icons.celebration, text: 'Todo al día')
                else
                  ...data.tareas.map((t) => _TareaCard(tarea: t)),

                const SizedBox(height: 20),
                _SectionHeader(
                  icon: Icons.alarm,
                  title: 'Próximos deadlines',
                  badge: data.deadlines.length,
                ),
                const SizedBox(height: 8),
                if (data.deadlines.isEmpty)
                  _EmptyCard(icon: Icons.check_circle, text: 'Sin deadlines próximos')
                else
                  ...data.deadlines.map((d) => _DeadlineCard(item: d)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashData {
  final List<HorarioItem> horario;
  final List<Tarea> tareas;
  final List<DeadlineItem> deadlines;
  const _DashData({
    required this.horario,
    required this.tareas,
    required this.deadlines,
  });
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? badge;

  const _SectionHeader({required this.icon, required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cyanGlow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassCard(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HorarioCard extends StatelessWidget {
  final HorarioItem item;
  const _HorarioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: glassCard(borderColor: item.tipoColor.withOpacity(0.4)),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: item.tipoColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.materia,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                const SizedBox(height: 2),
                Text(
                  '${item.horaInicio} – ${item.horaFin}'
                  '${item.lugar != null ? '  ·  ${item.lugar}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.tipoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.tipo,
              style: TextStyle(
                color: item.tipoColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TareaCard extends StatelessWidget {
  final Tarea tarea;
  const _TareaCard({required this.tarea});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: glassCard(),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tarea.priorityColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tarea.titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (tarea.materia != null)
                  Text(tarea.materia!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (tarea.deadline != null)
            Text(
              DateFormat('d MMM', 'es').format(tarea.deadline!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tarea.deadline!.isBefore(DateTime.now())
                        ? AppColors.red
                        : AppColors.textMuted,
                  ),
            ),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final DeadlineItem item;
  const _DeadlineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: glassCard(borderColor: item.urgenciaColor.withOpacity(0.4)),
      child: Row(
        children: [
          Icon(Icons.alarm, color: item.urgenciaColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                if (item.materia != null)
                  Text(item.materia!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('d MMM', 'es').format(item.fecha),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: item.urgenciaColor),
              ),
              Text(
                item.urgenciaLabel,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
