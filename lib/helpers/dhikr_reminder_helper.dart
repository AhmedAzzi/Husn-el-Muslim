import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/custom_dikr.dart';

class DhikrReminderHelper {
  static final DhikrReminderHelper _instance = DhikrReminderHelper._internal();
  factory DhikrReminderHelper() => _instance;
  DhikrReminderHelper._internal();

  Timer? _reminderTimer;
  bool isEnabled = true;
  int intervalMinutes = 15; // Default 15 minutes
  List<String> _adhkar = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled = prefs.getBool('dhikr_reminder_enabled') ?? true;
    intervalMinutes = prefs.getInt('dhikr_reminder_interval') ?? 15;

    await _loadAdhkarFromJson();

    if (isEnabled) {
      startTimer();
    }
  }

  Future<void> _loadAdhkarFromJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_dikr_list');

      List<dynamic> jsonList;
      if (saved != null) {
        jsonList = json.decode(saved);
      } else {
        final String jsonString =
            await rootBundle.loadString('assets/custom_dikr.json');
        jsonList = json.decode(jsonString);
      }

      _adhkar = jsonList
          .map((e) => CustomDikr.fromJson(e).arabic)
          .where((text) => text.length < 100) // Keep it short for overlay
          .toList();

      // Fallback if list is empty or fails
      if (_adhkar.isEmpty) {
        _adhkar = ["سبحان الله", "الحمد لله", "لا إله إلا الله", "الله أكبر"];
      }
    } catch (e) {
      _adhkar = ["سبحان الله", "الحمد لله", "لا إله إلا الله", "الله أكبر"];
    }
  }

  void startTimer() {
    _reminderTimer?.cancel();
    _reminderTimer =
        Timer.periodic(Duration(minutes: intervalMinutes), (timer) {
      if (isEnabled) {
        showReminder();
      }
    });
  }

  void stopTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  Future<void> updateSettings(bool enabled, int interval) async {
    isEnabled = enabled;
    intervalMinutes = interval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dhikr_reminder_enabled', enabled);
    await prefs.setInt('dhikr_reminder_interval', interval);

    if (isEnabled) {
      startTimer();
    } else {
      stopTimer();
    }
  }

  void showReminder([BuildContext? context]) {
    final effectiveContext = context ?? Get.overlayContext ?? Get.context;
    if (effectiveContext == null) return;

    final overlay = Overlay.maybeOf(effectiveContext);
    if (overlay == null) return;

    final randomDhikr = _adhkar[Random().nextInt(_adhkar.length)];

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => DhikrOverlayWidget(
        text: randomDhikr,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class DhikrOverlayWidget extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;

  const DhikrOverlayWidget({
    super.key,
    required this.text,
    required this.onDismiss,
  });

  @override
  State<DhikrOverlayWidget> createState() => _DhikrOverlayWidgetState();
}

class _DhikrOverlayWidgetState extends State<DhikrOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Start exit animation after 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Center the overlay vertically and horizontally
      top: MediaQuery.of(context).size.height / 2 - 50,

      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C35).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD64463).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD64463),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD64463),
                        shape: BoxShape.circle,
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
}
