import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:small_husn_muslim/core/services/notification_service.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/utils/audio_utils.dart';
import 'package:small_husn_muslim/features/azkar/presentation/azkar_details_screen.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/core/widgets/app_drawer.dart';
import 'package:small_husn_muslim/features/azkar/controllers/azkar_controller.dart';

class MyHomePageScreen extends StatefulWidget {
  final bool isRoot;
  final bool isHomeScreen;
  final bool isDarkMode;

  const MyHomePageScreen({
    super.key,
    this.isRoot = true,
    this.isHomeScreen = true,
    this.isDarkMode = true,
  });

  @override
  MyHomePageScreenState createState() => MyHomePageScreenState();
}

class MyHomePageScreenState extends State<MyHomePageScreen> {
  final AzkarController _azkarController = Get.put(AzkarController());
  final _player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool toggle = true;

  @override
  void dispose() {
    _player.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the main scaffold content
    Widget scaffoldContent = SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: toggle
                ? (widget.isHomeScreen
                    ? null // Let drawer icon show automatically
                    : IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Get.back(),
                      ))
                : null, // No leading icon during search
            title: toggle
                ? SizedBox(
                    height: 30,
                    child: Text(
                      'الأذكار',
                      style: TextStyle(
                        fontSize: double.parse(fontSize22),
                        fontFamily: fontFamily,
                        color: bgLight,
                      ),
                    ),
                  )
                : Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      autofocus: true,
                      onChanged: (value) {
                        _azkarController.updateSearchQuery(value);
                      },
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: fontFamily,
                          fontSize: 16,
                        ),
                        hintText: search,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        fontSize: 18,
                      ),
                    ),
                  ),
            iconTheme: IconThemeData(color: bgLight),
            actions: toggle ? _toggleSearchIcon() : _clearSearchAction(),
            flexibleSpace: SizedBox(
              height: 60,
              child: Image.asset(appBarBG, fit: BoxFit.cover),
            ),
          ),
          drawer: widget.isHomeScreen ? const AppDrawer() : null,
          body: Obx(() {
            if (_azkarController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = _azkarController.filteredAzkarList;
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد نتائج',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final azkar = list[index];
                return Column(
                  children: [
                    ListTile(
                      trailing: IconButton(
                        icon: const Icon(Icons.headset_mic_sharp),
                        onPressed: () {
                          setupAudioPlayer(_player, azkar.audio);

                          Get.dialog(
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: Text(
                                  azkar.category,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: double.parse(fontSize24),
                                  ),
                                ),
                                content: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: progressBar(_player),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: playbackControlButton(_player),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      _player.stop();
                                      Get.back();
                                    },
                                    child: Text(
                                      leave,
                                      style: TextStyle(
                                        fontSize: double.parse(fontSize18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).then((value) => _player.stop());
                        },
                      ),
                      leading: const Icon(Icons.ac_unit_sharp),
                      title: Text(
                        azkar.category,
                        style: TextStyle(
                          fontSize: double.parse(fontSize18),
                          fontFamily: fontFamily,
                        ),
                      ),
                      onTap: () async {
                        await Get.to(
                          () => AzkarDetailsScreen(azkarInfo: azkar),
                        )?.then((value) => _azkarController.loadAzkarData());
                      },
                    ),
                    const Divider(height: 1, thickness: 0.3)
                  ],
                );
              },
            );
          }),
        ),
      ),
    );

    return scaffoldContent;
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingPayload = NotificationService().pendingPayload;
      if (pendingPayload != null) {
        if (pendingPayload == 'Fajr_Challenge') {
          Get.to(() => const FajrChallengeScreen());
        } else if (pendingPayload == 'Morning_Adhkar' ||
            pendingPayload == 'Evening_Adhkar') {
          NotificationService().handleAdhkarNotification(pendingPayload);
        }
        NotificationService().pendingPayload = null;
      }

      final pendingScreen = await PrayerNotificationHelper.getPendingScreen();
      if (pendingScreen != null) {
        if (pendingScreen == 'prayer_times') {
          Get.to(() => const PrayerTimesScreen());
        }
      }
    });
  }

  List<Widget> _clearSearchAction() {
    return [
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() {
          searchController.clear();
          _azkarController.clearSearch();
          toggle = true;
        }),
      ),
      Obx(() => _azkarController.searchQuery.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                _azkarController.clearSearch();
              },
            )
          : const SizedBox.shrink()),
    ];
  }

  List<Widget> _toggleSearchIcon() {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() {
            toggle = false;
          }),
        ),
      ),
    ];
  }
}
