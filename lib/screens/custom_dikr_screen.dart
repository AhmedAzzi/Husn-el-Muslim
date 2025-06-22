import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_dikr.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';

class CustomDikrScreen extends StatefulWidget {
  const CustomDikrScreen({Key? key}) : super(key: key);

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

  void addCustomDikr(CustomDikr dikr) {
    setState(() {
      dikrList.add(dikr);
    });
    saveDikrList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تمت إضافة الذكر بنجاح!', style: TextStyle(fontFamily: 'Amiri')),
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
          child: Text('تم تعديل الذكر بنجاح!', style: TextStyle(fontFamily: 'Amiri')),
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
          child: Text('تم حذف الذكر بنجاح!', style: TextStyle(fontFamily: 'Amiri')),
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
    int count = 33;
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختر عدد التسبيحات'),
            content: TextField(
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(hintText: 'عدد التسبيحات (افتراضي 33)'),
              onChanged: (val) {
                count = int.tryParse(val) ?? 33;
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
                        onMaxScore: (score) {
                          setState(() {
                            if (score > dikr.maxScore)
                              dikrList[index].maxScore = score;
                          });
                        },
                      ),
                    ),
                  );
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('مسبحة', style: TextStyle(fontFamily: 'Amiri')),
            flexibleSpace: SizedBox(
              height: 60,
              child: Image.asset(
                appBarBG,
                fit: BoxFit.cover,
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: dikrList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add new dikr card
                return Card(
                  color: Colors.green[50],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: ListTile(
                    leading:
                        const Icon(Icons.add, color: Colors.green, size: 32),
                    title: const Text(
                      'إضافة ذكر جديد',
                      style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: showAddDikrDialog,
                  ),
                );
              }
              final dikr = dikrList[index - 1];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  // contentPadding: EdgeInsets.zero,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      dikr.arabic,
                      style: const TextStyle(fontSize: 20, fontFamily: 'Amiri'),
                    ),
                  ),
                  onTap: () => showCounterModal(dikr, index - 1),
                  onLongPress: () => showDikrOptions(context, index - 1),
                  trailing: dikr.maxScore > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('الأعلى'),
                            Text('${dikr.maxScore}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      : null,
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
  const AddEditDikrSheet({Key? key, this.dikr, required this.onSave})
      : super(key: key);

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
  final void Function(int maxScore) onMaxScore;
  const DikrCounterScreen(
      {Key? key,
      required this.dikr,
      required this.initialCount,
      required this.onMaxScore})
      : super(key: key);

  @override
  State<DikrCounterScreen> createState() => _DikrCounterScreenState();
}

class _DikrCounterScreenState extends State<DikrCounterScreen> {
  int count = 0;
  int maxScore = 0;
  late int limit;

  @override
  void initState() {
    super.initState();
    count = 0;
    maxScore = widget.dikr.maxScore;
    limit = widget.initialCount;
  }

  void increment() {
    setState(() {
      if (count < limit) {
        count++;
        if (count == limit && count > maxScore) {
          maxScore = count;
          widget.onMaxScore(maxScore);
        }
      }
    });
  }

  void decrement() {
    setState(() {
      if (count > 0) count--;
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
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        padding: const EdgeInsets.only(top: 5, bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.grey, width: 0.5),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                            ),
                            child: ListTile(
                              title: Text(
                                widget.dikr.arabic,
                                style: const TextStyle(
                                    fontFamily: 'Amiri', fontSize: 28),
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (widget.dikr.benefit != null)
                        ListTile(
                          title: Text(
                            'الفضل: ${widget.dikr.benefit!}',
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (widget.dikr.reference != null)
                        ListTile(
                          title: Text(
                            'المصدر: ${widget.dikr.reference!}',
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
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
                              '$limit مرة',
                              style: TextStyle(
                                fontSize: double.parse(fontSize18),
                                color: bgLight,
                                fontFamily: 'Amiri',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 0, right: 15),
                              child: Text(
                                '$count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: double.parse(fontSize22),
                                    fontFamily: 'Amiri',
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'الأعلى: $maxScore',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: double.parse(fontSize18),
                                  color: bgLight,
                                  fontFamily: 'Amiri'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 32),
                          onPressed: decrement,
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.add, size: 32),
                          onPressed: increment,
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
}
