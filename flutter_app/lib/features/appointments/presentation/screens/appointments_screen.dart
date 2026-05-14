import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../bloc/appointments_bloc.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'new_appointment_screen.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/appointments_repository.dart';

class AppointmentsScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const AppointmentsScreen({super.key, required this.onNavigate});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {

  @override
  void initState() {
    super.initState();
    context.read<AppointmentsBloc>().add(AppointmentsLoadRequested());
  }

  void _reload() => context.read<AppointmentsBloc>().add(AppointmentsLoadRequested());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Прийоми', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Оновити', onPressed: _reload),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AppointmentsBloc(repository: AppointmentsRepository()),
                child: const NewAppointmentScreen(),
              ),
            )).then((_) { if (context.mounted) _reload(); }),
          ),
        ],
      ),
      body: BlocBuilder<AppointmentsBloc, AppointmentsState>(
        builder: (context, state) {
          if (state is AppointmentsLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (state is AppointmentsError) return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
          if (state is AppointmentsLoaded) {
            if (state.appointments.isEmpty) return const Center(child: Text('Прийомів не знайдено'));
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _appointmentCard(state.appointments[i]),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      bottomNavigationBar: MedCareBottomNav(currentIndex: 1, onTap: widget.onNavigate),
    );
  }

  Widget _appointmentCard(AppointmentModel a) {
    final statusColor = a.status == 'scheduled'
        ? AppColors.primary
        : a.status == 'completed'
            ? AppColors.success
            : AppColors.danger;

    return GestureDetector(
      onTap: () => _showActions(a),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 2),
              Text('${a.doctorSpec} • ${a.reasonLabel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(a.timeStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor)),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 18),
          ]),
        ]),
      ),
    );
  }

  void _showActions(AppointmentModel a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(a.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('${a.timeStr} • ${a.doctorSpec}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            _actionTile(Icons.edit_calendar_rounded, 'Перенести прийом', const Color(0xFF3B82F6), () {
              Navigator.pop(ctx);
              _showReschedule(a);
            }),
            const SizedBox(height: 10),
            _actionTile(Icons.cancel_outlined, 'Скасувати прийом', AppColors.danger, () {
              Navigator.pop(ctx);
              _confirmDelete(a);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }

  // ── Reschedule ──────────────────────────────────────────────────────────────
  void _showReschedule(AppointmentModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RescheduleSheet(appointment: a, onSaved: _reload),
    );
  }

  // ── Delete ──────────────────────────────────────────────────────────────────
  void _confirmDelete(AppointmentModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скасувати прийом?'),
        content: Text('Прийом ${a.patientName} о ${a.timeStr} буде скасовано.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Назад')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Скасувати', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ApiService.instance.delete('/appointments/${a.id}');
        _reload();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

// ── Reschedule bottom sheet ────────────────────────────────────────────────
class _RescheduleSheet extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onSaved;
  const _RescheduleSheet({required this.appointment, required this.onSaved});
  @override State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSlots(_selectedDate);
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() { _loadingSlots = true; _selectedTime = null; });
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final r = await ApiService.instance.get('/appointments/slots', queryParameters: {
        'doctorId': widget.appointment.doctorId, 'date': dateStr,
      });
      if (mounted) setState(() { _slots = List<Map<String, dynamic>>.from(r.data); _loadingSlots = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _save() async {
    if (_selectedTime == null) return;
    setState(() => _saving = true);
    try {
      final parts = _selectedTime!.split(':');
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          int.parse(parts[0]), int.parse(parts[1]));
      final end = start.add(const Duration(minutes: 30));
      await ApiService.instance.patch('/appointments/${widget.appointment.id}', data: {
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Прийом перенесено. Пацієнта сповіщено на email.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Перенести прийом', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Date row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: List.generate(14, (i) {
              final d = today.add(Duration(days: i));
              final isSelected = _selectedDate.day == d.day && _selectedDate.month == d.month;
              return GestureDetector(
                onTap: () { setState(() => _selectedDate = d); _loadSlots(d); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Column(children: [
                    Text(['Нд','Пн','Вт','Ср','Чт','Пт','Сб'][d.weekday % 7],
                        style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                    Text(d.day.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppColors.text)),
                  ]),
                ),
              );
            })),
          ),
          const SizedBox(height: 16),
          if (_loadingSlots) const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else Expanded(
            child: GridView.builder(
              controller: controller,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _slots.length,
              itemBuilder: (_, i) {
                final slot = _slots[i];
                final busy = slot['busy'] == true;
                final time = slot['time'] as String;
                final selected = _selectedTime == time;
                return GestureDetector(
                  onTap: busy ? null : () => setState(() => _selectedTime = time),
                  child: Container(
                    decoration: BoxDecoration(
                      color: busy ? AppColors.background : selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Center(child: Text(time,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: busy ? AppColors.border : selected ? Colors.white : AppColors.text,
                        ))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_selectedTime == null || _saving) ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

