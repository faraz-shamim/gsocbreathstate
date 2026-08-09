import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<PatientProvider>(
            builder: (context, provider, _) {
              return ContentContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad - 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Patients',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.person_add_rounded),
                            color: AppTheme.emerald,
                            onPressed:
                                () => _showPatientDialog(context, provider),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child:
                          provider.patients.isEmpty
                              ? const PremiumEmptyState(
                                icon: Icons.person_add_alt_1_rounded,
                                title: 'No patients yet',
                                message:
                                    'Add a patient profile before recording sessions.',
                              )
                              : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  hPad,
                                  8,
                                  hPad,
                                  Responsive.bottomListPadding(context),
                                ),
                                itemCount: provider.patients.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final patient = provider.patients[index];
                                  final isActive =
                                      patient.id == provider.activePatient?.id;
                                  final sex = patient.sex?.trim();
                                  final detailParts = <String>[
                                    if (patient.age != null)
                                      'Age ${patient.age}',
                                    if (sex != null && sex.isNotEmpty) sex,
                                    if (patient.heightCm != null)
                                      '${patient.heightCm!.toStringAsFixed(0)} cm',
                                    if (patient.resonanceFrequency != null)
                                      'RF: ${patient.resonanceFrequency!.toStringAsFixed(1)} BPM',
                                  ];

                                  return ScaleOnPress(
                                    scaleFactor: 0.985,
                                    haptic: PressHaptic.selection,
                                    onTap:
                                        isActive
                                            ? null
                                            : () async {
                                              await provider.setActivePatient(
                                                patient,
                                              );
                                            },
                                    child: GlassCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      color:
                                          isActive
                                              ? AppTheme.emerald.withValues(
                                                alpha: isDark ? 0.15 : 0.08,
                                              )
                                              : null,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                isActive
                                                    ? AppTheme.emerald
                                                    : (isDark
                                                        ? Colors.white24
                                                        : Colors.black12),
                                            radius: 20,
                                            child: Text(
                                              patient.name.isNotEmpty
                                                  ? patient.name[0]
                                                      .toUpperCase()
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
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  patient.name,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.labelLarge,
                                                ),
                                                if (detailParts.isNotEmpty)
                                                  Text(
                                                    detailParts.join(' / '),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.emerald,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isActive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.emerald
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppTheme.radiusXs,
                                                ),
                                              ),
                                              child: const Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.emerald,
                                                ),
                                              ),
                                            ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color:
                                                  isDark
                                                      ? Colors.white54
                                                      : Colors.black45,
                                              size: 20,
                                            ),
                                            onSelected: (val) async {
                                              switch (val) {
                                                case 'activate':
                                                  await provider
                                                      .setActivePatient(
                                                        patient,
                                                      );
                                                  break;
                                                case 'edit':
                                                  _showPatientDialog(
                                                    context,
                                                    provider,
                                                    existing: patient,
                                                  );
                                                  break;
                                                case 'delete':
                                                  _confirmDelete(
                                                    context,
                                                    provider,
                                                    patient,
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder:
                                                (_) => [
                                                  if (!isActive)
                                                    const PopupMenuItem(
                                                      value: 'activate',
                                                      child: Text('Set Active'),
                                                    ),
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('Edit'),
                                                  ),
                                                  if (patient.name != 'Self')
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text('Delete'),
                                                    ),
                                                ],
                                          ),
                                        ],
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
          ),
        ),
      ),
    );
  }

  void _showPatientDialog(
    BuildContext context,
    PatientProvider provider, {
    Patient? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl = TextEditingController(
      text: existing?.age?.toString() ?? '',
    );
    final heightCtrl = TextEditingController(
      text:
          existing?.heightCm == null
              ? ''
              : existing!.heightCm!.toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    const sexOptions = ['Female', 'Male', 'Other', 'Prefer not to say'];
    String? selectedSex =
        sexOptions.contains(existing?.sex) ? existing?.sex : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder:
              (ctx, setModalState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(existing != null ? 'Edit Patient' : 'Add Patient'),
                content: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ageCtrl,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: heightCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedSex,
                        hint: const Text('Not specified'),
                        decoration: const InputDecoration(labelText: 'Sex'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not specified'),
                          ),
                          ...sexOptions.map(
                            (sex) => DropdownMenuItem<String?>(
                              value: sex,
                              child: Text(sex),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() => selectedSex = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final ageText = ageCtrl.text.trim();
                      final age =
                          ageText.isEmpty ? null : int.tryParse(ageText);
                      if (ageText.isNotEmpty &&
                          (age == null || age < 0 || age > 130)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter an age between 0 and 130.'),
                          ),
                        );
                        return;
                      }

                      final heightText = heightCtrl.text.trim();
                      final height =
                          heightText.isEmpty
                              ? null
                              : double.tryParse(heightText);
                      if (heightText.isNotEmpty &&
                          (height == null || height < 30 || height > 260)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter height in centimeters between 30 and 260.',
                            ),
                          ),
                        );
                        return;
                      }

                      final notes = _emptyToNull(notesCtrl.text.trim());
                      if (existing != null) {
                        await provider.updatePatient(
                          existing.id,
                          name,
                          age: age,
                          sex: selectedSex,
                          heightCm: height,
                          notes: notes,
                        );
                      } else {
                        await provider.createPatient(
                          name,
                          age: age,
                          sex: selectedSex,
                          heightCm: height,
                          notes: notes,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(existing != null ? 'Save' : 'Add'),
                  ),
                ],
              ),
        );
      },
    );
  }

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  void _confirmDelete(
    BuildContext context,
    PatientProvider provider,
    Patient patient,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Patient?'),
            content: Text(
              'All sessions and data for "${patient.name}" will be '
              'permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dustyRose,
                ),
                onPressed: () async {
                  await provider.deletePatient(patient.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
