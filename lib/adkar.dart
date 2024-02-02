import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:small_husn_muslim/azkar_class.dart';
import 'package:small_husn_muslim/constant/colors.dart';
import 'package:small_husn_muslim/constant/strings.dart';

class AzkarDetailsScreen extends StatefulWidget {
  final AzkarInfo azkarInfo;

  const AzkarDetailsScreen({super.key, required this.azkarInfo});

  @override
  AzkarDetailsScreenState createState() => AzkarDetailsScreenState();
}

class AzkarDetailsScreenState extends State<AzkarDetailsScreen> {
  PageController pageController = PageController(initialPage: 0);
  int currentPageIndex = 0;
  final _player = AudioPlayer();
  int marrat = 0;
  var iconColor = Get.isDarkMode ? Icons.light_mode : Icons.dark_mode;
  late List<ScreenshotController> screenshotControllers;

  late List<Key> screenshotKeys; // Add this line

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              PopupMenuButton(
                  onSelected: (value) async {
                    switch (value) {
                      case 'نسخ':
                        Clipboard.setData(ClipboardData(
                                text: widget
                                    .azkarInfo.array[currentPageIndex].text))
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Center(
                                      child:
                                          Text('تم نسخ الذكر إلى الحافظة'))));
                        });

                        break;
                      case 'مشاركة':
                        screenshotControllers[currentPageIndex]
                            .capture(delay: const Duration(milliseconds: 10))
                            .then((capturedImage) async {
                          final Uint8List? bytes = capturedImage;
                          final Uint8List list = bytes!.buffer.asUint8List();
                          final tempDir = await getTemporaryDirectory();
                          final file =
                              await File('${tempDir.path}/AllAboutFlutter.png')
                                  .create();
                          file.writeAsBytesSync(list);
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            subject: "من أذكار ${widget.azkarInfo.category}",
                          );
                        }).catchError((onError) {
                          if (kDebugMode) {
                            print(onError);
                          }
                        });

                        break;
                    }
                  },
                  itemBuilder: (BuildContext itemBuilder) => {'نسخ', 'مشاركة'}
                      .map((value) => PopupMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList())
            ],
            iconTheme: IconThemeData(color: bgLight),
            flexibleSpace: SizedBox(
              height: 60,
              child: Image.asset(appBarBG, fit: BoxFit.cover),
            ),
            leading: IconButton(
              onPressed: () {
                _player.stop();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                widget.azkarInfo.category,
                style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: double.parse(fontSize22),
                    color: bgLight),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _progessBar(),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _playbackControlButton(),
                    ),
                  ],
                ),
              ),
              _dikrPage(),
              Stack(
                children: [
                  Container(
                    height: 60.0,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(counterBG),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Text(
                            (marrat == 100
                                ? '$marrat مرة'
                                : (marrat > 1 ? '$marrat مرات' : 'مرة واحدة')),
                            style: TextStyle(color: bgLight),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 15, right: 15),
                            child: Text(
                              '${widget.azkarInfo.array[currentPageIndex].count}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: double.parse(fontSize22),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'الذكر ${currentPageIndex + 1} من ${widget.azkarInfo.array.length}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: bgLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    setupAudioPlayer(_player, widget.azkarInfo.array[currentPageIndex].audio);

    screenshotControllers = List.generate(
      widget.azkarInfo.array.length,
      (_) => ScreenshotController(),
    );

    screenshotKeys = List.generate(
      widget.azkarInfo.array.length,
      (index) => GlobalKey(
          debugLabel:
              'screenshot_key_$index'), // Use debugLabel for easier debugging
    );
  }

// 37030709
// @Rachidbk2001#
  void toggleTheme() {
    setState(() {
      Get.changeTheme(Get.isDarkMode ? ThemeData.light() : ThemeData.dark());
      iconColor = !Get.isDarkMode ? Icons.light_mode : Icons.dark_mode;
    });
  }

  Widget _dikrPage() {
    return Expanded(
      child: PageView.builder(
        controller: pageController,
        itemCount: widget.azkarInfo.array.length,
        onPageChanged: (index) {
          setState(() {
            currentPageIndex = index;
            marrat = widget.azkarInfo.array[currentPageIndex].fix;
            setupAudioPlayer(
                _player, widget.azkarInfo.array[currentPageIndex].audio);
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                if (widget.azkarInfo.array[index].count > 0) {
                  widget.azkarInfo.array[index].count--;
                  if (widget.azkarInfo.array[index].count == 0) {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.linear,
                    );
                  }
                }
              });
            },
            child: ListView(
              children: [
                Screenshot(
                  key: screenshotKeys[index],
                  controller: screenshotControllers[index],
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.only(top: 5, bottom: 10),
                    decoration: widget.azkarInfo.array[index].text
                                .contains('سورة الملك') ||
                            widget.azkarInfo.array[index].text
                                .contains('سورة السجدة')
                        ? (!Get.isDarkMode
                            ? BoxDecoration(
                                border: Border.all(color: bgDark, width: 3),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(30)))
                            : BoxDecoration(
                                border: Border.all(color: bgLight, width: 3),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(30))))
                        : BoxDecoration(
                            image: DecorationImage(
                            alignment: Alignment.center,
                            image: (!Get.isDarkMode
                                ? const AssetImage("assets/page.png")
                                : const AssetImage("assets/page_white.png")),
                            fit: BoxFit.fill,
                          )),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 7, top: 0),
                      child: ListTile(
                        title: Text(
                          widget.azkarInfo.array[index].text,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: double.parse(fontSize22),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                !Get.isDarkMode
                    ? Image.asset(
                        separator,
                        height: 50,
                      )
                    : Image.asset(
                        whiteSeparator,
                        height: 50,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  // saveImage(BuildContext context, Uint8List imageBytes) async {
  //   try {
  //     // Get the temporary directory using path_provider
  //     Directory tempDir = await getTemporaryDirectory();

  //     // Generate a unique filename using current timestamp
  //     String fileName =
  //         'capturedImage_${DateTime.now().millisecondsSinceEpoch}.png';

  //     // Create the file with the generated filename
  //     File imageFile = File('${tempDir.path}/$fileName');

  //     // Write the image bytes to the file
  //     await imageFile.writeAsBytes(imageBytes);

  //     // Save the image using GallerySaver
  //     await GallerySaver.saveImage(imageFile.path);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Image saved to gallery')),
  //     );
  //   } catch (e) {
  //     print('Error saving image: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to save image')),
  //     );
  //   }
  // }

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
}
