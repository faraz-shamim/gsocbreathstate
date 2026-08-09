import 'dart:convert';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/hrv_analysis/fisher_lehrer/fisher_lehrer.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class SessionDetailPage extends StatelessWidget {
  final SessionSummary summary;
  const SessionDetailPage({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = summary;
    final startDt = DateTime.tryParse(s.startedAt);
    final dateStr =
        startDt != null ? DateFormat('MMM d, yyyy').format(startDt) : '-';
    final timeStr = startDt != null ? DateFormat('h:mm a').format(startDt) : '';
    final dur = Duration(seconds: s.durationSeconds);
    final durStr =
        dur.inMinutes > 0
            ? '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s'
            : '${dur.inSeconds}s';

    List<int> hrReadings = [];
    if (s.hrReadingsJson != null && s.hrReadingsJson!.isNotEmpty) {
      try {
        hrReadings =
            (jsonDecode(s.hrReadingsJson!) as List)
                .map((e) => (e as num).toInt())
                .toList();
      } catch (_) {}
    }

    Map<String, dynamic> ext = {};
    if (s.extendedMetricsJson != null && s.extendedMetricsJson!.isNotEmpty) {
      try {
        ext = jsonDecode(s.extendedMetricsJson!) as Map<String, dynamic>;
      } catch (_) {}
    }
    final preciseRf = RfAssessmentHistorySummary.tryParse(ext);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.obsidian : AppTheme.ivory,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          preciseRf == null ? 'Session Details' : 'Precise RF Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.emerald,
                          AppTheme.emerald.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$timeStr  *  $durStr',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (preciseRf != null) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Resonance Frequency Assessment'),
              const SizedBox(height: 8),
              _buildPreciseRf(context, isDark, preciseRf),
            ],

            if (hrReadings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Heart Rate Over Time'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HrGraphPainter(
                      readings: hrReadings,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ],

            if (preciseRf == null ||
                s.breathRate != null ||
                s.avgHeartRate != null) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Quick Summary'),
              const SizedBox(height: 8),
              _buildQuickSummary(context, isDark, s),
            ],

            if (s.rmssd != null || s.sdnn != null) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Time-Domain HRV'),
              const SizedBox(height: 8),
              _buildTimeDomainHrv(context, isDark, s, ext),
            ],

            if (ext.containsKey('freq')) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Frequency-Domain HRV'),
              const SizedBox(height: 8),
              _buildFreqDomain(
                context,
                isDark,
                ext['freq'] as Map<String, dynamic>,
              ),
            ],

            if (ext.containsKey('rsa')) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Respiratory Sinus Arrhythmia'),
              const SizedBox(height: 8),
              _buildRsa(context, isDark, ext['rsa'] as Map<String, dynamic>),
            ],

            if (ext.containsKey('psych')) ...[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Psychophysiological Indices'),
              const SizedBox(height: 8),
              _buildPsych(
                context,
                isDark,
                ext['psych'] as Map<String, dynamic>,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.emerald.withValues(alpha: 0.8),
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildPreciseRf(
    BuildContext context,
    bool isDark,
    RfAssessmentHistorySummary result,
  ) {
    final estimated = result.mode == 'estimated';
    final application =
        result.appliedToPatient
            ? estimated
                ? 'Applied with confirmation'
                : 'Applied automatically'
            : result.rolloutStage == 'validation'
            ? 'Not applied (validation only)'
            : estimated && result.estimateConfirmed == null
            ? 'Confirmation required'
            : 'Not applied';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metricTile(
                context,
                isDark,
                Icons.tune_rounded,
                'Resonance Frequency',
                result.rfBpm == null
                    ? 'Unavailable'
                    : '${result.rfBpm!.toStringAsFixed(2)} bpm',
                AppTheme.emerald,
                badge: estimated ? 'ESTIMATED' : 'MEASURED',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'Cardiac maximum',
                result.peakToTroughAmplitude == null
                    ? '-'
                    : '${result.peakToTroughAmplitude!.toStringAsFixed(1)} ms',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Scheduled breathing',
                result.scheduledBpmAtCenter == null
                    ? '-'
                    : '${result.scheduledBpmAtCenter!.toStringAsFixed(2)} bpm',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Measured breathing',
                result.fittedRespirationBpm == null
                    ? 'Not measured'
                    : '${result.fittedRespirationBpm!.toStringAsFixed(2)} bpm',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'Adherence delta',
                result.adherenceDeltaBpm == null
                    ? '-'
                    : '${result.adherenceDeltaBpm!.toStringAsFixed(2)} bpm',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Corrections',
                '${result.ectopicCorrections}',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Quality',
                result.qualityPassed ? 'Passed' : 'Warnings',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$application • ${result.surface.toUpperCase()} • '
            '${result.protocolVersion}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: result.appliedToPatient ? AppTheme.emerald : Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result.rolloutStage != null) ...[
            const SizedBox(height: 6),
            Text(
              'Release ${_labelFromKey(result.rolloutStage!)} • '
              'protocol integrity '
              '${result.protocolConformancePassed == true ? 'passed' : 'unavailable'}'
              '${result.protocolFingerprint == null ? '' : ' • ${result.protocolFingerprint}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (result.qualityFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.qualityFlags.map(
              (flag) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• ${_labelFromKey(flag)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSummary(
    BuildContext context,
    bool isDark,
    SessionSummary s,
  ) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              if (s.breathRate != null)
                _metricTile(
                  context,
                  isDark,
                  Icons.air_rounded,
                  'Breath Rate',
                  '${s.breathRate} bpm',
                  AppTheme.emerald,
                  badge: _breathSourceLabel(s.breathSource),
                ),
              if (s.breathRate != null && s.avgHeartRate != null)
                const SizedBox(width: 10),
              if (s.avgHeartRate != null)
                _metricTile(
                  context,
                  isDark,
                  Icons.favorite_rounded,
                  'Avg Heart Rate',
                  '${s.avgHeartRate!.toStringAsFixed(0)} bpm',
                  AppTheme.dustyRose,
                ),
            ],
          ),
          if (s.minHeartRate != null || s.maxHeartRate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (s.minHeartRate != null)
                  _statTile(context, isDark, 'Min HR', '${s.minHeartRate} bpm'),
                if (s.minHeartRate != null && s.maxHeartRate != null)
                  const SizedBox(width: 10),
                if (s.maxHeartRate != null)
                  _statTile(context, isDark, 'Max HR', '${s.maxHeartRate} bpm'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeDomainHrv(
    BuildContext context,
    bool isDark,
    SessionSummary s,
    Map<String, dynamic> ext,
  ) {
    final td =
        ext.containsKey('timeDomain')
            ? ext['timeDomain'] as Map<String, dynamic>
            : <String, dynamic>{};
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'RMSSD',
                '${(s.rmssd ?? td['rmssd'])?.toStringAsFixed(1) ?? '-'} ms',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'SDNN',
                '${(s.sdnn ?? td['sdnn'])?.toStringAsFixed(1) ?? '-'} ms',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Mean NN',
                '${(s.meanNn ?? td['meanNN'])?.toStringAsFixed(0) ?? '-'} ms',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'pNN50',
                '${(s.pnn50 ?? td['pnn50'])?.toStringAsFixed(1) ?? '-'}%',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'pNN20',
                '${td['pnn20']?.toStringAsFixed(1) ?? '-'}%',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'SDSD',
                '${td['sdsd']?.toStringAsFixed(1) ?? '-'} ms',
              ),
            ],
          ),
          if (td.containsKey('medianNN')) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _statTile(
                  context,
                  isDark,
                  'Median NN',
                  '${td['medianNN']?.toStringAsFixed(0) ?? '-'} ms',
                ),
                const SizedBox(width: 8),
                _statTile(
                  context,
                  isDark,
                  'HTI',
                  '${td['hti']?.toStringAsFixed(1) ?? '-'}',
                ),
                const SizedBox(width: 8),
                _statTile(
                  context,
                  isDark,
                  'TINN',
                  '${td['tinn']?.toStringAsFixed(1) ?? '-'} ms',
                ),
              ],
            ),
          ],
          ..._extraTimeDomainRows(context, isDark, td),
        ],
      ),
    );
  }

  Widget _buildFreqDomain(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> f,
  ) {
    final storedGroups = _storedMetricGroups(f['allMetrics']);
    if (storedGroups.isNotEmpty) {
      return _buildMetricGroupCard(context, isDark, storedGroups);
    }
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'LF Power',
                '${_fmtOpt(f['lfPower'])} ms^2',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'HF Power',
                '${_fmtOpt(f['hfPower'])} ms^2',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'LF/HF',
                _fmtOpt(f['lfHfRatio'], decimals: 2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'Total Power',
                '${_fmtOpt(f['totalPower'])} ms^2',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'VLF Power',
                '${_fmtOpt(f['vlfPower'])} ms^2',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'VHF Power',
                '${_fmtOpt(f['vhfPower'])} ms^2',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsa(BuildContext context, bool isDark, Map<String, dynamic> r) {
    final storedGroups = _storedMetricGroups(r['allMetrics']);
    if (storedGroups.isNotEmpty) {
      return _buildMetricGroupCard(context, isDark, storedGroups);
    }
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'HRV Breath Rate',
                '${_fmtOpt(r['hrvBreathRate'], decimals: 1)} BPM',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Confidence',
                _fmtOptPct(r['hrvBreathConfidence']),
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Porges-Bohrer',
                '${_fmtOpt(r['porgesBohrer'], decimals: 3)} ln(ms^2)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statTile(
                context,
                isDark,
                'P2T Mean',
                '${_fmtOpt(r['p2tMean'])} ms',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Gates Mean',
                '${_fmtOpt(r['gatesMean'], decimals: 3)} ln(ms^2)',
              ),
              const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                'Breath Cycles',
                '${r['breathCycleCount'] ?? '-'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPsych(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> p,
  ) {
    final storedGroups = _storedMetricGroups(p['allMetrics']);
    if (storedGroups.isNotEmpty) {
      return _buildMetricGroupCard(context, isDark, storedGroups);
    }
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              _psychTile(
                context,
                isDark,
                'Stress Index',
                _fmtOpt(p['stressIndex'], decimals: 0),
                p['stressLevel'] ?? '',
              ),
              const SizedBox(width: 8),
              _psychTile(
                context,
                isDark,
                'Relaxation',
                '${_fmtOpt(p['relaxationScore'], decimals: 0)}/100',
                p['relaxationLevel'] ?? '',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _psychTile(
                context,
                isDark,
                'Para. Tone',
                '${_fmtOpt(p['parasympatheticTone'], decimals: 0)}/100',
                p['parasympatheticLevel'] ?? '',
              ),
              const SizedBox(width: 8),
              _psychTile(
                context,
                isDark,
                'Autonomic Balance',
                _fmtOpt(p['autonomicBalance'], decimals: 2),
                p['autonomicLevel'] ?? '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _extraTimeDomainRows(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> td,
  ) {
    final displayed = {
      'HRV_RMSSD',
      'rmssd',
      'HRV_SDNN',
      'sdnn',
      'HRV_MeanNN',
      'meanNN',
      'HRV_pNN50',
      'pnn50',
      'pnn20',
      'sdsd',
      'medianNN',
      'hti',
      'tinn',
    };
    final metrics =
        td.entries
            .where((e) => !displayed.contains(e.key) && _isMetricValue(e.value))
            .map(
              (e) => _StoredMetric(
                _labelFromKey(e.key),
                e.value,
                _unitForKey(e.key),
              ),
            )
            .toList();
    if (metrics.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      ..._metricRows(context, isDark, metrics),
    ];
  }

  Widget _buildMetricGroupCard(
    BuildContext context,
    bool isDark,
    Map<String, List<_StoredMetric>> groups,
  ) {
    final visibleGroups = groups.map(
      (key, value) => MapEntry(
        key,
        value.where((metric) => _isMetricValue(metric.value)).toList(),
      ),
    )..removeWhere((_, metrics) => metrics.isEmpty);

    if (visibleGroups.isEmpty) {
      return GlassCard(
        child: Text(
          'No stored metrics',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.55,
            ),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in visibleGroups.entries) ...[
            if (visibleGroups.length > 1) ...[
              Text(
                group.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.emerald.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ..._metricRows(context, isDark, group.value),
            if (group.key != visibleGroups.keys.last)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  List<Widget> _metricRows(
    BuildContext context,
    bool isDark,
    List<_StoredMetric> metrics,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 3) {
      final chunk = metrics.skip(i).take(3).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < chunk.length; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              _statTile(
                context,
                isDark,
                chunk[j].label,
                _formatStoredMetric(chunk[j].value, chunk[j].unit),
              ),
            ],
            for (var j = chunk.length; j < 3; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ],
        ),
      );
      if (i + 3 < metrics.length) rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  Map<String, List<_StoredMetric>> _storedMetricGroups(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, List<_StoredMetric>>{};
    raw.forEach((group, metrics) {
      if (metrics is! List) return;
      result[group.toString()] =
          metrics
              .whereType<Map>()
              .map(
                (m) => _StoredMetric(
                  (m['label'] ?? '').toString(),
                  m['value'],
                  (m['unit'] ?? '').toString(),
                ),
              )
              .where((m) => m.label.isNotEmpty)
              .toList();
    });
    return result;
  }

  bool _isMetricValue(dynamic value) {
    if (value == null) return false;
    if (value is num) return value.isFinite;
    if (value is String) return value.trim().isNotEmpty;
    return false;
  }

  String _formatStoredMetric(dynamic value, String unit) {
    if (value == null) return '-';
    if (value is! num) return value.toString();
    final v = value.toDouble();
    if (!v.isFinite) return '-';
    final normalizedUnit = unit.toLowerCase();
    final decimals =
        normalizedUnit == 'hz'
            ? 3
            : normalizedUnit.contains('/100') ||
                normalizedUnit == '%' ||
                normalizedUnit == 'n.u.'
            ? 1
            : unit.isEmpty
            ? 2
            : 1;
    final suffix = unit.isEmpty ? '' : ' $unit';
    return '${v.toStringAsFixed(decimals)}$suffix';
  }

  String _labelFromKey(String key) {
    final stripped = key.replaceFirst(RegExp(r'^HRV_'), '');
    return stripped
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  }

  String _unitForKey(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('pnn') || lower.contains('relative')) return '%';
    if (lower.contains('peak')) return 'Hz';
    if (lower.contains('power') || lower == 'hrv_tp') return 'ms^2';
    if (lower.contains('nn') ||
        lower.contains('rmssd') ||
        lower.contains('sdann') ||
        lower.contains('sdnni') ||
        lower.contains('tinn')) {
      return 'ms';
    }
    return '';
  }

  Widget _metricTile(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color, {
    String? badge,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    bool isDark,
    String label,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(
            alpha: isDark ? 0.05 : 0.03,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _psychTile(
    BuildContext context,
    bool isDark,
    String label,
    String value,
    String interpretation,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(
            alpha: isDark ? 0.05 : 0.03,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (interpretation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                interpretation,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.emerald.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtOpt(dynamic v, {int decimals = 1}) {
    if (v == null) return '-';
    if (v is num) return v.toDouble().toStringAsFixed(decimals);
    return v.toString();
  }

  String _fmtOptPct(dynamic v) {
    if (v == null) return '-';
    if (v is num) return '${(v.toDouble() * 100).toStringAsFixed(0)}%';
    return v.toString();
  }

  String? _breathSourceLabel(String? source) {
    if (source == null) return null;
    switch (source) {
      case 'belt':
        return 'Belt';
      case 'polar_hrv':
        return 'Polar';
      case 'microphone':
        return 'Mic';
      default:
        return source;
    }
  }
}

class _StoredMetric {
  final String label;
  final dynamic value;
  final String unit;

  const _StoredMetric(this.label, this.value, this.unit);
}

class _HrGraphPainter extends CustomPainter {
  final List<int> readings;
  final bool isDark;

  _HrGraphPainter({required this.readings, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.length < 2) return;

    final minHr = readings.reduce((a, b) => a < b ? a : b).toDouble();
    final maxHr = readings.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxHr - minHr;
    final yRange = range < 5 ? 10.0 : range + 4;
    final yMin = minHr - 2;

    final gridPaint =
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.06,
          )
          ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final labelStyle = TextStyle(
      fontSize: 9,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
    );
    for (int i = 0; i <= 4; i++) {
      final val = (yMin + yRange * i / 4).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = size.height * (1 - i / 4) - tp.height / 2;
      tp.paint(canvas, Offset(0, y.clamp(0, size.height - tp.height)));
    }

    final areaPath = Path();
    final linePath = Path();
    final leftPad = 28.0;
    final usableWidth = size.width - leftPad;

    for (int i = 0; i < readings.length; i++) {
      final x = leftPad + (i / (readings.length - 1)) * usableWidth;
      final y = size.height - ((readings[i] - yMin) / yRange) * size.height;
      final clampedY = y.clamp(0.0, size.height);
      if (i == 0) {
        areaPath.moveTo(x, clampedY);
        linePath.moveTo(x, clampedY);
      } else {
        areaPath.lineTo(x, clampedY);
        linePath.lineTo(x, clampedY);
      }
    }

    areaPath.lineTo(leftPad + usableWidth, size.height);
    areaPath.lineTo(leftPad, size.height);
    areaPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.dustyRose.withValues(alpha: 0.3),
        AppTheme.dustyRose.withValues(alpha: 0.02),
      ],
    );
    final areaPaint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          );
    canvas.drawPath(areaPath, areaPaint);

    final linePaint =
        Paint()
          ..color = AppTheme.dustyRose
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HrGraphPainter oldDelegate) =>
      readings != oldDelegate.readings;
}
