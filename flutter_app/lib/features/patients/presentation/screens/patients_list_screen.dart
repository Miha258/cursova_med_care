import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/patients_bloc.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'patient_card_screen.dart';

// Екран списку пацієнтів
class PatientsListScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const PatientsListScreen({super.key, required this.onNavigate});
  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PatientsBloc>().add(PatientsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Пацієнти', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddPatientDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocBuilder<PatientsBloc, PatientsState>(
              builder: (context, state) {
                if (state is PatientsLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                if (state is PatientsError) return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
                if (state is PatientsLoaded) {
                  if (state.patients.isEmpty) {
                    return const Center(child: Text('Пацієнтів не знайдено'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<PatientsBloc>().add(PatientsLoadRequested()),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.patients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _patientCard(context, state.patients[index]),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MedCareBottomNav(currentIndex: 2, onTap: widget.onNavigate),
    );
  }

  Widget _buildSearchBar() => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: TextField(
          controller: _searchController,
          onChanged: (q) {
            if (q.isEmpty) {
              context.read<PatientsBloc>().add(PatientsLoadRequested());
            } else {
              context.read<PatientsBloc>().add(PatientsSearchRequested(q));
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Пошук за ПІБ або полісом...',
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );

  Widget _patientCard(BuildContext context, dynamic patient) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<PatientsBloc>(), child: PatientCardScreen(patientId: patient.id))),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(
                    patient.lastName.isNotEmpty ? patient.lastName[0] : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 3),
                    Text('${patient.age} р. • ${patient.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (patient.allergies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text('⚠ Алергія', style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      );

  void _showAddPatientDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<PatientsBloc>(),
        child: const _AddPatientSheet(),
      ),
    );
  }
}

class _AddPatientSheet extends StatefulWidget {
  const _AddPatientSheet();
  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  String _bloodGroup = '';

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оберіть дату народження')));
      return;
    }
    context.read<PatientsBloc>().add(PatientCreateRequested({
      'lastName': _lastNameCtrl.text.trim(),
      'firstName': _firstNameCtrl.text.trim(),
      'middleName': _middleNameCtrl.text.trim(),
      'birthDate': _birthDate!.toIso8601String().split('T').first,
      'gender': _gender,
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      if (_bloodGroup.isNotEmpty) 'bloodGroup': _bloodGroup,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientsBloc, PatientsState>(
      listener: (context, state) {
        if (state is PatientCreated) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Пацієнта ${state.patient.fullName} додано'), backgroundColor: AppColors.success),
          );
        }
        if (state is PatientsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Center(child: Text('Новий пацієнт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                const SizedBox(height: 20),
                _field(_lastNameCtrl, 'Прізвище', required: true),
                const SizedBox(height: 12),
                _field(_firstNameCtrl, "Ім'я", required: true),
                const SizedBox(height: 12),
                _field(_middleNameCtrl, 'По батькові'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          _birthDate == null
                              ? 'Дата народження *'
                              : '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}',
                          style: TextStyle(color: _birthDate == null ? AppColors.textSecondary : AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Стать:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    _genderChip('male', 'Чоловіча'),
                    const SizedBox(width: 8),
                    _genderChip('female', 'Жіноча'),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_phoneCtrl, 'Телефон', hint: '+380XXXXXXXXX', keyboard: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _bloodGroup.isEmpty ? null : _bloodGroup,
                  decoration: _inputDecoration('Група крові (необов\'язково)'),
                  items: ['I(O)+', 'I(O)−', 'II(A)+', 'II(A)−', 'III(B)+', 'III(B)−', 'IV(AB)+', 'IV(AB)−']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
                ),
                const SizedBox(height: 20),
                BlocBuilder<PatientsBloc, PatientsState>(
                  builder: (context, state) {
                    final loading = state is PatientCreating;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String value, String label) => GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _gender == value ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gender == value ? AppColors.primary : AppColors.border),
          ),
          child: Text(label, style: TextStyle(color: _gender == value ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _field(TextEditingController ctrl, String label, {bool required = false, String? hint, TextInputType? keyboard}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: _inputDecoration(required ? '$label *' : label, hint: hint),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Обов'язкове поле" : null : null,
      );

  InputDecoration _inputDecoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );
}
