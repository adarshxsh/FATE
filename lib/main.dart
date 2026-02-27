import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'data/repository/backend_repository.dart';
import 'data/repository/local_metrics_repository.dart';
import 'domain/controllers/telemetry_controller.dart';
import 'presentation/state/auth_bloc.dart';
import 'presentation/state/dashboard_bloc.dart';
import 'presentation/screens/auth/google_login_screen.dart';
import 'presentation/screens/dashboard/attention_dashboard.dart';
import 'presentation/widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localRepo = LocalMetricsRepository();
  await localRepo.init();

  runApp(FateApp(localMetricsRepository: localRepo));
}

class FateApp extends StatelessWidget {
  final LocalMetricsRepository localMetricsRepository;

  const FateApp({Key? key, required this.localMetricsRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backendRepo = BackendRepository();
    final telemetryController = TelemetryController()..initialize();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(backendRepo)..add(AuthCheckStatus())),
        BlocProvider(create: (_) => DashboardBloc(telemetryController)),
      ],
      child: MaterialApp(
        title: 'FATE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainNavigator();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const GoogleLoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      },
    );
  }
}
