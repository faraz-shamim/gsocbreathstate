import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/services/ai/rf_predictor.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuickRfAssessmentScreen extends StatefulWidget {
  const QuickRfAssessmentScreen({super.key});

  @override
  State<QuickRfAssessmentScreen> createState() =>
      _QuickRfAssessmentScreenState();
}

class _QuickRfAssessmentScreenState extends State<QuickRfAssessmentScreen> {
  RfPredictionResult? _result;
  int? _resultPatientId;
  String? _inputError;
  bool _isSaving = false;
  bool _isSaved = false;

  void _estimate() {
    final patient = context.read<PatientProvider>().activePatient;
    if (patient == null) return;

    try {
      final result = RfPredictor().predict(
        RfPredictionInput(sex: patient.sex, heightCm: patient.heightCm),
      );
      setState(() {
        _result = result;
        _resultPatientId = patient.id;
        _inputError = null;
        _isSaved = false;
      });
    } on RfPredictionInputException catch (error) {
      setState(() {
        _result = null;
        _resultPatientId = null;
        _inputError = error.message;
        _isSaved = false;
      });
    }
  }

  Future<void> _saveEstimate() async {
    final patient = context.read<PatientProvider>().activePatient;
    final result = _result;
    if (patient == null ||
        result == null ||
        _resultPatientId != patient.id ||
        _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<PatientProvider>().updateResonanceFrequency(
        patient.id,
        result.estimatedBpm,
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasuo RF estimate saved to the patient profile.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the RF estimate: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);
    final patient = context.watch<PatientProvider>().activePatient;
    final visibleResult =
        patient != null && _resultPatientId == patient.id ? _result : null;

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
                    message: 'Select a patient before the quick RF estimate.',
                  )
                  : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quick RF Estimate',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        patient.name,
                                        style: AppTheme.luxuryItalic(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: _FormulaCard(
                              patient: patient,
                              error: _inputError,
                              onEstimate: _estimate,
                            ),
                          ),
                        ),
                      ),
                      if (visibleResult != null)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                          sliver: SliverToBoxAdapter(
                            child: ContentContainer(
                              child: _ResultCard(
                                result: visibleResult,
                                isSaving: _isSaving,
                                isSaved: _isSaved,
                                onSave: _saveEstimate,
                              ),
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
}

class _FormulaCard extends StatelessWidget {
  final Patient patient;
  final String? error;
  final VoidCallback onEstimate;

  const _FormulaCard({
    required this.patient,
    required this.error,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final formulaSex = HasuoFormulaSex.tryParse(patient.sex);
    final height = patient.heightCm;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasuo et al. Model',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Uses only sex and height. ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _InputRow(
            label: 'Sex',
            value: formulaSex?.displayName ?? patient.sex ?? 'Not specified',
            isValid: formulaSex != null,
          ),
          const SizedBox(height: 8),
          _InputRow(
            label: 'Height',
            value:
                height == null ? 'Not specified' : '${_heightText(height)} cm',
            isValid: height != null && height.isFinite && height > 0,
          ),
          const SizedBox(height: 16),
          Text(
            'Male: 17.90 − 0.07 × height(cm)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Female: 15.88 − 0.06 × height(cm)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppTheme.coralRose,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(error!)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEstimate,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate estimate'),
            ),
          ),
        ],
      ),
    );
  }

  static String _heightText(double height) {
    final rounded = height.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }
}

class _InputRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isValid;

  const _InputRow({
    required this.label,
    required this.value,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          size: 18,
          color: isValid ? AppTheme.emerald : AppTheme.coralRose,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RfPredictionResult result;
  final bool isSaving;
  final bool isSaved;
  final VoidCallback onSave;

  const _ResultCard({
    required this.result,
    required this.isSaving,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated RF',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.estimatedBpm.toStringAsFixed(2)} BPM',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.emerald,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...result.warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.coralRose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  isSaving || isSaved ? null : onSave,
              icon:
                  isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        isSaved
                            ? Icons.check_circle_rounded
                            : Icons.save_outlined,
                      ),
              label: Text(
                isSaving
                    ? 'Saving'
                    : isSaved
                    ? 'Estimate saved'
                    : 'Save estimate to patient',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Precise RF Assessment when a physiologically measured RF is '
            'required.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
