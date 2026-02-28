import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../state/dashboard_bloc.dart';

class LogOverlay extends StatelessWidget {
  const LogOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SYSTEM_LOGS', style: GoogleFonts.firaCode(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                    Icon(Icons.terminal, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.logs.length,
                  itemBuilder: (context, index) {
                    final log = state.logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: GoogleFonts.firaCode(
                          color: log.contains('EVENT') ? AppColors.secondary : (log.contains('CALC') ? AppColors.primary : AppColors.textMuted),
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
