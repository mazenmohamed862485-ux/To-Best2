import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'التقدم' : 'Progress',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: isAr ? 'القياسات' : 'Measurements',
            onPressed: () => context.push('/progress/measurements'),
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: isAr ? 'الصور' : 'Photos',
            onPressed: () => context.push('/progress/photos'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(progressProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Evaluation summary ───────────
                  if (state.evalResult != null)
                    _EvalCard(eval: state.evalResult!, isAr: isAr),
                  const SizedBox(height: 16),

                  // ── Volume chart ─────────────────
                  _ChartCard(
                    title: isAr ? '📈 الحجم الأسبوعي' : '📈 Weekly Volume',
                    child: _VolumeChart(data: state.weeklyVolume),
                  ),
                  const SizedBox(height: 16),

                  // ── Weight chart ─────────────────
                  if (state.weightHistory.isNotEmpty)
                    _ChartCard(
                      title: isAr ? '⚖️ تتبع الوزن' : '⚖️ Weight Tracking',
                      child: _WeightChart(data: state.weightHistory),
                    ),
                  const SizedBox(height: 16),

                  // ── PRs table ────────────────────
                  _PRsTable(prs: state.prs, isAr: isAr),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

// ── Evaluation Card ───────────────────────────────────
class _EvalCard extends StatelessWidget {
  final EvalResult eval;
  final bool isAr;
  const _EvalCard({required this.eval, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = _evalColor(eval.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAr ? 'تقييم أدائك' : 'Your Performance',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                Text(eval.label,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: color, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _evalColor(EvalType type) {
    switch (type) {
      case EvalType.s1: return AppColors.evalS1;
      case EvalType.s2: return AppColors.evalS2;
      case EvalType.s3: return AppColors.evalS3;
      case EvalType.rv: return AppColors.evalGd;
      case EvalType.gd: return AppColors.evalGd;
      case EvalType.st: return AppColors.evalSt;
      case EvalType.ws: return AppColors.evalSt;
      case EvalType.dn: return AppColors.evalDn;
      case EvalType.beg: return AppColors.evalBeg;
    }
  }
}

// ── Chart Card Wrapper ────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

// ── Volume Bar Chart ──────────────────────────────────
class _VolumeChart extends StatelessWidget {
  final List<({String week, double volume})> data;
  const _VolumeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)));
    }
    final theme = Theme.of(context);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((d) => d.volume).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Text(data[idx].week.substring(5),
                    style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: theme.dividerColor,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.volume,
              color: theme.colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        )).toList(),
      ),
    );
  }
}

// ── Weight Line Chart ─────────────────────────────────
class _WeightChart extends StatelessWidget {
  final List<({String date, double weight})> data;
  const _WeightChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    final minW = data.map((d) => d.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxW = data.map((d) => d.weight).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minW,
        maxY: maxW,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: theme.dividerColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (data.length / 4).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Text(data[idx].date.substring(5),
                    style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Colors.grey));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.ok,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 20,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3, color: AppColors.ok, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.ok.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PRs Table ─────────────────────────────────────────
class _PRsTable extends StatelessWidget {
  final List<PersonalRecordEntry> prs;
  final bool isAr;
  const _PRsTable({required this.prs, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? '🏆 أرقام قياسية' : '🏆 Personal Records',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            if (prs.isEmpty)
              Text(isAr ? 'لا توجد أرقام قياسية بعد' : 'No PRs yet',
                  style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'))
            else
              ...prs.map((pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(pr.name,
                              style: const TextStyle(fontSize: 13, fontFamily: 'Cairo')),
                        ),
                        Text('${pr.weight}kg × ${pr.reps}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${pr.epley.toStringAsFixed(0)} 1RM',
                              style: TextStyle(
                                  fontSize: 10, color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
