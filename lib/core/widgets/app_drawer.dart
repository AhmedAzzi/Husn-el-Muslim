import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_icons/simple_icons.dart';

import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/utils/url_utils.dart';
import 'package:small_husn_muslim/features/masbaha/presentation/custom_dikr_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/presentation/prayer_times_screen.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Drawer(
      width: screenSize.width - 100,
      child: ListView(
        shrinkWrap: true,
        children: [
          DrawerHeader(
            child: Center(child: Image(image: AssetImage(icLauncher))),
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
            title: const Text('مسبحة', style: TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const CustomDikrScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.access_time_filled_rounded),
            title: const Text('مواقيت الصلاة', style: TextStyle(fontSize: 18)),
            onTap: () {
              Get.back(); // Close drawer
              Get.to(() => const PrayerTimesScreen());
            },
          ),
          const Divider(thickness: 0.3),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات', style: TextStyle(fontSize: 18)),
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
                    data: Get.isDarkMode ? ThemeData.dark() : ThemeData.light(),
                    child: AlertDialog(
                      backgroundColor: Get.isDarkMode ? bgDark : bgLight,
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
                                    fontSize: double.parse(fontSize24)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(SimpleIcons.google),
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
                              leading: const Icon(SimpleIcons.github),
                              title: Text(sourceCode),
                              onTap: () async {
                                await openURL(githubLink);
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
                              color: Get.isDarkMode ? bgLight : bgDark,
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
    );
  }
}
