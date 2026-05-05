import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/patients_bloc.dart';
import '../../../appointments/presentation/screens/new_appointment_screen.dart';
import '../../../appointments/data/repositories/appointments_repository.dart';
import '../../../appointments/presentation/bloc/appointments_bloc.dart';

// Рис. 2.4а — Картка пацієнта
class PatientCardScreen extends StatefulWidget {
  final String patientId;
  const PatientCardScreen({super.key, required this.patientId});
  @override
  State<PatientCardScreen> createState() => _PatientCardScreenState();
}

class _PatientCardScreenState extends State<PatientCardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Картка', 'Прийоми', 'Рецепти', 'Аналізи'];

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
    return BlocBuilder<PatientsBloc, PatientsState>(
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
                  expandedHeight: 170,
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
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                            child: Center(
                              child: Text(p.lastName.isNotEmpty ? p.lastName[0] : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
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
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 5,
                                  children: [
                                    if (p.bloodGroup.isNotEmpty) _tag('${p.bloodGroup} гр. крові'),
                                    if (p.rhFactor.isNotEmpty) _tag('Rh${p.rhFactor}'),
                                    for (final a in p.allergies) _tag(a, isDanger: true),
                                  ],
                                ),
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
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildCardTab(p),
                  _buildPlaceholderTab('Прийоми', Icons.calendar_today_outlined),
                  _buildPlaceholderTab('Рецепти', Icons.medication_outlined),
                  _buildPlaceholderTab('Аналізи', Icons.science_outlined),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AppointmentsBloc(repository: AppointmentsRepository()),
                    child: NewAppointmentScreen(patientId: p.id, patientName: p.fullName),
                  ),
                )),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Записати на прийом'),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _tag(String text, {bool isDanger = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red.withOpacity(0.4) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  Widget _buildCardTab(dynamic p) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Personal data card
            _sectionCard(
              title: 'Особисті дані',
              children: [
                _infoRow('Страховий поліс', p.insuranceNo.isNotEmpty ? p.insuranceNo : '—'),
                _infoRow('Телефон', p.phone.isNotEmpty ? p.phone : '—'),
                _infoRow('Email', p.email.isNotEmpty ? p.email : '—'),
                if (p.allergies.isNotEmpty)
                  _infoRow('Алергії', p.allergies.join(', '), isDanger: true),
              ],
            ),
            const SizedBox(height: 12),
            // Vitals card (CustomPainter-like indicators)
            _sectionCard(
              title: "Показники здоров'я",
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                  children: [
                    _vitalCard('145/90', 'мм рт.ст.', 'Тиск', AppColors.danger),
                    _vitalCard('78', 'уд/хв', 'Пульс', AppColors.success),
                    _vitalCard('82', 'кг', 'Вага', AppColors.primary),
                    _vitalCard('36.6', '°C', 'Температура', AppColors.warning),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _sectionCard({required String title, required List<Widget> children}) => Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _infoRow(String key, String value, {bool isDanger = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDanger ? AppColors.danger : AppColors.text)),
          ],
        ),
      );

  Widget _vitalCard(String value, String unit, String label, Color color) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildPlaceholderTab(String name, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text('Розділ «$name»', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Завантаження через NestJS API...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
}
