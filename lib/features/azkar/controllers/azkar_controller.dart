import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/azkar/data/azkar_info.dart';
import 'package:small_husn_muslim/core/utils/asset_loader.dart';

class AzkarController extends GetxController {
  final azkarList = <AzkarInfo>[].obs;
  final searchQuery = ''.obs;
  final isLoading = true.obs;

  List<AzkarInfo> get filteredAzkarList {
    if (searchQuery.isEmpty) {
      return azkarList;
    }
    return azkarList
        .where((azkar) => azkar.category.contains(searchQuery.value))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAzkarData();
  }

  Future<void> loadAzkarData() async {
    isLoading.value = true;
    try {
      final jsonData = await loadAzkarJson();
      // Offload heavy JSON decoding to an isolate to prevent UI jank
      final List<AzkarInfo> loadedAzkar = await compute(_parseAzkar, jsonData);
      azkarList.assignAll(loadedAzkar);
    } catch (e) {
      if (kDebugMode) print('Error loading azkar data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  static List<AzkarInfo> _parseAzkar(String jsonData) {
    final List<dynamic> jsonList = json.decode(jsonData);
    return jsonList.map((json) => AzkarInfo.fromJson(json)).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }
}
