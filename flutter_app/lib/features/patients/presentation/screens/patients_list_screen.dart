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
      builder: (_) => const _AddPatientSheet(),
    );
  }
}

class _AddPatientSheet extends StatelessWidget {
  const _AddPatientSheet();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Новий пацієнт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('Форма реєстрації нового пацієнта.\nPOST /patients → PostgreSQL INSERT', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Закрити')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
