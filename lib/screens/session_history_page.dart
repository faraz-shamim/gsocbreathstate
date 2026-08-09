import 'dart:convert';

import 'package:breath_state/screens/session_detail_page.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionHistoryPage extends StatefulWidget {
  final int patientId;
  const SessionHistoryPage({super.key, required this.patientId});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  List<SessionSummary> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppDatabase().getSessionSummaries(widget.patientId);
    if (mounted) {
      setState(() {
        _sessions = list;
        _loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    await AppDatabase().deleteSessionSummary(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.obsidian : AppTheme.ivory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Session History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body:
          _loading
              ? const PremiumLoadingState(
                title: 'Loading sessions',
                message: 'Fetching saved recordings for this patient.',
                icon: Icons.history_rounded,
                rows: 4,
              )
              : _sessions.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder:
                    (context, i) =>
                        _buildSessionRow(context, isDark, _sessions[i]),
              ),
    );
  }

  Widget _buildEmpty() {
    return const PremiumEmptyState(
      icon: Icons.history_rounded,
      title: 'No sessions yet',
      message: 'Complete a recording and the summary will appear here.',
    );
  }

  Widget _buildSessionRow(BuildContext context, bool isDark, SessionSummary s) {
    final startDt = DateTime.tryParse(s.startedAt);
    final dateStr =
        startDt != null ? DateFormat('MMM d, yyyy').format(startDt) : '-';
    final timeStr = startDt != null ? DateFormat('h:mm a').format(startDt) : '';
    final dur = Duration(seconds: s.durationSeconds);
    final durStr =
        dur.inMinutes > 0
            ? '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s'
            : '${dur.inSeconds}s';
    final ext = _decodeExtendedMetrics(s.extendedMetricsJson);
    final preciseRf = RfAssessmentHistorySummary.tryParse(ext);
    final chips = _sessionMetricChips(s, ext);

    return ScaleOnPress(
      scaleFactor: 0.985,
      haptic: PressHaptic.light,
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SessionDetailPage(summary: s)),
          ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(
                        alpha: isDark ? 0.15 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      preciseRf == null
                          ? Icons.monitor_heart_rounded
                          : Icons.science_rounded,
                      color: AppTheme.emerald,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preciseRf == null ? dateStr : 'Precise RF • $dateStr',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$timeStr  *  $durStr',
                          style: AppTheme.luxuryItalic(
                            fontSize: 11,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.3,
                      ),
                    ),
                    onPressed: () => _confirmDelete(context, s.id),
                    splashRadius: 18,
                    tooltip: 'Delete',
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    chips
                        .map(
                          (chip) => _chip(
                            context,
                            chip.icon,
                            chip.label,
                            chip.color,
                            isDark,
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _decodeExtendedMetrics(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  List<_HistoryMetricChip> _sessionMetricChips(
    SessionSummary s,
    Map<String, dynamic> ext,
  ) {
    final psych =
        ext['psych'] is Map<String, dynamic>
            ? ext['psych'] as Map<String, dynamic>
            : const <String, dynamic>{};

    final chips = <_HistoryMetricChip>[];
    final preciseRf = RfAssessmentHistorySummary.tryParse(ext);
    if (preciseRf != null) {
      if (preciseRf.rfBpm != null) {
        chips.add(
          _HistoryMetricChip(
            Icons.tune_rounded,
            'RF ${preciseRf.rfBpm!.toStringAsFixed(2)} bpm',
            AppTheme.emerald,
          ),
        );
      }
      chips.add(
        _HistoryMetricChip(
          preciseRf.mode == 'measured'
              ? Icons.sensors_rounded
              : Icons.calculate_rounded,
          preciseRf.mode == 'measured' ? 'Measured' : 'Estimated',
          preciseRf.mode == 'measured' ? AppTheme.clinicalTeal : Colors.amber,
        ),
      );
      chips.add(
        _HistoryMetricChip(
          preciseRf.qualityPassed
              ? Icons.verified_rounded
              : Icons.warning_amber_rounded,
          preciseRf.qualityPassed ? 'Quality passed' : 'Quality warnings',
          preciseRf.qualityPassed ? AppTheme.emerald : Colors.amber,
        ),
      );
      final applicationLabel =
          preciseRf.appliedToPatient
              ? 'Applied'
              : preciseRf.rolloutStage == 'validation'
              ? 'Not applied'
              : preciseRf.mode == 'estimated' &&
                  preciseRf.estimateConfirmed == null
              ? 'Confirmation required'
              : 'Not applied';
      chips.add(
        _HistoryMetricChip(
          preciseRf.appliedToPatient
              ? Icons.check_circle_rounded
              : Icons.info_outline_rounded,
          applicationLabel,
          preciseRf.appliedToPatient ? AppTheme.emerald : Colors.amber,
        ),
      );
      if (preciseRf.rolloutStage == 'validation') {
        chips.add(
          const _HistoryMetricChip(
            Icons.fact_check_rounded,
            'Validation only',
            Colors.blueGrey,
          ),
        );
      } else if (preciseRf.protocolConformancePassed == false) {
        chips.add(
          const _HistoryMetricChip(
            Icons.gpp_bad_rounded,
            'Integrity failed',
            Colors.redAccent,
          ),
        );
      }
      return chips;
    }
    if (s.avgHeartRate != null) {
      final unit = _historyUnitForKey('heartRate');
      chips.add(
        _HistoryMetricChip(
          Icons.favorite_rounded,
          'Avg HR ${s.avgHeartRate!.toStringAsFixed(0)} $unit',
          AppTheme.dustyRose,
        ),
      );
    }
    if (s.breathRate != null) {
      final unit = _historyUnitForKey('breathRate');
      chips.add(
        _HistoryMetricChip(
          Icons.air_rounded,
          'Breath ${s.breathRate} $unit',
          AppTheme.emerald,
        ),
      );
    }
    final stress = _metric(psych, ['stressIndex', 'PSY_Baevsky_SI']);
    if (stress != null) {
      chips.add(
        _HistoryMetricChip(
          Icons.psychology_alt_rounded,
          'Stress Index ${stress.toStringAsFixed(0)}',
          AppTheme.coralRose,
        ),
      );
    }

    return chips;
  }

  String _historyUnitForKey(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('pnn') ||
        lower.contains('relative') ||
        lower.contains('confidence') ||
        lower.contains('amo')) {
      return '%';
    }
    if (lower.contains('breathrate') ||
        lower.contains('heart') ||
        lower.endsWith('bpm')) {
      return 'bpm';
    }
    if (lower.contains('peak')) return 'Hz';
    if (lower.contains('power') || lower == 'hrv_tp') return 'ms^2';
    if (lower.contains('nn') ||
        lower.contains('rmssd') ||
        lower.contains('sdsd') ||
        lower.contains('tinn') ||
        lower.contains('mo') ||
        lower.contains('mxdmn')) {
      return 'ms';
    }
    if (lower.contains('tone') || lower.contains('relaxation')) return '/100';
    return '';
  }

  double? _metric(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num && value.isFinite) return value.toDouble();
    }
    return null;
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Session?'),
            content: const Text(
              'This will permanently remove this session record.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _delete(id);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: AppTheme.coralRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _HistoryMetricChip {
  final IconData icon;
  final String label;
  final Color color;

  const _HistoryMetricChip(this.icon, this.label, this.color);
}
