import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../data/models/khatma_models.dart';
import '../../domain/services/statistics_service.dart';
import '../controllers/statistics_controller.dart';

/// Statistics screen: today/yesterday counts, cumulative totals, streak, and
/// a simple 7-day bar chart drawn without an external chart dependency.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = Get.find<StatisticsService>();
  List<DailyCount> _week = [];

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    final w = await _service.lastWeek();
    if (mounted) setState(() => _week = w);
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<StatisticsController>();
    final l = L10n.of(khatmaLang());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.t('statistics'),
            style: const TextStyle(
              fontFamily: HusnTheme.fontFamily,
              fontSize: HusnTheme.fontSize18,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: HusnTheme.primary,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ctl.refresh();
            await _loadWeek();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Obx(() {
                final total = ctl.cumulative.value?.totalVerses ?? 0;
                final today = ctl.todayCount.value;
                final yesterday = ctl.yesterdayCount.value;
                final minutes = ctl.todayMinutes.value;
                final streak = ctl.currentStreak.value;
                final longest = ctl.longestStreak.value;
                final activeDays = ctl.cumulative.value?.activeDays ?? 0;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _bigStat(
                            l.t('today'),
                            '$today',
                            l.t('minutes'),
                            '$minutes د',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _bigStat(
                            l.t('total_verses'),
                            '$total',
                            l.t('streak'),
                            '$streak يوم',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _bigStat(
                              'أمس', '$yesterday', 'أطول سلسلة', '$longest'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _bigStat('أيام نشطة', '$activeDays', 'المجموع',
                              '$total آية'),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
              const Text(
                'آخر ٧ أيام',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: HusnTheme.fontSize18,
                ),
              ),
              const SizedBox(height: 8),
              if (_week.isNotEmpty) _weekChart(_week),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigStat(String label1, String value1, String label2, String value2) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value1,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HusnTheme.primary,
              ),
            ),
            Text(
              label1,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value2,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 16,
              ),
            ),
            Text(
              label2,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekChart(List<DailyCount> week) {
    final max = week.map((d) => d.count).fold<int>(1, (a, b) => b > a ? b : a);
    return Container(
      height: 180,
      alignment: Alignment.bottomCenter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(week.length, (i) {
          final d = week[i];
          final h = max == 0 ? 4.0 : (d.count / max) * 120;
          final label = StatisticsService.weekdayLabels[i % 7];
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: h.clamp(4, 140),
                  width: 18,
                  decoration: BoxDecoration(
                    color: d.count == 0
                        ? Colors.grey.withValues(alpha: 0.3)
                        : HusnTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 10)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
