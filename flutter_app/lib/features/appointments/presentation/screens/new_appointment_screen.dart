import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../bloc/appointments_bloc.dart';
import '../../data/models/appointment_model.dart';

// Рис. 2.4б — Запис на прийом
class NewAppointmentScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  const NewAppointmentScreen({super.key, this.patientId, this.patientName});
  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedSlot;
  String _selectedReason = 'repeat';
  DoctorInfo? _selectedDoctor;

  // patient picker (used when screen opened without patientId)
  String? _pickedPatientId;
  String? _pickedPatientName;
  List<Map<String, dynamic>> _patients = [];
  bool _patientsLoading = false;

  String get _effectivePatientId => widget.patientId ?? _pickedPatientId ?? '';

  final _reasons = [
    ('repeat', 'Повторний прийом'),
    ('primary', 'Первинна консультація'),
    ('preventive', 'Профілактичний огляд'),
    ('emergency', 'Невідкладна допомога'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AppointmentsBloc>().add(AppointmentDoctorsRequested());
    if (widget.patientId == null) _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _patientsLoading = true);
    try {
      final r = await ApiService.instance.get('/patients');
      final list = (r.data as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _patients = list; _patientsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _patientsLoading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedSlot = null;
    });
    if (_selectedDoctor != null) {
      context.read<AppointmentsBloc>().add(AppointmentSlotsRequested(
            doctorId: _selectedDoctor!.id,
            date: _formatDate(selectedDay),
          ));
    }
  }

  void _confirm() {
    if (_effectivePatientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оберіть пацієнта'), backgroundColor: AppColors.warning));
      return;
    }
    if (_selectedDoctor == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оберіть лікаря, дату та час'), backgroundColor: AppColors.warning));
      return;
    }
    final parts = _selectedSlot!.split(':');
    final startTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, int.parse(parts[0]), int.parse(parts[1]));
    final endTime = startTime.add(const Duration(minutes: 30));

    context.read<AppointmentsBloc>().add(AppointmentCreateRequested({
      'patientId': _effectivePatientId,
      'doctorId': _selectedDoctor!.id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'reason': _selectedReason,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentsBloc, AppointmentsState>(
      listener: (context, state) {
        if (state is AppointmentCreated) {
          _showReceiptDialog(context, state);
        }
        if (state is AppointmentsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.danger));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              title: const Text('Запис на прийом', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Оберіть час візиту', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      if (widget.patientName != null)
                        Text(widget.patientName!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Patient selector (only when not pre-filled)
                  if (widget.patientId == null) ...[
                    _buildPatientSelector(),
                    const SizedBox(height: 12),
                  ],
                  // Doctor selector
                  _buildDoctorSelector(),
                  const SizedBox(height: 12),
                  // Calendar
                  _buildCalendar(),
                  const SizedBox(height: 12),
                  // Time slots
                  _buildSlots(),
                  const SizedBox(height: 12),
                  // Reason
                  _buildReasonSelector(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) => ElevatedButton.icon(
              onPressed: state is AppointmentsLoading ? null : _confirm,
              icon: state is AppointmentsLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check, size: 18),
              label: Text(_selectedSlot != null ? 'Підтвердити запис на $_selectedSlot' : 'Підтвердити запис'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelector() => GestureDetector(
        onTap: () => _showPatientPicker(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
          ),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: _pickedPatientName != null
                    ? Text(_pickedPatientName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text))
                    : Text(_patientsLoading ? 'Завантаження...' : 'Оберіть пацієнта', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      );

  void _showPatientPicker() {
    if (_patients.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final p = _patients[i];
          final name = '${p['lastName'] ?? ''} ${p['firstName'] ?? ''}'.trim();
          return ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(p['phone'] ?? ''),
            onTap: () {
              setState(() { _pickedPatientId = p['id'] as String; _pickedPatientName = name; });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorSelector() => BlocBuilder<AppointmentsBloc, AppointmentsState>(
        builder: (context, state) {
          List<DoctorModel> doctors = [];
          if (state is AppointmentSlotsLoaded) {
            doctors = state.doctors;
          }
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedDoctor != null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Д-р ${_selectedDoctor!.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          Text('${_selectedDoctor!.spec} • каб. ${_selectedDoctor!.office}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ])
                      : const Text('Оберіть лікаря', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => _showDoctorPicker(context, doctors),
                  child: const Text('Змінити', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      );

  void _showDoctorPicker(BuildContext context, List doctors) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final d = doctors[i];
          return ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: Text('Д-р ${d.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(d.specialization),
            onTap: () {
              setState(() => _selectedDoctor = DoctorInfo(id: d.id, name: d.shortName, spec: d.specialization, office: d.officeNumber));
              Navigator.pop(context);
              context.read<AppointmentsBloc>().add(AppointmentSlotsRequested(doctorId: d.id, date: _formatDate(_selectedDay)));
            },
          );
        },
      ),
    );
  }

  Widget _buildCalendar() => Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          onDaySelected: _onDaySelected,
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: AppColors.danger),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
          ),
        ),
      );

  Widget _buildSlots() => BlocBuilder<AppointmentsBloc, AppointmentsState>(
        builder: (context, state) {
          final slots = state is AppointmentSlotsLoaded ? state.slots : <dynamic>[];
          if (slots.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(_selectedDoctor == null ? 'Оберіть лікаря' : 'Доступних слотів немає', style: const TextStyle(color: AppColors.textSecondary))),
            );
          }
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ДОСТУПНІ СЛОТИ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2),
                  itemCount: slots.length,
                  itemBuilder: (_, i) {
                    final s = slots[i];
                    final isSelected = s.time == _selectedSlot && !s.busy;
                    return GestureDetector(
                      onTap: s.busy ? null : () => setState(() => _selectedSlot = s.time),
                      child: Container(
                        decoration: BoxDecoration(
                          color: s.busy ? const Color(0xFFF3F4F6) : (isSelected ? AppColors.primary : const Color(0xFFE3F2FD)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: s.busy ? const Color(0xFF9CA3AF) : (isSelected ? Colors.white : AppColors.primary),
                            decoration: s.busy ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );

  Widget _buildReasonSelector() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ПРИЧИНА ВІЗИТУ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2, style: const TextStyle(fontSize: 13, color: AppColors.text)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedReason = v); },
            ),
          ],
        ),
      );

  void _showReceiptDialog(BuildContext screenContext, AppointmentCreated state) {
    final emailController = TextEditingController();
    final patientName = widget.patientName ?? _pickedPatientName ?? '';
    final doctorName = _selectedDoctor != null ? 'Д-р ${_selectedDoctor!.name}' : '';
    final spec = _selectedDoctor?.spec ?? '';
    final d = _selectedDay;
    final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final timeStr = _selectedSlot ?? '';
    final appointmentId = state.appointment.id;

    showDialog<void>(
      context: screenContext,
      barrierDismissible: false,
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text('Надіслати чек', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Введіть email пацієнта — надішлемо чек із посиланням на оплату.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'patient@example.com',
                  prefixIcon: const Icon(Icons.alternate_email, size: 18),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ]),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: sending ? null : () {
                  Navigator.pop(ctx);
                  Navigator.pop(screenContext);
                  ScaffoldMessenger.of(screenContext).showSnackBar(const SnackBar(
                    content: Text('✅ Запис підтверджено!'), backgroundColor: AppColors.success));
                },
                child: const Text('Пропустити'),
              ),
              ElevatedButton.icon(
                onPressed: sending ? null : () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;
                  setS(() => sending = true);
                  try {
                    await ApiService.instance.post('/appointments/receipt', data: {
                      'email': email,
                      'patientName': patientName,
                      'doctorName': doctorName,
                      'specialization': spec,
                      'date': dateStr,
                      'time': timeStr,
                      'reason': _selectedReason,
                      'appointmentId': appointmentId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (screenContext.mounted) {
                      Navigator.pop(screenContext);
                      ScaffoldMessenger.of(screenContext).showSnackBar(SnackBar(
                        content: Text('✅ Чек надіслано на $email'), backgroundColor: AppColors.success));
                    }
                  } catch (_) {
                    setS(() => sending = false);
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Не вдалось надіслати email'), backgroundColor: AppColors.danger));
                  }
                },
                icon: sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(sending ? 'Надсилання...' : 'Надіслати'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DoctorInfo {
  final String id;
  final String name;
  final String spec;
  final String office;
  const DoctorInfo({required this.id, required this.name, required this.spec, required this.office});
}
