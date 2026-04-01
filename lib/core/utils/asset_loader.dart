import 'package:flutter/services.dart';

Future<String> loadAzkarJson() async {
  return await rootBundle.loadString('assets/hisnmuslim.json');
}
