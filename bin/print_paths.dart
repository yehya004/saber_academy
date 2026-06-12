// ignore_for_file: avoid_print
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final docDir = await getApplicationDocumentsDirectory();
    print("getApplicationDocumentsDirectory: ${docDir.path}");
  } catch (e) {
    print("Error getting documents directory: $e");
  }
  try {
    final supportDir = await getApplicationSupportDirectory();
    print("getApplicationSupportDirectory: ${supportDir.path}");
  } catch (e) {
    print("Error getting support directory: $e");
  }
}
