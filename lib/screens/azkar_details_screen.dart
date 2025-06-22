import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/azkar_info.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import 'package:path_provider/path_provider.dart';
import '../utils.dart';
import 'package:flutter/foundation.dart';

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
  late List<Key> screenshotKeys;

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
      (index) => GlobalKey(debugLabel: 'screenshot_key_$index'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
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
                            child:
                                Text(value, textDirection: TextDirection.rtl),
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
            title: Text(
              widget.azkarInfo.category,
              style: TextStyle(
                fontSize: double.parse(fontSize18),
                fontFamily: fontFamily,
                color: bgLight,
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: progressBar(_player,
                          topPadding: 15,
                          thumbRadius: 7,
                          barHeight: 2,
                          timeLabelTextStyle: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: playbackControlButton(_player, iconSize: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Text(
                              (marrat == 100
                                  ? '$marrat مرة'
                                  : (marrat > 1
                                      ? '$marrat مرات'
                                      : 'مرة واحدة')),
                              style: TextStyle(
                                fontSize: double.parse(fontSize18),
                                color: bgLight,
                                fontFamily: fontFamily,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 0, right: 15),
                              child: Text(
                                '${widget.azkarInfo.array[currentPageIndex].count}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: double.parse(fontSize22),
                                    fontFamily: fontFamily,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'الذكر ${currentPageIndex + 1} من ${widget.azkarInfo.array.length}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: double.parse(fontSize18),
                                  color: bgLight,
                                  fontFamily: fontFamily),
                            ),
                          ),
                        ],
                      ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5, top: 0),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.only(top: 5, bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 2),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 0.5),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  widget.azkarInfo.array[index].text,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: double.parse(fontSize24),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 60,
                          child: Row(
                            children: List.generate(
                                550 ~/ 10,
                                (index) => Expanded(
                                      flex: 5,
                                      child: Container(
                                        color: index % 2 == 0
                                            ? Colors.transparent
                                            : Colors.grey,
                                        height: 1,
                                      ),
                                    )),
                          ),
                        ),
                        const SizedBox(height: 5),
                        ListTile(
                          title: Text(
                            widget.azkarInfo.footnote[index],
                            // '',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
