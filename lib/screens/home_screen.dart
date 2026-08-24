// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/go_direct/go_direct_constants.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/clinical_primitives.dart';
import 'package:breath_state/widgets/patient_selector.dart';
import 'package:breath_state/widgets/animated_counter.dart';
import 'package:breath_state/widgets/animated_entrance.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _dailyQuotes = [
    'Small steady breaths can change the tone of the whole day.',
    'Let the next breath be simple, steady, and enough.',
    'A calm body gives the mind more room to choose.',
    'Progress can be quiet and still be real.',
    'Meet this moment with one smooth breath at a time.',
    'Your nervous system learns through gentle repetition.',
    'A settled rhythm is a strong place to begin.',
    'The smallest pause can become useful space.',
    'Steady practice builds trust in the body.',
    'Breathe softly, notice clearly, continue kindly.',
  ];

  List<BreathRateEntry> breathEntries = [];
  List<HeartRateEntry> heartEntries = [];
  bool isLoading = true;
  int? _lastLoadedPatientId;
  StreamSubscription<List<BreathRateEntry>>? _breathSub;
  StreamSubscription<List<HeartRateEntry>>? _heartSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentId = Provider.of<PatientProvider>(context).activePatient?.id;
    if (currentId != _lastLoadedPatientId) {
      _lastLoadedPatientId = currentId;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final db = context.read<AppDatabase>();
    final pid = _lastLoadedPatientId;

    await _breathSub?.cancel();
    await _heartSub?.cancel();
    _breathSub = null;
    _heartSub = null;

    setState(() => isLoading = true);
    try {
      if (pid != null) {
        final b = await db.getBreathRatesForPatient(pid);
        final h = await db.getHeartRatesForPatient(pid);
        if (mounted) {
          setState(() {
            breathEntries = b;
            heartEntries = h;
            isLoading = false;
          });
        }
        _breathSub = db.watchBreathRatesForPatient(pid).listen((entries) {
          if (mounted) setState(() => breathEntries = entries);
        });
        _heartSub = db.watchHeartRatesForPatient(pid).listen((entries) {
          if (mounted) setState(() => heartEntries = entries);
        });
      } else {
        if (mounted) {
          setState(() {
            breathEntries = [];
            heartEntries = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _breathSub?.cancel();
    _heartSub?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _dailyQuote(Patient? patient) {
    final now = DateTime.now();
    final seed =
        (patient?.id ?? 0) * 1000000 +
        now.year * 10000 +
        now.month * 100 +
        now.day;
    return _dailyQuotes[seed.abs() % _dailyQuotes.length];
  }

  List<FlSpot> _toSpots<T>(List<T> entries, int Function(T) rateOf) {
    if (entries.isEmpty) return [];
    final recent =
        entries.length > 20 ? entries.sublist(entries.length - 20) : entries;
    return recent.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), rateOf(e.value).toDouble());
    }).toList();
  }

  double _niceInterval(double range, int targetTicks) {
    if (range <= 0) return 1;
    final rawInterval = range / targetTicks;
    final magnitude = _pow10((rawInterval).toStringAsFixed(10));
    final residual = rawInterval / magnitude;
    double nice;
    if (residual <= 1.5) {
      nice = 1;
    } else if (residual <= 3) {
      nice = 2;
    } else if (residual <= 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    return (nice * magnitude).ceilToDouble().clamp(1, double.infinity);
  }

  double _pow10(String valueStr) {
    final v = double.tryParse(valueStr) ?? 1;
    if (v <= 0) return 1;
    final exp = (v.abs()).toStringAsFixed(0).length - 1;
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    if (v < 10) return 1;
    return result / 10;
  }

  Widget _buildChartCard(
    List<FlSpot> spots,
    String title,
    Color color,
    String unit,
  ) {
    final hasData = spots.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String displayValue = '--';
    String minVal = '--';
    String maxVal = '--';
    String avgVal = '--';
    double dataMin = 0, dataMax = 100;
    double chartMin = 0, chartMax = 100;
    double yInterval = 10;

    if (hasData) {
      final values = spots.map((e) => e.y).toList();
      final rawMin = values.reduce((a, b) => a < b ? a : b);
      final rawMax = values.reduce((a, b) => a > b ? a : b);
      final rawAvg = values.reduce((a, b) => a + b) / values.length;

      displayValue = spots.last.y.toStringAsFixed(0);
      minVal = rawMin.toStringAsFixed(0);
      maxVal = rawMax.toStringAsFixed(0);
      avgVal = rawAvg.toStringAsFixed(1);
      dataMin = rawMin;
      dataMax = rawMax;

      final range = (dataMax - dataMin).clamp(2.0, double.infinity);
      yInterval = _niceInterval(range, 4);

      chartMin = (dataMin - yInterval * 0.5);
      chartMin = (chartMin / yInterval).floorToDouble() * yInterval;
      if (chartMin < 0 && dataMin >= 0) chartMin = 0;

      chartMax = (dataMax + yInterval * 0.5);
      chartMax = (chartMax / yInterval).ceilToDouble() * yInterval;

      if ((chartMax - chartMin) / yInterval < 2) {
        chartMax = chartMin + yInterval * 3;
      }
    }

    final labelColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final gridColor =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);
    final axisTitleStyle = TextStyle(
      color: labelColor.withValues(alpha: 0.5),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return ClinicalPanel(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      radius: AppTheme.radiusLg,
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              title.contains('Heart')
                                  ? Icons.favorite_rounded
                                  : Icons.air_rounded,
                              color: color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: labelColor,
                                letterSpacing: 0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          hasData
                              ? AnimatedCounter(
                                value: double.tryParse(displayValue) ?? 0.0,
                                style: Theme.of(
                                  context,
                                ).textTheme.displayMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              )
                              : Text(
                                '--',
                                style: Theme.of(
                                  context,
                                ).textTheme.displayMedium?.copyWith(
                                  color: color.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Text(
                      '${spots.length} readings',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AspectRatio(
            aspectRatio: 2.0,
            child:
                hasData
                    ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: gridColor,
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval:
                                  spots.length > 10
                                      ? ((spots.length - 1) / 5).ceilToDouble()
                                      : 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= spots.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '#${idx + 1}',
                                    style: axisTitleStyle,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: axisTitleStyle,
                                    textAlign: TextAlign.right,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: gridColor.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                        ),
                        minX: 0,
                        maxX: (spots.length - 1).toDouble(),
                        minY: chartMin,
                        maxY: chartMax,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            shadow: Shadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final isLast = spot.x == barData.spots.last.x;
                                return FlDotCirclePainter(
                                  radius: isLast ? 5 : 3,
                                  color:
                                      isLast
                                          ? color
                                          : color.withValues(alpha: 0.7),
                                  strokeWidth: isLast ? 3 : 1.5,
                                  strokeColor:
                                      isDark
                                          ? AppTheme.obsidian
                                          : AppTheme.pureWhite,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.20),
                                  color.withValues(alpha: 0.05),
                                  color.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            getTooltipColor:
                                (_) =>
                                    isDark
                                        ? AppTheme.charcoal.withValues(
                                          alpha: 0.95,
                                        )
                                        : AppTheme.pureWhite.withValues(
                                          alpha: 0.95,
                                        ),
                            getTooltipItems:
                                (touched) =>
                                    touched
                                        .map(
                                          (s) => LineTooltipItem(
                                            '${s.y.toStringAsFixed(1)} $unit',
                                            TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    '\nReading #${s.x.toInt() + 1}',
                                                style: TextStyle(
                                                  color: labelColor.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                          ),
                          handleBuiltInTouches: true,
                          touchSpotThreshold: 20,
                        ),
                        showingTooltipIndicators:
                            spots.length <= 5
                                ? spots.asMap().entries.map((e) {
                                  return ShowingTooltipIndicators([
                                    LineBarSpot(
                                      LineChartBarData(spots: spots),
                                      0,
                                      spots[e.key],
                                    ),
                                  ]);
                                }).toList()
                                : [],
                      ),
                    )
                    : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              title.contains('Heart')
                                  ? Icons.favorite_border_rounded
                                  : Icons.air_rounded,
                              color: color.withValues(alpha: 0.2),
                              size: 36,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No ${title.toLowerCase()} data yet',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start a recording session to see trends',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.2),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),

          if (hasData) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Min',
                    minVal,
                    unit,
                    color.withValues(alpha: 0.6),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.hairline(isDark),
                  ),
                  _buildStatItem('Avg', avgVal, unit, color),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.hairline(isDark),
                  ),
                  _buildStatItem(
                    'Max',
                    maxVal,
                    unit,
                    color.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final breathSpots = _toSpots<BreathRateEntry>(breathEntries, (e) => e.rate);
    final heartSpots = _toSpots<HeartRateEntry>(heartEntries, (e) => e.rate);
    final hPad = Responsive.horizontalPadding(context);
    final showChartsRow = Responsive.isTabletOrDesktop(context);
    final breathColor = isDark ? AppTheme.emerald : AppTheme.deepJade;
    final heartColor = isDark ? AppTheme.dustyRose : AppTheme.darkRose;
    final activePatient = context.watch<PatientProvider>().activePatient;

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
              isLoading
                  ? const PremiumLoadingState(
                    title: 'Loading dashboard',
                    message: 'Preparing recent breath and heart trends.',
                    icon: Icons.insights_rounded,
                    rows: 4,
                  )
                  : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getGreeting(),
                                            style: AppTheme.luxuryItalic(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            activePatient == null
                                                ? 'Clinical dashboard'
                                                : activePatient.name,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.displaySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _dailyQuote(activePatient),
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (Responsive.isMobile(context))
                                      const PatientSelector(),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 100),
                                  child: Consumer2<
                                    PolarConnectProvider,
                                    GoDirectProvider
                                  >(
                                    builder: (
                                      context,
                                      polarProvider,
                                      gdProvider,
                                      _,
                                    ) {
                                      final polarConnected =
                                          polarProvider.getPolarConnect() !=
                                          null;
                                      final gdState =
                                          gdProvider.connectionState;

                                      String gdLabel;
                                      Color gdColor;
                                      switch (gdState) {
                                        case GoDirectConnectionState.scanning:
                                          gdLabel = 'Resp belt scanning';
                                          gdColor = AppTheme.signalWarn;
                                          break;
                                        case GoDirectConnectionState.connecting:
                                        case GoDirectConnectionState
                                            .initializing:
                                          gdLabel = 'Resp belt connecting';
                                          gdColor = AppTheme.signalWarn;
                                          break;
                                        case GoDirectConnectionState.streaming:
                                          gdLabel = 'Resp belt on';
                                          gdColor = AppTheme.signalGood;
                                          break;
                                        case GoDirectConnectionState.connected:
                                          gdLabel = 'Resp belt on';
                                          gdColor = AppTheme.signalGood;
                                          break;
                                        default:
                                          gdLabel = 'Resp belt off';
                                          gdColor = AppTheme.signalBad;
                                      }

                                      return ClinicalPanel(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        radius: AppTheme.radiusLg,
                                        tint:
                                            polarConnected
                                                ? AppTheme.clinicalTeal
                                                : AppTheme.signalWarn,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Sensor readiness',
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.labelSmall,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    polarConnected
                                                        ? 'Polar H10 available'
                                                        : 'Connect Polar H10 to start biofeedback',
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  alignment: WrapAlignment.end,
                                                  children: [
                                                    ClinicalStatusPill(
                                                      label:
                                                          polarConnected
                                                              ? 'Polar ready'
                                                              : 'Polar off',
                                                      color:
                                                          polarConnected
                                                              ? AppTheme
                                                                  .signalGood
                                                              : AppTheme
                                                                  .signalBad,
                                                      icon:
                                                          Icons
                                                              .favorite_rounded,
                                                    ),
                                                    ClinicalStatusPill(
                                                      label: gdLabel,
                                                      color: gdColor,
                                                      icon: Icons.air_rounded,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        sliver: SliverToBoxAdapter(
                          child: ContentContainer(
                            child: AnimatedEntrance(
                              delay: const Duration(milliseconds: 200),
                              child:
                                  showChartsRow
                                      ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: _buildChartCard(
                                              breathSpots,
                                              'Breath Rate',
                                              breathColor,
                                              '/min',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildChartCard(
                                              heartSpots,
                                              'Heart Rate',
                                              heartColor,
                                              'bpm',
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        children: [
                                          _buildChartCard(
                                            breathSpots,
                                            'Breath Rate',
                                            breathColor,
                                            '/min',
                                          ),
                                          _buildChartCard(
                                            heartSpots,
                                            'Heart Rate',
                                            heartColor,
                                            'bpm',
                                          ),
                                        ],
                                      ),
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
