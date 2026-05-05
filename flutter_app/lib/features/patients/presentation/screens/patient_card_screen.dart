import '../../data/models/patient_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/repositories/patients_repository.dart';
import '../../../appointments/presentation/screens/new_appointment_screen.dart';
import '../../../appointments/data/repositories/appointments_repository.dart';
import '../../../appointments/presentation/bloc/appointments_bloc.dart';

class PatientCardScreen extends StatefulWidget {
  final String patientId;
  const PatientCardScreen({super.key, required this.patientId});
  @override
  State<PatientCardScreen> createState() => _PatientCardScreenState();
}

class _PatientCardScreenState extends State<PatientCardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Картка', 'Прийоми', 'Рецепти', 'Аналізи', 'Діагнози'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<PatientsBloc>().add(PatientLoadRequested(widget.patientId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AppointmentsBloc(repository: AppointmentsRepository())
            ..add(AppointmentPatientRequested(widget.patientId)),
        ),
      ],
      child: BlocBuilder<PatientsBloc, PatientsState>(
        builder: (context, state) {
          if (state is PatientsLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
          }
          if (state is PatientsError) {
            return Scaffold(body: Center(child: Text(state.message)));
          }
          if (state is PatientDetailLoaded) {
            final p = state.patient;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 175,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                    title: const Text('Картка пацієнта', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
                              child: Center(child: Text(p.lastName.isNotEmpty ? p.lastName[0] : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(p.fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text('ID: #PT-${p.id.substring(0, 5).toUpperCase()} • ${p.birthDate.substring(0, 10)} (${p.age} р.)',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 5, children: [
                                    if (p.bloodGroup.isNotEmpty) _tag('${p.bloodGroup} гр.'),
                                    if (p.rhFactor.isNotEmpty) _tag('Rh${p.rhFactor}'),
                                    for (final a in p.allergies) _tag('⚠ $a', isDanger: true),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.white,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCardTab(p),
                    _buildAppointmentsTab(context, p.id, p.fullName),
                    _buildPrescriptionsTab(context, p.id),
                    _LabTestsTab(patientId: p.id),
                    _buildDiagnosesTab(context, p.id),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _tag(String text, {bool isDanger = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  // ── Вкладка "Картка" ─────────────────────────────────────────────────────
  Widget _buildCardTab(dynamic p) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _sectionCard(title: 'Особисті дані', children: [
            _infoRow('Страховий поліс', p.insuranceNo.isNotEmpty ? p.insuranceNo : '—'),
            _infoRow('Телефон', p.phone.isNotEmpty ? p.phone : '—'),
            _infoRow('Email', p.email.isNotEmpty ? p.email : '—'),
            if (p.allergies.isNotEmpty) _infoRow('Алергії', p.allergies.join(', '), isDanger: true),
          ]),
          const SizedBox(height: 12),
          _sectionCard(title: "Показники (останні)", children: [
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2,
              children: [
                _vitalCard('—', 'мм рт.ст.', 'Тиск', AppColors.danger),
                _vitalCard('—', 'уд/хв', 'Пульс', AppColors.success),
                _vitalCard('—', 'кг', 'Вага', AppColors.primary),
                _vitalCard('—', '°C', 'Температура', AppColors.warning),
              ],
            ),
          ]),
        ]),
      );

  // ── Вкладка "Прийоми" ────────────────────────────────────────────────────
  Widget _buildAppointmentsTab(BuildContext ctx, String patientId, String patientName) => BlocBuilder<AppointmentsBloc, AppointmentsState>(
        builder: (context, state) {
          if (state is AppointmentsLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (state is AppointmentsError) return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));

          final appointments = state is AppointmentsLoaded ? state.appointments : [];

          return Column(
            children: [
              Expanded(
                child: appointments.isEmpty
                    ? _emptyState(Icons.calendar_today_outlined, 'Прийомів немає', 'Натисніть «+» щоб записати пацієнта')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final a = appointments[i];
                          return _appointmentCard(a);
                        },
                      ),
              ),
              _bottomButton(
                label: 'Записати на прийом',
                icon: Icons.add,
                onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AppointmentsBloc(repository: AppointmentsRepository()),
                    child: NewAppointmentScreen(patientId: patientId, patientName: patientName),
                  ),
                )).then((_) => context.read<AppointmentsBloc>().add(AppointmentPatientRequested(patientId))),
              ),
            ],
          );
        },
      );

  Widget _appointmentCard(dynamic a) {
    final statusColor = a.status == 'completed' ? AppColors.success : a.status == 'cancelled' ? AppColors.danger : AppColors.primary;
    final statusLabel = a.status == 'completed' ? 'Завершено' : a.status == 'cancelled' ? 'Скасовано' : 'Заплановано';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.event, color: statusColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.reasonLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text('${a.startTime.day.toString().padLeft(2,'0')}.${a.startTime.month.toString().padLeft(2,'0')}.${a.startTime.year}  ${a.timeStr}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  // ── Вкладка "Рецепти" ────────────────────────────────────────────────────
  Widget _buildPrescriptionsTab(BuildContext ctx, String patientId) {
    context.read<PatientsBloc>().add(PatientPrescriptionsRequested(patientId));
    return BlocBuilder<PatientsBloc, PatientsState>(
      buildWhen: (prev, curr) => curr is PatientPrescriptionsLoaded || curr is PatientsLoading || curr is PatientsError,
      builder: (context, state) {
        if (state is PatientsLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        
        List<PrescriptionModel> prescriptions = [];
        if (state is PatientPrescriptionsLoaded) {
          prescriptions = state.prescriptions;
        }

        return Column(children: [
          Expanded(
            child: prescriptions.isEmpty
                ? _emptyState(Icons.medication_outlined, 'Рецептів немає', 'Натисніть «+» щоб виписати рецепт')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prescriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _prescriptionCard(prescriptions[i]),
                  ),
          ),
          _bottomButton(
            label: 'Виписати рецепт',
            icon: Icons.add,
            onTap: () => _showAddPrescriptionSheet(ctx, patientId),
          ),
        ]);
      },
    );
  }

  Widget _prescriptionCard(PrescriptionModel rx) {
    final color = rx.status == 'active' ? AppColors.success : rx.status == 'completed' ? AppColors.primary : AppColors.textSecondary;
    final statusLabel = rx.status == 'active' ? 'Активний' : rx.status == 'completed' ? 'Завершено' : 'Скасовано';
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.medication, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(rx.medicationName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(statusLabel, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _rxChip(Icons.straighten, rx.dosage),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(rx.createdAt.substring(0, 10), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        if (rx.instruction.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(rx.instruction, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  Widget _rxChip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);

  void _showAddPrescriptionSheet(BuildContext ctx, String patientId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: ctx.read<PatientsBloc>(),
        child: _AddPrescriptionSheet(patientId: patientId),
      ),
    );
  }

  // ── Вкладка "Діагнози" ───────────────────────────────────────────────────
  Widget _buildDiagnosesTab(BuildContext ctx, String patientId) {
    return _DiagnosesTab(patientId: patientId);
  }

  // ── Shared widgets ───────────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
      );

  Widget _bottomButton({required String label, required IconData icon, required VoidCallback onTap}) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Widget _sectionCard({required String title, required List<Widget> children}) => Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _infoRow(String key, String value, {bool isDanger = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDanger ? AppColors.danger : AppColors.text)),
        ]),
      );

  Widget _vitalCard(String value, String unit, String label, Color color) => Container(
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 3))),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Форма виписки рецепту ─────────────────────────────────────────────────
class _AddPrescriptionSheet extends StatefulWidget {
  final String patientId;
  const _AddPrescriptionSheet({required this.patientId});
  @override
  State<_AddPrescriptionSheet> createState() => _AddPrescriptionSheetState();
}

class _AddPrescriptionSheetState extends State<_AddPrescriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PatientsBloc>().add(PatientPrescriptionCreateRequested({
      'patientId': widget.patientId,
      'medicationName': _nameCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim(),
      'instruction': _instCtrl.text.trim(),
    }));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Рецепт успішно створено'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Виписати новий рецепт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: _dec('Назва препарату *', hint: 'напр. Амоксицилін'),
            validator: (v) => v!.isEmpty ? 'Введіть назву' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dosageCtrl,
            decoration: _dec('Дозування *', hint: 'напр. 500 мг, 2 рази на день'),
            validator: (v) => v!.isEmpty ? 'Введіть дозування' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instCtrl,
            maxLines: 2,
            decoration: _dec('Інструкція / Примітки', hint: 'напр. Після їжі, курс 7 днів'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Створити рецепт', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

// ── Вкладка Аналізи ───────────────────────────────────────────────────────
class _LabTestsTab extends StatefulWidget {
  final String patientId;
  const _LabTestsTab({required this.patientId});
  @override
  State<_LabTestsTab> createState() => _LabTestsTabState();
}

class _LabTestsTabState extends State<_LabTestsTab> {
  List<Map<String, dynamic>> _tests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.instance.get('/lab-tests/patient/${widget.patientId}');
      if (mounted) setState(() { _tests = List<Map<String, dynamic>>.from(r.data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)));

    return Column(children: [
      Expanded(
        child: _tests.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.biotech_outlined, size: 56, color: AppColors.border),
                SizedBox(height: 16),
                Text('Аналізів немає', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text('Натисніть «+» щоб додати аналіз', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _labTestCard(_tests[i]),
              ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: ElevatedButton.icon(
          onPressed: () => _showAddLabTestSheet(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Додати аналіз'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }

  Widget _labTestCard(Map<String, dynamic> t) {
    final name = t['testName'] ?? t['name'] ?? '—';
    final result = t['result'] ?? '—';
    final status = t['status'] ?? '';
    final createdAt = t['createdAt'] ?? t['date'] ?? '';
    String dateStr = '—';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }
    final Color statusColor = status == 'normal' ? AppColors.success : status == 'abnormal' ? AppColors.danger : AppColors.textSecondary;
    final String statusLabel = status == 'normal' ? 'Норма' : status == 'abnormal' ? 'Відхилення' : 'Очікується';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.science_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Результат: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(child: Text(result, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        if (t['notes'] != null && (t['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(t['notes'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }

  void _showAddLabTestSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddLabTestSheet(patientId: widget.patientId, onSaved: _load),
    );
  }
}

// ── Форма додавання аналізу ───────────────────────────────────────────────
class _AddLabTestSheet extends StatefulWidget {
  final String patientId;
  final VoidCallback onSaved;
  const _AddLabTestSheet({required this.patientId, required this.onSaved});
  @override
  State<_AddLabTestSheet> createState() => _AddLabTestSheetState();
}

class _AddLabTestSheetState extends State<_AddLabTestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _status = 'pending';
  bool _saving = false;

  final _statuses = [('pending', 'Очікується'), ('normal', 'Норма'), ('abnormal', 'Відхилення')];

  @override
  void dispose() {
    _nameCtrl.dispose(); _resultCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post('/lab-tests', data: {
        'patientId': widget.patientId,
        'testName': _nameCtrl.text.trim(),
        'result': _resultCtrl.text.trim(),
        'status': _status,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Аналіз збережено'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Center(child: Text('Новий аналіз', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: _dec('Назва аналізу *', hint: 'напр. Загальний аналіз крові'),
              validator: (v) => v == null || v.isEmpty ? "Обов'язкове поле" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _resultCtrl,
              decoration: _dec('Результат *', hint: 'напр. Hb 130 г/л'),
              validator: (v) => v == null || v.isEmpty ? "Обов'язкове поле" : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _dec('Статус'),
              items: _statuses.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _status = v); },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: _dec('Примітки', hint: 'Необов\'язково'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Вкладка Діагнози (окремий StatefulWidget з власним завантаженням) ─────
class _DiagnosesTab extends StatefulWidget {
  final String patientId;
  const _DiagnosesTab({required this.patientId});
  @override
  State<_DiagnosesTab> createState() => _DiagnosesTabState();
}

class _DiagnosesTabState extends State<_DiagnosesTab> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.instance.get('/medical-records/patient/${widget.patientId}');
      if (mounted) setState(() { _records = List<Map<String, dynamic>>.from(r.data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)));

    return Column(children: [
      Expanded(
        child: _records.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.assignment_outlined, size: 56, color: AppColors.border),
                SizedBox(height: 16),
                Text('Діагнозів немає', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text('Натисніть «+» щоб додати запис', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _diagnosisCard(_records[i]),
              ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: ElevatedButton.icon(
          onPressed: () => _showAddDiagnosisSheet(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Додати діагноз'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]);
  }

  Widget _diagnosisCard(Map<String, dynamic> rec) {
    final diagnosis = rec['diagnosis'] ?? '—';
    final createdAt = rec['createdAt'] ?? '';
    String dateStr = '—';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }
    final bp = rec['bloodPressure'];
    final hr = rec['heartRate'];
    final temp = rec['temperature'];
    final weight = rec['weight'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(diagnosis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        if (bp != null || hr != null || temp != null || weight != null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 6, children: [
            if (bp != null) _chip(Icons.favorite, '$bp мм рт.ст.', AppColors.danger),
            if (hr != null) _chip(Icons.monitor_heart, '$hr уд/хв', AppColors.success),
            if (temp != null) _chip(Icons.thermostat, '$temp °C', AppColors.warning),
            if (weight != null) _chip(Icons.scale, '$weight кг', AppColors.primary),
          ]),
        ],
      ]),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]);

  void _showAddDiagnosisSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddDiagnosisSheet(patientId: widget.patientId, onSaved: _load),
    );
  }
}

// ── Форма додавання діагнозу ──────────────────────────────────────────────
class _AddDiagnosisSheet extends StatefulWidget {
  final String patientId;
  final VoidCallback onSaved;
  const _AddDiagnosisSheet({required this.patientId, required this.onSaved});
  @override
  State<_AddDiagnosisSheet> createState() => _AddDiagnosisSheetState();
}

class _AddDiagnosisSheetState extends State<_AddDiagnosisSheet> {
  final _formKey = GlobalKey<FormState>();
  final _diagCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _diagCtrl.dispose(); _bpCtrl.dispose(); _hrCtrl.dispose();
    _tempCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post('/medical-records', data: {
        'patientId': widget.patientId,
        'diagnosis': _diagCtrl.text.trim(),
        if (_bpCtrl.text.isNotEmpty) 'bloodPressure': _bpCtrl.text.trim(),
        if (_hrCtrl.text.isNotEmpty) 'heartRate': int.tryParse(_hrCtrl.text.trim()),
        if (_tempCtrl.text.isNotEmpty) 'temperature': double.tryParse(_tempCtrl.text.trim()),
        if (_weightCtrl.text.isNotEmpty) 'weight': double.tryParse(_weightCtrl.text.trim()),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Діагноз збережено'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Center(child: Text('Новий діагноз', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _diagCtrl,
              maxLines: 2,
              decoration: _dec('Діагноз *', hint: 'МКХ-10 або опис'),
              validator: (v) => v == null || v.isEmpty ? "Обов'язкове поле" : null,
            ),
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerLeft,
                child: Text('ПОКАЗНИКИ (необов\'язково)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(controller: _bpCtrl, decoration: _dec('Тиск', hint: '120/80'), keyboardType: TextInputType.text)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _hrCtrl, decoration: _dec('Пульс', hint: '72'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: _tempCtrl, decoration: _dec('Темпер.', hint: '36.6'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _weightCtrl, decoration: _dec('Вага кг', hint: '75'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            ]),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
