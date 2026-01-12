import 'package:flutter/material.dart';
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
import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late List<ScreenshotController> screenshotControllers;
  late List<Key> screenshotKeys;

  Timer? _timer;
  bool isAutoPlaying = false;
  int autoIncrementInterval = 1000; // milliseconds
  final ap.AudioPlayer _clickPlayer = ap.AudioPlayer();
  bool _clickSoundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    marrat = widget.azkarInfo.array[currentPageIndex].fix; // Initialize marrat
    setupAudioPlayer(_player, widget.azkarInfo.array[currentPageIndex].audio);
    screenshotControllers = List.generate(
      widget.azkarInfo.array.length,
      (_) => ScreenshotController(),
    );
    screenshotKeys = List.generate(
      widget.azkarInfo.array.length,
      (index) => GlobalKey(debugLabel: 'screenshot_key_$index'),
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _clickPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> playClickSound() async {
    if (!_clickSoundEnabled) return;
    try {
      await _clickPlayer.play(ap.AssetSource('click.wav'));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> vibrateDevice() async {
    if (!_vibrationEnabled) return;
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      // Silently fail
    }
  }

  void toggleAutoPlay() {
    if (isAutoPlaying) {
      _timer?.cancel();
      setState(() {
        isAutoPlaying = false;
      });
    } else {
      setState(() {
        isAutoPlaying = true;
      });
      _timer = Timer.periodic(Duration(milliseconds: autoIncrementInterval),
          (timer) {
        decrement();
      });
    }
  }

  void showIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempInterval = autoIncrementInterval;
        final TextEditingController intervalController = TextEditingController(
          text: (tempInterval / 1000).toStringAsFixed(1),
        );

        void updateFromTextField(String value) {
          final parsed = double.tryParse(value);
          if (parsed != null && parsed >= 0.1) {
            tempInterval = (parsed * 1000).round();
          }
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('سرعة العداد التلقائي',
                    style: TextStyle(fontFamily: 'Amiri')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('الوقت بالثانية'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              tempInterval += 100;
                              intervalController.text =
                                  (tempInterval / 1000).toStringAsFixed(1);
                            });
                          },
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: intervalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              updateFromTextField(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (tempInterval > 100) tempInterval -= 100;
                              intervalController.text =
                                  (tempInterval / 1000).toStringAsFixed(1);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Update from text field before saving
                      updateFromTextField(intervalController.text);
                      this.setState(() {
                        autoIncrementInterval = tempInterval;
                        if (isAutoPlaying) {
                          // Restart timer with new interval
                          _timer?.cancel();
                          _timer = Timer.periodic(
                              Duration(milliseconds: autoIncrementInterval),
                              (timer) {
                            decrement();
                          });
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void resetCount() {
    setState(() {
      widget.azkarInfo.array[currentPageIndex].count =
          widget.azkarInfo.array[currentPageIndex].fix;
      isAutoPlaying = false;
      _timer?.cancel();
    });
  }

  void decrement() {
    if (widget.azkarInfo.array[currentPageIndex].count > 0) {
      playClickSound();
      vibrateDevice();
      setState(() {
        widget.azkarInfo.array[currentPageIndex].count--;
        if (widget.azkarInfo.array[currentPageIndex].count == 0) {
          isAutoPlaying = false;
          _timer?.cancel();
          pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.linear,
          );
        }
      });
    } else {
      isAutoPlaying = false;
      _timer?.cancel();
    }
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
                          if (!context.mounted) return;
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
                          if (!context.mounted) return;
                          await SharePlus.instance.share(
                            ShareParams(
                              text: "من أذكار ${widget.azkarInfo.category}",
                              files: [XFile(file.path)],
                            ),
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
              if (marrat >= 10)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: toggleAutoPlay,
                            onLongPress: showIntervalDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isAutoPlaying ? Icons.pause : Icons.play_arrow,
                                size: 28,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('تلقائي',
                              style:
                                  TextStyle(fontFamily: 'Amiri', fontSize: 10)),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: resetCount,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh,
                                size: 28,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('تصفير',
                              style:
                                  TextStyle(fontFamily: 'Amiri', fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
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
            // Stop auto play when page changes
            isAutoPlaying = false;
            _timer?.cancel();
            setupAudioPlayer(
                _player, widget.azkarInfo.array[currentPageIndex].audio);
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: decrement,
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
