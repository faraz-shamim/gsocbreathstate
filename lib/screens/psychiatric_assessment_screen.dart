// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/psychometrics/psychometric_scales.dart';
import 'package:breath_state/services/psychometrics/scale_engine.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:breath_state/widgets/psychometric_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PsychiatricAssessmentScreen extends StatefulWidget {
  const PsychiatricAssessmentScreen({super.key});

  @override
  State<PsychiatricAssessmentScreen> createState() =>
      _PsychiatricAssessmentScreenState();
}

class _PsychiatricAssessmentScreenState
    extends State<PsychiatricAssessmentScreen> {
  PsychometricScaleType _selectedScale = PsychometricScaleType.phq9;
  final Map<int, int> _responses = {};
  final _administeredByCtrl = TextEditingController(text: 'Clinician');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  QuestionnaireDefinition get _definition => definitionForScale(_selectedScale);

  @override
  void dispose() {
    _administeredByCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setScale(PsychometricScaleType type) {
    if (type == _selectedScale) return;
    setState(() {
      _selectedScale = type;
      _responses.clear();
    });
  }

  Future<void> _save() async {
    final patient = context.read<PatientProvider>().activePatient;
    if (patient == null) {
      _showMessage('Select a patient before saving an assessment.');
      return;
    }
    if (!_definition.isComplete(_responses)) {
      _showMessage('Complete every item before scoring.');
      return;
    }

    setState(() => _saving = true);
    try {
      final result = _definition.score(_responses);
      await context.read<AppDatabase>().insertPsychometricEntry(
        patientId: patient.id,
        scaleType: result.scaleType.id,
        totalScore: result.totalScore,
        severityLevel: result.severityLabel,
        responsesJson: result.toResponsesJson(),
        administeredBy: _emptyToNull(_administeredByCtrl.text.trim()),
        requiresReview: result.requiresReview,
        notes: _emptyToNull(_notesCtrl.text.trim()),
      );
      if (!mounted) return;
      setState(() {
        _responses.clear();
        _notesCtrl.clear();
      });
      _showResultDialog(result);
    } catch (error) {
      if (mounted) _showMessage('Could not save assessment: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showResultDialog(QuestionnaireResult result) {
    final scoreColor = psychometricScoreColor(
      result.scaleType,
      result.totalScore,
      result.requiresReview,
    );
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('${result.scaleType.displayName} saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score ${result.totalScore}/${_definition.maxScore}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(result.severityLabel),
                if (result.flags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...result.flags.map(
                    (flag) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.priority_high_rounded,
                            color: AppTheme.coralRose,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(flag.detail)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);
    final patient = context.watch<PatientProvider>().activePatient;

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
          child:
              patient == null
                  ? const PremiumEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No active patient',
                    message: 'Select or create a patient before assessing.',
                  )
                  : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: _Header(patientName: patient.name),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: _AssessmentCard(
                              definition: _definition,
                              selectedScale: _selectedScale,
                              responses: _responses,
                              administeredByCtrl: _administeredByCtrl,
                              notesCtrl: _notesCtrl,
                              saving: _saving,
                              onScaleChanged: _setScale,
                              onResponseChanged: (item, value) {
                                setState(() => _responses[item] = value);
                              },
                              onSave: _save,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: _RecentAssessments(patientId: patient.id),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: Responsive.bottomListPadding(context),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  String? _emptyToNull(String value) => value.isEmpty ? null : value;
}

class _Header extends StatelessWidget {
  final String patientName;

  const _Header({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Assessments', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          patientName,
          style: AppTheme.luxuryItalic(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final QuestionnaireDefinition definition;
  final PsychometricScaleType selectedScale;
  final Map<int, int> responses;
  final TextEditingController administeredByCtrl;
  final TextEditingController notesCtrl;
  final bool saving;
  final ValueChanged<PsychometricScaleType> onScaleChanged;
  final void Function(int item, int value) onResponseChanged;
  final VoidCallback onSave;

  const _AssessmentCard({
    required this.definition,
    required this.selectedScale,
    required this.responses,
    required this.administeredByCtrl,
    required this.notesCtrl,
    required this.saving,
    required this.onScaleChanged,
    required this.onResponseChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                PsychometricScaleType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: selectedScale == type,
                    onSelected: (_) => onScaleChanged(type),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            definition.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${definition.subtitle} / ${definition.timeframe}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 18),
          ...definition.questions.map(
            (question) => _QuestionRow(
              question: question,
              options: definition.responseOptions,
              value: responses[question.number],
              onChanged: (value) => onResponseChanged(question.number, value),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: administeredByCtrl,
            decoration: const InputDecoration(
              labelText: 'Administered by',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Clinical notes',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon:
                  saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check_rounded),
              label: Text(saving ? 'Saving' : 'Score and Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final ScaleQuestion question;
  final List<ScaleResponseOption> options;
  final int? value;
  final ValueChanged<int> onChanged;

  const _QuestionRow({
    required this.question,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: isDark ? 0.22 : 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${question.number}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  return ChoiceChip(
                    label: Text('${option.value} ${option.label}'),
                    selected: value == option.value,
                    onSelected: (_) => onChanged(option.value),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentAssessments extends StatelessWidget {
  final int patientId;

  const _RecentAssessments({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final formatter = DateFormat('MMM d, y h:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Results',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<PsychometricEntry>>(
            stream: db.watchPsychometricEntriesForPatient(patientId),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const <PsychometricEntry>[];
              if (entries.isEmpty) {
                return Text(
                  'No assessments saved for this patient yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                );
              }
              return Column(
                children:
                    entries.take(6).map((entry) {
                      final type = PsychometricScaleType.fromId(
                        entry.scaleType,
                      );
                      final date =
                          DateTime.tryParse(entry.administeredAt) ??
                          DateTime.now();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: psychometricScoreColor(
                            type,
                            entry.totalScore,
                            entry.requiresReview,
                          ),
                          child: Text(
                            entry.totalScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          '${type.displayName} / ${entry.severityLevel}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(formatter.format(date)),
                        trailing:
                            entry.requiresReview
                                ? const Icon(
                                  Icons.priority_high_rounded,
                                  color: AppTheme.coralRose,
                                )
                                : null,
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
