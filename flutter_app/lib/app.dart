import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'package:medcare_crm/core/utils/ui_utils.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/patients/presentation/bloc/patients_bloc.dart';
import 'features/patients/presentation/screens/patients_list_screen.dart';
import 'features/appointments/presentation/bloc/appointments_bloc.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
import 'features/appointments/data/repositories/appointments_repository.dart';

class MedCareApp extends StatelessWidget {
  const MedCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckRequested())),
      ],
      child: MaterialApp(
        title: 'MedCare CRM',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: UiUtils.messengerKey,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(
                backgroundColor: AppColors.primary,
                body: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            if (state is AuthAuthenticated) {
              return const HomeShell();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

// Головна оболонка з bottom navigation (після авторизації)
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _onNavigate(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardBloc()),
        BlocProvider(create: (_) => PatientsBloc()),
        BlocProvider(create: (_) => AppointmentsBloc(repository: AppointmentsRepository())),
      ],
      child: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onNavigate: _onNavigate),
          AppointmentsScreen(onNavigate: _onNavigate),
          PatientsListScreen(onNavigate: _onNavigate),
        ],
      ),
    );
  }
}
