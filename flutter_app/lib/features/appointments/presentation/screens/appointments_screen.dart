import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/appointments_bloc.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'new_appointment_screen.dart';
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AppointmentsBloc(repository: AppointmentsRepository()),
                child: const NewAppointmentScreen(),
              ),
            )),
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
              onRefresh: () async => context.read<AppointmentsBloc>().add(AppointmentsLoadRequested()),
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

  Widget _appointmentCard(dynamic a) {
    final statusColor = a.status == 'scheduled' ? AppColors.primary : a.status == 'completed' ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('${a.doctorSpec} • ${a.reasonLabel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(a.timeStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
