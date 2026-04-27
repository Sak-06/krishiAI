import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {

  static String currentLang = "en";

  static const String apiKey = "579614ab5dmshf7af67fb5847696p19a0a6jsnf8aa9bcda182";

  /// cache for translated text
  static final Map<String,String> _cache = {};

  static void changeLanguage(String lang) {
    currentLang = lang;
    _cache.clear();
    print("Language changed: $lang");
  }

  /// BULK TRANSLATE
  static Future<Map<String,String>> translateBulk(List<String> texts) async {

    Map<String,String> result = {};

    /// if english return same
    if(currentLang == "en") {
      for(var t in texts){
        result[t] = t;
      }
      return result;
    }

    /// check cache first
    List<String> needTranslation = [];

    for(String t in texts){
      String key = "$currentLang|$t";

      if(_cache.containsKey(key)){
        result[t] = _cache[key]!;
      } else {
        needTranslation.add(t);
      }
    }

    /// if everything cached
    if(needTranslation.isEmpty){
      return result;
    }

    try{

      final response = await http.post(
          Uri.parse("https://openl-translate.p.rapidapi.com/translate/bulk"),
          headers: {
            "Content-Type":"application/json",
            "x-rapidapi-key": apiKey,
            "x-rapidapi-host": "openl-translate.p.rapidapi.com"
          },
          body: jsonEncode({
            "target_lang": currentLang,
            "text": needTranslation
          })
      );

      final data = jsonDecode(response.body);

      List translated = data["data"]?["translatedText"]
          ?? data["translated"]
          ?? [];

      for(int i=0;i<needTranslation.length;i++){

        String original = needTranslation[i];
        String translatedText = translated[i];

        result[original] = translatedText;

        _cache["$currentLang|$original"] = translatedText;
      }

      return result;

    }catch(e){

      print("TRANSLATION ERROR $e");

      for(var t in texts){
        result[t] = t;
      }

      return result;
    }
  }
  /// Helper for translating a single string
  static Future<String> translate(String text) async {
    final map = await translateBulk([text]); // call the bulk method
    return map[text] ?? text; // return single translated string
  }
}
/*const http = require('https');

const options = {
	method: 'POST',
	hostname: 'openl-translate.p.rapidapi.com',
	port: null,
	path: '/translate/bulk',
	headers: {
		'x-rapidapi-key': '579614ab5dmshf7af67fb5847696p19a0a6jsnf8aa9bcda182',
		'x-rapidapi-host': 'openl-translate.p.rapidapi.com',
		'Content-Type': 'application/json'
	}
};

const req = http.request(options, function (res) {
	const chunks = [];

	res.on('data', function (chunk) {
		chunks.push(chunk);
	});

	res.on('end', function () {
		const body = Buffer.concat(chunks);
		console.log(body.toString());
	});
});

req.write(JSON.stringify({
  target_lang: 'es',
  text: [
    'Hello, how are you?',
    'The weather is nice today.',
    'I love programming.'
  ]
}));
req.end();*/
