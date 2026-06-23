import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_dropzone_web/flutter_dropzone_plugin.dart';

void registerWebPluginsPlatform() {
  try {
    FlutterDropzonePlugin.registerWith(pluginRegistrar);
  } catch (e) {
    // Avoid double-registration error if already registered by the framework
  }
}
