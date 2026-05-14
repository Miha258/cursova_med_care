import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../bloc/patients_bloc.dart';
import '../../data/models/prescription_model.dart';
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
  final _tabs = ['Картки', 'Прийоми', 'Рецепти', 'Аналізи', 'Діагнози'];
  Map<String, dynamic>? _latestRecord;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    final patientsBloc = context.read<PatientsBloc>();
    patientsBloc.add(PatientLoadRequested(widget.patientId));
    patientsBloc.add(PatientPrescriptionsRequested(widget.patientId));
    _loadLatestRecord();
  }

  Future<void> _loadLatestRecord() async {
    try {
      final r = await ApiService.instance.get('/medical-records', queryParameters: {'patientId': widget.patientId});
      final list = List<Map<String, dynamic>>.from(r.data);
      if (list.isNotEmpty && mounted) {
        setState(() => _latestRecord = list.last);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<PatientsBloc>().add(PatientLoadRequested(widget.patientId));
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
            return Builder(
              builder: (ctx) => Scaffold(
                backgroundColor: AppColors.background,
                body: NestedScrollView(
                  headerSliverBuilder: (ctx, _) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 220,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                      title: const Text('Картка пацієнта', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                          padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
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
                      _buildCardTab(ctx, p),
                      _buildAppointmentsTab(ctx, p.id, p.fullName),
                      _MedicationsTab(patientId: p.id),
                      _LabTestsTab(patientId: p.id),
                      _buildDiagnosesTab(ctx, p.id),
                    ],
                  ),
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
  Widget _buildCardTab(BuildContext ctx, dynamic p) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildActionButtons(ctx, p),
          const SizedBox(height: 16),
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
                _vitalCard(_latestRecord?['bloodPressure'] ?? '—', 'мм рт.ст.', 'Тиск', AppColors.danger),
                _vitalCard(_latestRecord?['heartRate']?.toString() ?? '—', 'уд/хв', 'Пульс', AppColors.success),
              ],
            ),
          ]),
        ]),
      );

  // ── Вкладка "Прийоми" ───────────────────────────────────────────────────
  Widget _buildAppointmentsTab(BuildContext ctx, String patientId, String patientName) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoading) return const Center(child: CircularProgressIndicator());
        if (state is AppointmentsLoaded) {
          if (state.appointments.isEmpty) return _emptyState(Icons.event_note, 'Прийомів немає', 'Сплануйте перший візит пацієнта');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _appointmentCard(state.appointments[i]),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _appointmentCard(dynamic app) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.event_available, color: AppColors.primary, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${app.startTime.day.toString().padLeft(2,'0')}.${app.startTime.month.toString().padLeft(2,'0')}.${app.startTime.year}  ${app.timeStr}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(app.reasonLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ])),
        Text(app.status, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  void _showAddPrescriptionSheet(BuildContext ctx, String patientId, {PrescriptionModel? prescription}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: ctx.read<PatientsBloc>(),
        child: _AddPrescriptionSheet(patientId: patientId, prescription: prescription),
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

  Widget _sectionCard({required String title, required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _infoRow(String label, String value, {bool isDanger = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDanger ? AppColors.danger : AppColors.text))),
        ]),
      );

  Widget _vitalCard(String value, String unit, String label, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6))),
          ]),
        ]),
      );

  // ignore: unused_element
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

// ── Вкладка "Препарати" ──────────────────────────────────────────────────
class _MedicationsTab extends StatefulWidget {
  final String patientId;
  const _MedicationsTab({required this.patientId});
  @override State<_MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<_MedicationsTab> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.instance.get('/medications');
      final list = List<Map<String, dynamic>>.from(r.data);
      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? _all
          : _all.where((m) => (m['name'] as String).toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  Future<void> _deleteMed(Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити препарат?'),
        content: Text('«${m['name']}» буде назавжди видалено з бази.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.delete('/medications/${m['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Препарат «${m['name']}» видалено'), backgroundColor: AppColors.success));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Column(children: [
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Пошук препарату...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showAddMedSheet(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
      Expanded(
        child: _filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_pharmacy_outlined, size: 56, color: AppColors.border),
                const SizedBox(height: 12),
                Text(_query.isEmpty ? 'Препаратів немає' : 'Нічого не знайдено',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                if (_query.isEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddMedSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Додати препарат'),
                  ),
                ],
              ]))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _medCard(context, _filtered[i]),
                ),
              ),
      ),
    ]);
  }

  Widget _medCard(BuildContext ctx, Map<String, dynamic> m) {
    final qty = int.tryParse(m['quantity']?.toString() ?? '0') ?? 0;
    final minQty = int.tryParse(m['minQuantity']?.toString() ?? '0') ?? 0;
    final isLow = qty <= minQty;
    final price = double.tryParse(m['price']?.toString() ?? '0') ?? 0.0;
    final unit = m['unit'] ?? 'таб.';
    final name = m['name'] ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        border: isLow ? Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1) : null,
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: isLow ? AppColors.warning.withValues(alpha: 0.12) : const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_pharmacy_rounded,
              color: isLow ? AppColors.warning : const Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, children: [
            _badge('$qty $unit', isLow ? AppColors.warning : AppColors.success),
            _badge('${price.toStringAsFixed(0)} грн', AppColors.primary),
            if (isLow) _badge('⚠ Мало', AppColors.warning),
          ]),
        ])),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            onPressed: () => _prescribeSheet(ctx, m),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            child: const Text('Рецепт'),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _deleteMed(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text('Видалити', style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  void _prescribeSheet(BuildContext ctx, Map<String, dynamic> med) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: ctx.read<PatientsBloc>(),
        child: _AddPrescriptionSheet(patientId: widget.patientId, prefillMedication: med['name'] ?? ''),
      ),
    );
  }

  void _showAddMedSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMedicationSheet(onSaved: _load),
    );
  }
}

// ── Форма додавання препарату ─────────────────────────────────────────────
class _AddMedicationSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddMedicationSheet({required this.onSaved});
  @override State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String _unit = 'таб.';
  bool _saving = false;

  final _units = ['таб.', 'капс.', 'мл', 'амп.', 'фл.', 'шт.'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _minQtyCtrl.dispose();
    _priceCtrl.dispose(); _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post('/medications', data: {
        'name': _nameCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text.trim()) ?? 0,
        'minQuantity': int.tryParse(_minQtyCtrl.text.trim()) ?? 0,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'unit': _unit,
        if (_expiryCtrl.text.isNotEmpty) 'expiryDate': _expiryCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Препарат додано'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
      }
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
            const Center(child: Text('Новий препарат', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: _dec('Назва препарату *', hint: 'напр. Парацетамол 500мг'),
              validator: (v) => v == null || v.isEmpty ? "Обов'язкове поле" : null,
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Кількість *', hint: '100'),
                validator: (v) => v == null || v.isEmpty ? 'Введіть кількість' : null,
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: _dec('Одиниця'),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) { if (v != null) setState(() => _unit = v); },
              )),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: TextFormField(
                controller: _minQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Мін. залишок', hint: '20'),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Ціна (грн)', hint: '45.50'),
              )),
            ]),
            const SizedBox(height: 12),

            TextFormField(
              controller: _expiryCtrl,
              decoration: _dec('Термін придатності', hint: '2027-12-31'),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Додати препарат', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

// ── Вкладка "Аналізи" ───────────────────────────────────────────────────
class _LabTestsTab extends StatefulWidget {
  final String patientId;
  const _LabTestsTab({required this.patientId});
  @override State<_LabTestsTab> createState() => _LabTestsTabState();
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
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
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

    // Мапа статусів для відображення
    final statusMap = {
      'pending': {'label': 'Очікується', 'color': AppColors.primary},
      'normal': {'label': 'Норма', 'color': AppColors.success},
      'abnormal': {'label': 'Відхилення', 'color': AppColors.danger},
    };

    final displayStatus = statusMap[status.toLowerCase()] ?? {'label': status, 'color': AppColors.textSecondary};

    String dateStr = '—';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Результат: $result', style: const TextStyle(fontSize: 13)),
          if (status.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (displayStatus['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(displayStatus['label'] as String, style: TextStyle(color: displayStatus['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
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

// ── Форма додавання аналізу ──────────────────────────────────────────────
class _AddLabTestSheet extends StatefulWidget {
  final String patientId;
  final VoidCallback onSaved;
  const _AddLabTestSheet({required this.patientId, required this.onSaved});
  @override State<_AddLabTestSheet> createState() => _AddLabTestSheetState();
}

class _AddLabTestSheetState extends State<_AddLabTestSheet> {
  final _nameCtrl = TextEditingController();
  final _resCtrl = TextEditingController();
  bool _saving = false;

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Новий аналіз', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: _dec('Назва аналізу')),
        const SizedBox(height: 12),
        TextField(controller: _resCtrl, decoration: _dec('Результат')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: _saving ? null : () async {
            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _saving = true);
            try {
              await ApiService.instance.post('/lab-tests', data: {
                'patientId': widget.patientId,
                'testName': _nameCtrl.text.trim(),
                'result': _resCtrl.text.trim(),
                'status': 'normal',
              });
              if (mounted) { nav.pop(); widget.onSaved(); }
            } catch (e) {
              if (mounted) messenger.showSnackBar(SnackBar(content: Text('Помилка: $e')));
            }
            if (mounted) setState(() => _saving = false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Зберегти'),
        )),
      ]),
    );
  }
}

// ── Вкладка "Діагнози" (детальна реалізація) ─────────────────────────────
class _DiagnosesTab extends StatefulWidget {
  final String patientId;
  const _DiagnosesTab({required this.patientId});
  @override State<_DiagnosesTab> createState() => _DiagnosesTabState();
}

class _DiagnosesTabState extends State<_DiagnosesTab> {
  List<Map<String, dynamic>> _diagnoses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.instance.get('/medical-records', queryParameters: {'patientId': widget.patientId});
      if (mounted) setState(() { _diagnoses = List<Map<String, dynamic>>.from(r.data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return Column(children: [
      Expanded(
        child: _diagnoses.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.assignment_outlined, size: 56, color: AppColors.border),
                SizedBox(height: 16),
                Text('Діагнозів немає', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Text('Натисніть «+» щоб додати', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _diagnoses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _diagnosisCard(_diagnoses[i]),
              ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: ElevatedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _AddDiagnosisSheet(patientId: widget.patientId, onSaved: _load),
          ),
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

  Widget _diagnosisCard(Map<String, dynamic> d) {
    final bp = d['bloodPressure'];
    final hr = d['heartRate'];
    final temp = d['temperature'];
    final weight = d['weight'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_hospital, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(d['diagnosis'] ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Text(d['createdAt']?.substring(0, 10) ?? '—', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        if (bp != null || hr != null || temp != null || weight != null) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            if (bp != null) _chip(Icons.favorite, '$bp мм', AppColors.danger),
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
}

// ── Форма виписки рецепту ─────────────────────────────────────────────────
class _AddPrescriptionSheet extends StatefulWidget {
  final String patientId;
  final PrescriptionModel? prescription;
  final String prefillMedication;
  const _AddPrescriptionSheet({required this.patientId, this.prescription, this.prefillMedication = ''});
  @override
  State<_AddPrescriptionSheet> createState() => _AddPrescriptionSheetState();
}

class _AddPrescriptionSheetState extends State<_AddPrescriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _instCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.prescription != null;
    _nameCtrl = TextEditingController(
      text: _isEditing ? widget.prescription!.medicationName : widget.prefillMedication,
    );
    _dosageCtrl = TextEditingController(text: _isEditing ? widget.prescription!.dosage : '');
    _instCtrl = TextEditingController(text: _isEditing ? widget.prescription!.instruction : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _dosageCtrl.dispose(); _instCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'patientId': widget.patientId,
      'medicationName': _nameCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim(),
      'instruction': _instCtrl.text.trim(),
    };
    if (_isEditing) {
      context.read<PatientsBloc>().add(PatientPrescriptionUpdateRequested(widget.prescription!.id, data));
    } else {
      context.read<PatientsBloc>().add(PatientPrescriptionCreateRequested(data));
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEditing ? '✅ Рецепт оновлено' : '✅ Рецепт виписано'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_isEditing ? 'Редагувати рецепт' : 'Новий рецепт', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),
        Form(key: _formKey, child: Column(children: [
          TextField(controller: _nameCtrl, decoration: _dec('Назва препарату', hint: 'Напр. Парацетамол')),
          const SizedBox(height: 16),
          TextField(controller: _dosageCtrl, decoration: _dec('Дозування', hint: 'Напр. 1 таб 2р/день')),
          const SizedBox(height: 16),
          TextField(controller: _instCtrl, maxLines: 2, decoration: _dec('Інструкція (опціонально)')),
        ])),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(_isEditing ? 'Зберегти зміни' : 'Виписати рецепт', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );
}

// ── Action buttons (2×2 grid) ─────────────────────────────────────────────
extension on _PatientCardScreenState {
  Widget _buildActionButtons(BuildContext ctx, dynamic p) {
    return Column(children: [
      Row(children: [
        Expanded(child: _actionCard(
          icon: Icons.calendar_month_rounded,
          label: 'Записати\nна прийом',
          color: const Color(0xFF3B82F6),
          onTap: () {
            final bloc = ctx.read<AppointmentsBloc>();
            Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => BlocProvider.value(value: bloc,
                child: NewAppointmentScreen(patientId: p.id, patientName: p.fullName)),
            ));
          },
        )),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(
          icon: Icons.local_pharmacy_rounded,
          label: 'Рецепти',
          color: const Color(0xFFEC4899),
          onTap: () => _tabController.animateTo(2),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _actionCard(
          icon: Icons.biotech_rounded,
          label: 'Аналізи',
          color: const Color(0xFFF59E0B),
          onTap: () => _tabController.animateTo(3),
        )),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(
          icon: Icons.folder_shared_rounded,
          label: 'Картки',
          color: const Color(0xFF10B981),
          onTap: () => _tabController.animateTo(0),
        )),
      ]),
    ]);
  }

  Widget _actionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, height: 1.3)),
          ),
        ]),
      ),
    );
  }
}
