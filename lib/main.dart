import 'dart:convert';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:just_audio/just_audio.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:small_husn_muslim/adkar.dart';
import 'package:small_husn_muslim/azkar_class.dart';
import 'package:small_husn_muslim/constant/colors.dart';
import 'package:small_husn_muslim/constant/strings.dart';

void main() async {
  runApp(const MyHomePageScreen());
}

class MyHomePageScreen extends StatefulWidget {
  const MyHomePageScreen({super.key});

  @override
  MyHomePageScreenState createState() => MyHomePageScreenState();
}

class MyHomePageScreenState extends State<MyHomePageScreen> {
  List<AzkarInfo> azkarList = [];
  final _player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool toggle = true;
  var iconColor = Icons.light_mode;

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return GetMaterialApp(
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Builder(builder: (context) {
          return SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                appBar: AppBar(
                  title: SizedBox(
                    height: 30,
                    child: Text(
                      title,
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
                drawer: Drawer(
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
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Directionality(
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
                                        color:
                                            Get.isDarkMode ? bgLight : bgDark,
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
                                                const Icon(Icons.person_pin),
                                            title: Text(developer),
                                            subtitle: Text(
                                              developerName,
                                              style: TextStyle(
                                                fontFamily: fontFamily,
                                              ),
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
                                              // launchUrl(Uri.base);
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
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          leave,
                                          style: TextStyle(
                                            fontFamily: fontFamily,
                                            color: Get.isDarkMode
                                                ? bgLight
                                                : bgDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                ),
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
                                  setupAudioPlayer(
                                      _player, azkarList[index].audio);

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: Text(
                                            azkarList[index].category,
                                            style: TextStyle(
                                              fontFamily: fontFamily,
                                              fontSize:
                                                  double.parse(fontSize24),
                                            ),
                                          ),
                                          content: Row(
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20),
                                                  child: _progessBar(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: _playbackControlButton(),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                _player.stop();
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                leave,
                                                style: TextStyle(
                                                  fontSize:
                                                      double.parse(fontSize18),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
                                () => AzkarDetailsScreen(
                                    azkarInfo: azkarList[index]),
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
        }));
  }

  @override
  void initState() {
    super.initState();
    loadAzkarData();
    toggleTheme();
  }

  Future<void> loadAzkarData() async {
    String jsonData = await loadAzkarJson();
    List<dynamic> jsonList = json.decode(jsonData);

    setState(() {
      azkarList = jsonList.map((json) => AzkarInfo.fromJson(json)).toList();
    });
  }

  void toggleTheme() {
    setState(() {
      Get.changeTheme(Get.isDarkMode ? ThemeData.light() : ThemeData.dark());
      iconColor = !Get.isDarkMode ? Icons.light_mode : Icons.dark_mode;
    });
  }

  Widget _playbackControlButton() {
    return StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final processingState = snapshot.data?.processingState;
          final playing = snapshot.data?.playing;
          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            return Container(
              margin: const EdgeInsets.all(8.0),
              child: const CircularProgressIndicator(),
            );
          } else if (playing != true) {
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 50,
              onPressed: _player.play,
            );
          } else if (processingState != ProcessingState.completed) {
            return IconButton(
              icon: const Icon(Icons.pause),
              iconSize: 50,
              onPressed: _player.pause,
            );
          } else {
            return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 50,
                onPressed: () => _player.seek(Duration.zero));
          }
        });
  }

  Widget _progessBar() {
    return StreamBuilder<Duration?>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ProgressBar(
            progress: snapshot.data ?? Duration.zero,
            buffered: _player.bufferedPosition,
            total: _player.duration ?? Duration.zero,
            onSeek: (duration) {
              _player.seek(duration);
            },
          ),
        );
      },
    );
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
        child: Row(
          children: [
            IconButton(
              icon: Icon(iconColor),
              onPressed: toggleTheme,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() {
                toggle = false;
              }),
            ),
          ],
        ),
      ),
    ];
  }
}
