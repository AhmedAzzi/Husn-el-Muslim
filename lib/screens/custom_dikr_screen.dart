import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/custom_dikr.dart';
import '../constants/strings.dart';

class CustomDikrScreen extends StatefulWidget {
  const CustomDikrScreen({super.key});

  @override
  State<CustomDikrScreen> createState() => _CustomDikrScreenState();
}

class _CustomDikrScreenState extends State<CustomDikrScreen> {
  List<CustomDikr> dikrList = [];

  static const String customDikrKey = 'custom_dikr_list';

  Future<void> saveDikrList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = dikrList.map((e) => e.toJson()).toList();
    await prefs.setString(customDikrKey, json.encode(jsonList));
  }

  Future<void> loadDikrList() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(customDikrKey);
    if (saved != null) {
      final List<dynamic> jsonList = json.decode(saved);
      setState(() {
        dikrList = jsonList.map((e) => CustomDikr.fromJson(e)).toList();
      });
    } else {
      await loadDefaultDikr();
    }
  }

  @override
  void initState() {
    super.initState();
    loadDikrList();
  }

  Future<void> loadDefaultDikr() async {
    final String jsonString =
        await rootBundle.loadString('assets/custom_dikr.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      dikrList = jsonList.map((e) => CustomDikr.fromJson(e)).toList();
    });
  }

  Future<void> exportData() async {
    try {
      final jsonList = dikrList.map((e) => e.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Let user choose directory to save the file
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد الحفظ',
      );

      if (selectedDirectory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'dikr_backup_$timestamp.json';
        final file = File('$selectedDirectory/$fileName');
        await file.writeAsString(jsonString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ النسخة الاحتياطية: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e')),
      );
    }
  }

  Future<void> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          dikrList = jsonList.map((e) => CustomDikr.fromJson(e)).toList();
        });
        saveDikrList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استيراد البيانات بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستيراد: $e')),
      );
    }
  }

  void addCustomDikr(CustomDikr dikr) {
    setState(() {
      dikrList.add(dikr);
    });
    saveDikrList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تمت إضافة الذكر بنجاح!',
              style: TextStyle(fontFamily: 'Amiri')),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void editCustomDikr(int index, CustomDikr dikr) {
    setState(() {
      dikrList[index] = dikr;
    });
    saveDikrList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تم تعديل الذكر بنجاح!',
              style: TextStyle(fontFamily: 'Amiri')),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void deleteCustomDikr(int index) {
    setState(() {
      dikrList.removeAt(index);
    });
    saveDikrList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تم حذف الذكر بنجاح!',
              style: TextStyle(fontFamily: 'Amiri')),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showAddDikrDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEditDikrSheet(onSave: addCustomDikr),
      ),
    );
  }

  void showEditDikrDialog(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEditDikrSheet(
          dikr: dikrList[index],
          onSave: (dikr) => editCustomDikr(index, dikr),
        ),
      ),
    );
  }

  void showCounterModal(CustomDikr dikr, int index) {
    int count = 0;
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختر عدد التسبيحات'),
            content: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'عدد التسبيحات (افتراضي مفتوح)'),
              onChanged: (val) {
                count = int.tryParse(val) ?? 0;
              },
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DikrCounterScreen(
                        dikr: dikr,
                        initialCount: count,
                        onUpdate: (newMaxScore, totalDelta) {
                          setState(() {
                            dikrList[index].maxScore = newMaxScore;
                            dikrList[index].totalCount += totalDelta;
                          });
                        },
                      ),
                    ),
                  ).then((_) => saveDikrList()); // Save when closing
                },
                child: const Text('ابدأ'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showDikrOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('تعديل',
                      style: TextStyle(fontFamily: 'Amiri')),
                  onTap: () {
                    Navigator.pop(context);
                    showEditDikrDialog(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title:
                      const Text('حذف', style: TextStyle(fontFamily: 'Amiri')),
                  onTap: () {
                    Navigator.pop(context);
                    deleteCustomDikr(index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalScore = dikrList.fold(0, (sum, item) => sum + item.totalCount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A24), // Dark background
          appBar: AppBar(
            backgroundColor: const Color(0xFF693B42), // Dark Red/Purple
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('مسبحة',
                style: TextStyle(fontFamily: 'Amiri', color: Colors.white)),
            // centerTitle: true,
            actions: [
              Row(
                children: [
                  Text(
                    '$totalScore',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.diamond, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'export') {
                    exportData();
                  } else if (value == 'import') {
                    importData();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('تصدير البيانات'),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Text('استيراد البيانات'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: dikrList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add new dikr button
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Color(0xFF8B3D4D), size: 28),
                        SizedBox(width: 8),
                        Text(
                          'إضافة ذكر جديد',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            color: Color(0xFF8B3D4D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: showAddDikrDialog,
                  ),
                );
              }
              final dikr = dikrList[index - 1];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C35), // Dark card color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: Text(
                    dikr.arabic,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Amiri',
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${dikr.maxScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.diamond,
                          color: Color(0xFFD64463), size: 20), // Pink diamond
                    ],
                  ),
                  onTap: () => showCounterModal(dikr, index - 1),
                  onLongPress: () => showDikrOptions(context, index - 1),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AddEditDikrSheet extends StatefulWidget {
  final CustomDikr? dikr;
  final void Function(CustomDikr) onSave;
  const AddEditDikrSheet({super.key, this.dikr, required this.onSave});

  @override
  State<AddEditDikrSheet> createState() => _AddEditDikrSheetState();
}

class _AddEditDikrSheetState extends State<AddEditDikrSheet> {
  late TextEditingController dikrController;
  late TextEditingController benefitController;
  late TextEditingController referenceController;

  @override
  void initState() {
    super.initState();
    dikrController = TextEditingController(text: widget.dikr?.arabic ?? '');
    benefitController = TextEditingController(text: widget.dikr?.benefit ?? '');
    referenceController =
        TextEditingController(text: widget.dikr?.reference ?? '');
  }

  @override
  void dispose() {
    dikrController.dispose();
    benefitController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.dikr == null ? 'إضافة ذكر' : 'تعديل ذكر',
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dikrController,
              decoration: const InputDecoration(
                  labelText: 'الذكر *', border: OutlineInputBorder()),
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: benefitController,
              decoration: const InputDecoration(
                  labelText: 'الفضل', border: OutlineInputBorder()),
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                  labelText: 'المصدر', border: OutlineInputBorder()),
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (dikrController.text.trim().isEmpty) return;
                      widget.onSave(
                        CustomDikr(
                          arabic: dikrController.text.trim(),
                          benefit: benefitController.text.trim().isEmpty
                              ? null
                              : benefitController.text.trim(),
                          reference: referenceController.text.trim().isEmpty
                              ? null
                              : referenceController.text.trim(),
                          maxScore: widget.dikr?.maxScore ?? 0,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DikrCounterScreen extends StatefulWidget {
  final CustomDikr dikr;
  final int initialCount;
  final void Function(int maxScore, int totalDelta) onUpdate;
  const DikrCounterScreen(
      {super.key,
      required this.dikr,
      required this.initialCount,
      required this.onUpdate});

  @override
  State<DikrCounterScreen> createState() => _DikrCounterScreenState();
}

class _DikrCounterScreenState extends State<DikrCounterScreen> {
  int count = 0;
  late int startingMaxScore;
  late int limit;
  Timer? _timer;
  bool isAutoPlaying = false;
  int autoIncrementInterval = 1000; // milliseconds

  @override
  void initState() {
    super.initState();
    count = 0;
    startingMaxScore = widget.dikr.maxScore;
    limit = widget.initialCount;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        increment();
      });
    }
  }

  void showIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempInterval = autoIncrementInterval;
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
                            });
                          },
                        ),
                        Text((tempInterval / 1000).toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (tempInterval > 100) tempInterval -= 100;
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
                      this.setState(() {
                        autoIncrementInterval = tempInterval;
                        if (isAutoPlaying) {
                          // Restart timer with new interval
                          _timer?.cancel();
                          _timer = Timer.periodic(
                              Duration(milliseconds: autoIncrementInterval),
                              (timer) {
                            increment();
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
      count = 0;
      isAutoPlaying = false;
      _timer?.cancel();
    });
  }

  void increment() {
    setState(() {
      if (limit == 0 || count < limit) {
        count++;
        int currentMaxScore =
            count > startingMaxScore ? count : startingMaxScore;
        widget.onUpdate(currentMaxScore, 1);
      }
    });
  }

  void decrement() {
    setState(() {
      if (count > 0) {
        count--;
        int currentMaxScore =
            count > startingMaxScore ? count : startingMaxScore;
        widget.onUpdate(currentMaxScore, -1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title:
                const Text('عداد الذكر', style: TextStyle(fontFamily: 'Amiri')),
            flexibleSpace: SizedBox(
              height: 60,
              child: Image.asset(
                appBarBG,
                fit: BoxFit.cover,
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(child: Container()),
                    Expanded(child: Container()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onTap: increment,
                  child: ListView(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 0.5),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: ListTile(
                            title: Text(
                              widget.dikr.arabic,
                              style: const TextStyle(
                                  fontFamily: 'Amiri', fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (widget.dikr.benefit != null)
                        ListTile(
                          dense: true,
                          title: Text(
                            'الفضل: ${widget.dikr.benefit!}',
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (widget.dikr.reference != null)
                        ListTile(
                          dense: true,
                          title: Text(
                            'المصدر: ${widget.dikr.reference!}',
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Auto Play and Reset Buttons
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
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
              // Bottom Counter Bar
              Container(
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(counterBG),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Target Limit (Right)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            limit == 0 ? 'مفتوح' : '$limit مرة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Center Rosary (Misbaha)
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Image.asset('assets/sabha.png', height: 60),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Max Score (Left)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            '${count > startingMaxScore ? count : startingMaxScore}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
