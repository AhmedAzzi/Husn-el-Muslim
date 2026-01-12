import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/azkar_info.dart';
import '../models/prayer_times_logic.dart';
import '../helpers/prayer_notification_helper.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../utils.dart';
import '../main.dart' show lightTheme, darkTheme;
import 'azkar_details_screen.dart';
import 'custom_dikr_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';
import '../dialogs/ayat_hadith_dialog.dart';

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
  List<AzkarInfo> azkarList = [];
  final _player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool toggle = true;

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    // Build the main scaffold content
    Widget scaffoldContent = SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: widget.isHomeScreen
                ? null // Let drawer icon show automatically
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
            title: SizedBox(
              height: 30,
              child: Text(
                'الأذكار',
                style: TextStyle(
                  fontSize: double.parse(fontSize22),
                  fontFamily: fontFamily,
                  color: bgLight,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: bgLight),
            actions: toggle ? _toggleSearchIcon() : _toggleSearchBar(),
            flexibleSpace: SizedBox(
              height: 60,
              child: Image.asset(appBarBG, fit: BoxFit.cover),
            ),
          ),
          drawer: widget.isHomeScreen
              ? Drawer(
                  width: screenSize.width - 100,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      DrawerHeader(
                        child:
                            Center(child: Image(image: AssetImage(icLauncher))),
                      ),
                      ListTile(
                        leading: const Icon(Icons.list_rounded),
                        title: Text(
                          adkar,
                          style: TextStyle(
                            fontSize: double.parse(fontSize18),
                            fontFamily: fontFamily,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        onTap: () => Get.back(),
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.bubble_chart),
                        title:
                            const Text('مسبحة', style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Get.back(); // Close drawer
                          Get.to(() => CustomDikrScreen());
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.access_time_filled_rounded),
                        title: const Text('مواقيت الصلاة',
                            style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Get.back(); // Close drawer
                          Get.to(() => const PrayerTimesScreen());
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('الإعدادات',
                            style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Get.back(); // Close drawer
                          Get.to(() => const SettingsScreen());
                        },
                      ),
                      const Divider(thickness: 0.3),
                      ListTile(
                        onTap: () {
                          Get.dialog(
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Theme(
                                data: Get.isDarkMode
                                    ? ThemeData.dark()
                                    : ThemeData.light(),
                                child: AlertDialog(
                                  backgroundColor:
                                      Get.isDarkMode ? bgDark : bgLight,
                                  title: Text(
                                    about,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: Get.isDarkMode ? bgLight : bgDark,
                                    ),
                                  ),
                                  content: SizedBox(
                                    height: 450,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Image.asset(
                                            icLauncher,
                                            scale: 3,
                                          ),
                                          title: Text(aboutVersion),
                                          subtitle: Text(aboutOpenSource),
                                        ),
                                        const Divider(),
                                        ListTile(
                                          title: Text(
                                            do3aa,
                                            style: TextStyle(
                                                fontFamily: fontFamily,
                                                fontSize:
                                                    double.parse(fontSize24)),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading:
                                              const Icon(SimpleIcons.google),
                                          title: Text(offielWebSite),
                                          subtitle: Text(
                                            offielWebSiteIbnWahf,
                                            style: TextStyle(
                                              fontFamily: fontFamily,
                                            ),
                                          ),
                                          onTap: () {
                                            openURL(oficialWebSiteLink);
                                          },
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading:
                                              const Icon(SimpleIcons.github),
                                          title: Text(sourceCode),
                                          onTap: () async {
                                            await openURL(
                                              githubLink,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      child: Text(
                                        leave,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          color:
                                              Get.isDarkMode ? bgLight : bgDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        leading: const Icon(Icons.info_rounded),
                        title: Text(
                          about,
                          style: TextStyle(
                            fontFamily: fontFamily,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const Divider(thickness: 0.3),
                    ],
                  ),
                )
              : null,
          body: ListView.builder(
            itemCount: azkarList.length,
            itemBuilder: (context, index) {
              if (azkarList[index].category.contains(searchQuery)) {
                return Column(
                  children: [
                    ListTile(
                      trailing: IconButton(
                        icon: const Icon(Icons.headset_mic_sharp),
                        onPressed: () {
                          setState(() {
                            setupAudioPlayer(_player, azkarList[index].audio);

                            Get.dialog(
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: Text(
                                    azkarList[index].category,
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
                          });
                        },
                      ),
                      leading: const Icon(Icons.ac_unit_sharp),
                      title: Text(
                        azkarList[index].category,
                        style: TextStyle(
                          fontSize: double.parse(fontSize18),
                          fontFamily: fontFamily,
                        ),
                      ),
                      onTap: () async {
                        await Get.to(
                          () => AzkarDetailsScreen(azkarInfo: azkarList[index]),
                        )?.then((value) => loadAzkarData());
                      },
                    ),
                    const Divider(height: 1, thickness: 0.3)
                  ],
                );
              } else {
                return Container(); // Return an empty container for non-matching items
              }
            },
          ),
        ),
      ),
    );

    // If this is the root widget, wrap with GetMaterialApp
    if (widget.isRoot) {
      return GetMaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: widget.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: scaffoldContent,
      );
    }

    // Otherwise, just return the scaffold content for navigation
    return scaffoldContent;
  }

  @override
  void initState() {
    super.initState();
    loadAzkarData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingPayload = NotificationService().pendingPayload;
      if (pendingPayload != null) {
        Get.dialog(AyatHadithDialog(prayerName: pendingPayload));
        NotificationService().pendingPayload = null;
      }

      // Handle native pending screen (e.g. from persistent notification)
      final pendingScreen = await PrayerNotificationHelper.getPendingScreen();
      if (pendingScreen != null) {
        if (pendingScreen == 'prayer_times') {
          // If we are already on home screen, use Get.to
          // Note: using Get.to allows user to go back to home
          Get.to(() => const PrayerTimesScreen());
        }
      }
    });
  }

  Future<void> loadAzkarData() async {
    String jsonData = await loadAzkarJson();
    List<dynamic> jsonList = json.decode(jsonData);

    setState(() {
      azkarList = jsonList.map((json) => AzkarInfo.fromJson(json)).toList();
    });
  }

  List<Widget> _toggleSearchBar() {
    return [
      const Spacer(),
      Expanded(
        flex: 6,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintStyle: TextStyle(color: bgLight),
              hintText: search,
              prefixIcon: Icon(Icons.search, color: bgLight),
            ),
            style: TextStyle(color: bgLight),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: () => setState(() {
          searchController.clear();
          searchQuery = '';
          toggle = true;
        }),
      ),
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
