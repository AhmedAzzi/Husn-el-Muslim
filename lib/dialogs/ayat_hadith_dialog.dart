import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/prayer_times_logic.dart';

class AyatHadithDialog extends StatelessWidget {
  final String prayerName;
  final String content;

  const AyatHadithDialog({
    super.key,
    required this.prayerName,
    this.content =
        "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا",
  });

  @override
  Widget build(BuildContext context) {
    // Using PopScope to handle back button logic (stopping audio)
    return PopScope(
      canPop: false, // We handle popping manually
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    const Icon(
                      Icons.mosque,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      "حان الآن موعد $prayerName",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily:
                            'Amiri', // Keeping Amiri for Arabic esthetic
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "قال الله تعالى:",
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content Card (White Container)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Ayat/Hadith Text
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              height: 1.8,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Source
                          const Text(
                            "[سورة النساء: 103]",
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Close Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD64463),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _closeDialog,
                              child: const Text(
                                "إغلاق",
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _closeDialog() {
    PrayerTimesLogic().stopAudio();
    if (Get.isDialogOpen ?? false) {
      Get.back();
    } else {
      // In case it's pushed as a page
      Get.back();
    }
  }
}
