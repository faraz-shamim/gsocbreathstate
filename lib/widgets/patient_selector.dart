import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/screens/patient_list_screen.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

                                                                  
class PatientSelector extends StatelessWidget {
  const PatientSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        final name = provider.activePatient?.name ?? 'Select';
        final activeColor = isDark ? AppTheme.emerald : AppTheme.deepJade;

        return ScaleOnPress(
          onTap: () => _showPicker(context, provider),
          scaleFactor: 0.97,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 16, color: activeColor),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.62)
                          : const Color(0xFF475569),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context, PatientProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Switch Patient',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...provider.patients.map((patient) {
                  final isActive = patient.id == provider.activePatient?.id;

                  return ScaleOnPress(
                    scaleFactor: 0.985,
                    haptic: PressHaptic.selection,
                    onTap: () async {
                      await provider.setActivePatient(patient);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isActive
                                ? AppTheme.emerald
                                : (isDark ? Colors.white24 : Colors.black12),
                        radius: 18,
                        child: Text(
                          patient.name.isNotEmpty
                              ? patient.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color:
                                isActive
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black54),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(patient.name),
                      trailing:
                          isActive
                              ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.emerald,
                                size: 20,
                              )
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
    );
  }
}
