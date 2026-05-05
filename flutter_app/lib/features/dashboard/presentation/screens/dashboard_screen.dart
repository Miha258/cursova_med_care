import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
// ignore_for_file: unused_import
import '../bloc/dashboard_bloc.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';

// Рис. 2.3б — Головний екран (Dashboard)
class DashboardScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => context.read<DashboardBloc>().add(DashboardLoadRequested()),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            SliverToBoxAdapter(child: _buildUpcomingSection(context)),
          ],
        ),
      ),
      bottomNavigationBar: MedCareBottomNav(currentIndex: 0, onTap: widget.onNavigate),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Доброго ранку, 👋', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    user != null ? 'Д-р ${user.shortName}' : 'MedCare CRM',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Row(children: [
                IconButton(
                  onPressed: () => context.read<DashboardBloc>().add(DashboardLoadRequested()),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Оновити',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Вийти',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 18),
          // Stats 2×2 grid
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoaded) {
                final s = state.stats;
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _statCard('${s.appointmentsToday}', 'Прийомів сьогодні'),
                    _statCard('${s.newPatientsToday}', 'Нових пацієнтів'),
                    _statCard('${s.activePatients}', 'Активних пацієнтів'),
                    _statCard('${s.occupancyPercent}%', 'Заповненість'),
                  ],
                );
              }
              return GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2,
                children: List.generate(4, (_) => _statCard('—', '...')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Вийти з акаунту?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Ви будете перенаправлені на екран входу.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
          ],
        ),
      );

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.person_add_outlined, label: 'Новий\nпацієнт', color: const Color(0xFFE3F2FD), navIndex: 2),
      _QuickAction(icon: Icons.calendar_today_outlined, label: 'Запис', color: const Color(0xFFFFF3E0), navIndex: 1),
      _QuickAction(icon: Icons.medication_outlined, label: 'Рецепт', color: const Color(0xFFFCE4EC), navIndex: null),
      _QuickAction(icon: Icons.folder_outlined, label: 'Картка', color: const Color(0xFFE8F5E9), navIndex: 2),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) => _buildActionItem(context, a)).toList(),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, _QuickAction a) => GestureDetector(
        onTap: () { if (a.navIndex != null) widget.onNavigate(a.navIndex!); },
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(16)),
              child: Icon(a.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(a.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildUpcomingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Найближчі прийоми', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
              TextButton(onPressed: () => widget.onNavigate(1), child: const Text('Усі →', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)));
              if (state is DashboardError) return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
              if (state is DashboardLoaded) {
                if (state.stats.upcomingAppointments.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Прийомів сьогодні немає')));
                }
                return Column(
                  children: state.stats.upcomingAppointments.map((a) => _appointmentCard(a)).toList(),
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _appointmentCard(dynamic a) => GestureDetector(
        onTap: () => widget.onNavigate(2),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                    Text(a.specialization, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                child: Text(a.time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final int? navIndex;
  const _QuickAction({required this.icon, required this.label, required this.color, this.navIndex});
}
