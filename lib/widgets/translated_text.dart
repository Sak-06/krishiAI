import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslatedText extends StatefulWidget {

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatedText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
      });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {

  String translated = "";

  @override
  void initState() {
    super.initState();
    translateText();
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // language change hone par dubara translate
    translateText();
  }

  Future<void> translateText() async {

    String result = await TranslationService.translate(widget.text);

    if (!mounted) return;

    setState(() {
      translated = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Text(
      translated.isEmpty ? widget.text : translated,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}