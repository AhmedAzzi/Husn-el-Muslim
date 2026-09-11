import 'package:get/get.dart';

import '../../domain/services/statistics_service.dart';

/// GetX controller exposing statistics for the dashboard and statistics screen.
class StatisticsController extends GetxController {
  StatisticsController(this._stats);

  final StatisticsService _stats;

  final cumulative = Rxn<CumulativeStats>();
  final todayCount = 0.obs;
  final yesterdayCount = 0.obs;
  final todayMinutes = 0.obs;
  final weekCount = 0.obs;
  final monthCount = 0.obs;
  final currentStreak = 0.obs;
  final longestStreak = 0.obs;
  final isLoading = false.obs;
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    error.value = null;
    try {
      cumulative.value = await _stats.cumulative();
      todayCount.value = await _stats.countOn(DateTime.now());
      yesterdayCount.value =
          await _stats.countOn(DateTime.now().subtract(const Duration(days: 1)));
      todayMinutes.value = await _stats.minutesOn(DateTime.now());
      final week = await _stats.lastWeek();
      weekCount.value = week.fold(0, (a, d) => a + d.count);
      final month = await _stats.lastMonth();
      monthCount.value = month.fold(0, (a, d) => a + d.count);
      final c = cumulative.value;
      currentStreak.value = c?.currentStreak ?? 0;
      longestStreak.value = c?.longestStreak ?? 0;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
