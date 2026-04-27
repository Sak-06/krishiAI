// widgets/screen_translator.dart
import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class ScreenTranslator extends StatefulWidget {
  final Widget child;

  const ScreenTranslator({super.key, required this.child});

  @override
  State<ScreenTranslator> createState() => _ScreenTranslatorState();

  /// Helper method to translate a single string with cache

}

class _ScreenTranslatorState extends State<ScreenTranslator> {
  static final Map<String, String> _cache = {};

  static Future<String> translateTextCached(String text) async {
    if (TranslationService.currentLang == "en") return text;
    if (_cache.containsKey(text)) return _cache[text]!;

    try {
      final translated = await TranslationService.translate(text); // use helper
      _cache[text] = translated;
      return translated;
    } catch (e) {
      return text;
    }
  }
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}