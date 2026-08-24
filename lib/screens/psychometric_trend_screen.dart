// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:convert';

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

class PsychometricTrendScreen extends StatefulWidget {
  const PsychometricTrendScreen({super.key});

  @override
  State<PsychometricTrendScreen> createState() =>
      _PsychometricTrendScreenState();
}

class _PsychometricTrendScreenState extends State<PsychometricTrendScreen> {
  PsychometricScaleType? _selectedScale;
  int? _patientId;
  Stream<List<PsychometricEntry>>? _psychometricStream;
  Stream<List<SessionSummary>>? _summaryStream;
  List<PsychometricEntry> _lastPsychometrics = const [];
  List<SessionSummary> _lastSummaries = const [];
  bool _hasLoadedPsychometrics = false;
  bool _hasLoadedSummaries = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final patientId = context.watch<PatientProvider>().activePatient?.id;
    if (patientId != _patientId) {
      _patientId = patientId;
      if (patientId == null) {
        _psychometricStream = null;
        _summaryStream = null;
        _lastPsychometrics = const [];
        _lastSummaries = const [];
        _hasLoadedPsychometrics = false;
        _hasLoadedSummaries = false;
      } else {
        final db = context.read<AppDatabase>();
        _psychometricStream = db.watchPsychometricEntriesForPatient(patientId);
        _summaryStream = db.watchSessionSummariesForPatient(patientId);
        _lastPsychometrics = const [];
        _lastSummaries = const [];
        _hasLoadedPsychometrics = false;
        _hasLoadedSummaries = false;
      }
    }
  }

  _TrendData _trendDataFromEntries(
    List<PsychometricEntry> psychometrics,
    List<SessionSummary> summaries,
  ) {
    return _TrendData(
      psychometricPoints:
          psychometrics.map((entry) {
            return PsychometricTrendPoint(
              timestamp:
                  DateTime.tryParse(entry.administeredAt) ?? DateTime.now(),
              scaleType: PsychometricScaleType.fromId(entry.scaleType),
              score: entry.totalScore,
              severity: entry.severityLevel,
              requiresReview: entry.requiresReview,
            );
          }).toList(),
      hrvPoints:
          summaries
              .map(_coherencePointFromSummary)
              .whereType<HrvCoherenceTrendPoint>()
              .toList(),
    );
  }

  HrvCoherenceTrendPoint? _coherencePointFromSummary(SessionSummary summary) {
    final date = DateTime.tryParse(summary.endedAt ?? summary.startedAt);
    if (date == null) return null;
    final score = _coherenceScoreFromSummary(summary);
    if (score == null) return null;
    return HrvCoherenceTrendPoint(timestamp: date, coherenceScore: score);
  }

  double? _coherenceScoreFromSummary(SessionSummary summary) {
    final raw = summary.extendedMetricsJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final biofeedback = decoded['biofeedback'];
      if (biofeedback is Map<String, dynamic>) {
        final coherence = biofeedback['coherenceScore'];
        if (coherence is num) {
          return coherence.toDouble().clamp(0, 100).toDouble();
        }
      }
      final rfCoherence = decoded['RF_Optimal_Coherence'];
      if (rfCoherence is num) {
        return (rfCoherence.toDouble() * 100).clamp(0, 100).toDouble();
      }
      final freq = decoded['freq'];
      if (freq is! Map<String, dynamic>) return null;
      final lf = freq['lfPower'];
      final hf = freq['hfPower'];
      if (lf is num && hf is num && lf + hf > 0) {
        return (lf / (lf + hf) * 100).clamp(0, 100).toDouble();
      }
      final ratio = freq['lfHfRatio'];
      if (ratio is num && ratio.isFinite && ratio >= 0) {
        return (ratio / (1 + ratio) * 100).clamp(0, 100).toDouble();
      }
    } catch (_) {}
    return null;
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
                    message: 'Select a patient to view longitudinal trends.',
                  )
                  : StreamBuilder<List<PsychometricEntry>>(
                    stream: _psychometricStream,
                    builder: (context, psychSnapshot) {
                      return StreamBuilder<List<SessionSummary>>(
                        stream: _summaryStream,
                        builder: (context, summarySnapshot) {
                          if (psychSnapshot.hasData) {
                            _lastPsychometrics = psychSnapshot.data!;
                            _hasLoadedPsychometrics = true;
                          }
                          if (summarySnapshot.hasData) {
                            _lastSummaries = summarySnapshot.data!;
                            _hasLoadedSummaries = true;
                          }

                          final waitingForPsychometrics =
                              !_hasLoadedPsychometrics &&
                              psychSnapshot.connectionState ==
                                  ConnectionState.waiting;
                          final waitingForSummaries =
                              !_hasLoadedSummaries &&
                              summarySnapshot.connectionState ==
                                  ConnectionState.waiting;
                          final data = _trendDataFromEntries(
                            _lastPsychometrics,
                            _lastSummaries,
                          );
                          final loading =
                              data.psychometricPoints.isEmpty &&
                              data.hrvPoints.isEmpty &&
                              (waitingForPsychometrics || waitingForSummaries);

                          return CustomScrollView(
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
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child:
                                          loading
                                              ? const PremiumLoadingState(
                                                title: 'Loading flowsheet',
                                                message:
                                                    'Preparing symptom and HRV trends.',
                                                icon: Icons.timeline_rounded,
                                                rows: 3,
                                              )
                                              : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      ChoiceChip(
                                                        label: const Text(
                                                          'All',
                                                        ),
                                                        selected:
                                                            _selectedScale ==
                                                            null,
                                                        onSelected:
                                                            (_) => setState(
                                                              () =>
                                                                  _selectedScale =
                                                                      null,
                                                            ),
                                                      ),
                                                      ...PsychometricScaleType
                                                          .values
                                                          .map((type) {
                                                            return ChoiceChip(
                                                              avatar: _ScaleDot(
                                                                color:
                                                                    scaleColor(
                                                                      type,
                                                                    ),
                                                              ),
                                                              label: Text(
                                                                type.displayName,
                                                              ),
                                                              selected:
                                                                  _selectedScale ==
                                                                  type,
                                                              onSelected:
                                                                  (
                                                                    _,
                                                                  ) => setState(
                                                                    () =>
                                                                        _selectedScale =
                                                                            type,
                                                                  ),
                                                            );
                                                          }),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _Legend(),
                                                  const SizedBox(height: 12),
                                                  PsychometricTrendChart(
                                                    scaleType: _selectedScale,
                                                    maxScaleScore:
                                                        _maxScaleScore(
                                                          data,
                                                          _selectedScale,
                                                        ),
                                                    psychometricPoints:
                                                        data.psychometricPoints,
                                                    hrvPoints: data.hrvPoints,
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                                sliver: SliverToBoxAdapter(
                                  child: ContentContainer(
                                    child: _LatestRows(
                                      data: data,
                                      loading: waitingForPsychometrics,
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
                          );
                        },
                      );
                    },
                  ),
        ),
      ),
    );
  }
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
        Text('Flowsheets', style: Theme.of(context).textTheme.displaySmall),
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

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendItem(color: AppTheme.clinicalCyan, label: 'PHQ-9'),
        _LegendItem(color: AppTheme.signalWarn, label: 'GAD-7'),
        _LegendItem(color: AppTheme.cardiacRose, label: 'PCL-5'),
        _LegendItem(color: AppTheme.emerald, label: 'HRV coherence'),
      ],
    );
  }
}

class _ScaleDot extends StatelessWidget {
  final Color color;

  const _ScaleDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _LatestRows extends StatelessWidget {
  final _TrendData data;
  final bool loading;

  const _LatestRows({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, y');
    final points = List<PsychometricTrendPoint>.from(data.psychometricPoints)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Assessments',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (points.isEmpty && loading)
            Text(
              'Loading latest assessments...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            )
          else if (points.isEmpty)
            Text(
              'No psychometric assessments have been saved yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            )
          else
            ...points
                .take(8)
                .map(
                  (point) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: psychometricScoreColor(
                        point.scaleType,
                        point.score,
                        point.requiresReview,
                      ),
                      child: Text(
                        point.score.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      '${point.scaleType.displayName} / ${point.severity}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(dateFormatter.format(point.timestamp)),
                  ),
                ),
        ],
      ),
    );
  }
}

class _TrendData {
  final List<PsychometricTrendPoint> psychometricPoints;
  final List<HrvCoherenceTrendPoint> hrvPoints;

  const _TrendData({required this.psychometricPoints, required this.hrvPoints});
}

int _maxScaleScore(_TrendData data, PsychometricScaleType? selectedScale) {
  if (selectedScale != null) {
    return definitionForScale(selectedScale).maxScore;
  }
  final usedScales =
      data.psychometricPoints.map((point) => point.scaleType).toSet();
  if (usedScales.isEmpty) {
    return PsychometricScaleType.values
        .map((type) => definitionForScale(type).maxScore)
        .reduce((a, b) => a > b ? a : b);
  }
  return usedScales
      .map((type) => definitionForScale(type).maxScore)
      .reduce((a, b) => a > b ? a : b);
}
