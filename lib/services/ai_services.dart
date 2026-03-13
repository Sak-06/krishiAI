import 'dart:io';
import 'dart:convert';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIServices {
  static final ImageLabeler _imageLabeler =
  GoogleMlKit.vision.imageLabeler(ImageLabelerOptions(
    confidenceThreshold: 0.50,    // best threshold
  ));

  //----------------------------------------------------
  // PRICE PREDICTION - API CALL
  //----------------------------------------------------
  static Future<Map<String, dynamic>> getPriceSuggestion({
    required String crop,
    required String location,
    String quality = 'medium',
    int quantity = 1,
  }) async {
    try {
      final apiUrl = dotenv.maybeGet('AI_BACKEND_URL');

      if (apiUrl == null || apiUrl.isEmpty) {
        print("❌ Missing API URL in .env");
        return _fallbackPrice(crop);
      }

      final response = await http
          .post(
        Uri.parse("$apiUrl/predict-price"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "crop": crop.toLowerCase(),
          "location": location,
          "season": _season(),
          "quality": quality,
          "quantity": quantity,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return _fallbackPrice(crop);
    } catch (e) {
      print("Price API Error: $e");
      return _fallbackPrice(crop);
    }
  }

  //----------------------------------------------------
  // IMAGE ANALYSIS - ML KIT
  //----------------------------------------------------
  static Future<Map<String, dynamic>> analyzeCropImage(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);

      final labels = await _imageLabeler.processImage(inputImage);

      final cropLabels = labels.where((l) =>
          _isCrop(l.label.toLowerCase())).toList();

      if (cropLabels.isEmpty) {
        return {
          "isCropDetected": false,
          "identifiedCrop": null,
          "quality": "unknown",
          "confidence": 0.0,
          "error": "No crop detected"
        };
      }

      final top = cropLabels.first;

      return {
        "isCropDetected": true,
        "identifiedCrop": _mapCrop(top.label),
        "confidence": top.confidence,
        "quality": _estimateQuality(labels),
        "error": null,
      };
    } catch (e) {
      return {
        "isCropDetected": false,
        "identifiedCrop": null,
        "quality": "unknown",
        "confidence": 0.0,
        "error": e.toString()
      };
    }
  }

  //----------------------------------------------------
  // HELPER FUNCTIONS
  //----------------------------------------------------

  static bool _isCrop(String label) {
    const crops = [
      "tomato", "potato", "onion", "carrot", "vegetable",
      "fruit", "wheat", "rice", "corn", "apple", "banana",
      "orange", "spinach", "lettuce", "cabbage", "broccoli",
      "cauliflower", "brinjal", "eggplant", "pepper", "chilli"
    ];

    return crops.any((c) => label.contains(c));
  }

  static String _mapCrop(String label) {
    final mapping = {
      "tomato": "Tomato",
      "potato": "Potato",
      "onion": "Onion",
      "carrot": "Carrot",
      "wheat": "Wheat",
      "rice": "Rice",
      "corn": "Corn",
      "apple": "Apple",
      "banana": "Banana",
      "orange": "Orange",
      "spinach": "Spinach",
      "lettuce": "Lettuce",
      "cabbage": "Cabbage",
      "broccoli": "Broccoli",
      "cauliflower": "Cauliflower",
      "brinjal": "Brinjal",
      "eggplant": "Brinjal",
      "pepper": "Green Chilli",
      "chilli": "Chilli"
    };

    label = label.toLowerCase();
    return mapping[label] ?? label;
  }

  static String _estimateQuality(List<ImageLabel> labels) {
    final fresh = labels.any((l) => l.label.toLowerCase().contains("fresh"));
    final ripe = labels.any((l) => l.label.toLowerCase().contains("ripe"));
    final rotten = labels.any((l) => l.label.toLowerCase().contains("rotten"));

    if (rotten) return "low";
    if (fresh && ripe) return "high";
    if (fresh) return "medium";

    return "medium";
  }

  static String _season() {
    final m = DateTime.now().month;

    if (m >= 3 && m <= 5) return "summer";
    if (m >= 6 && m <= 9) return "monsoon";
    return "winter";
  }

  static Map<String, dynamic> _fallbackPrice(String crop) {
    const defaultPrices = {
      "tomato": 25.0,
      "potato": 15.0,
      "onion": 30.0,
      "wheat": 20.0,
      "rice": 35.0,
      "carrot": 40.0,
      "spinach": 20.0,
      "cauliflower": 25.0,
      "cabbage": 18.0,
    };

    final price = defaultPrices[crop.toLowerCase()] ?? 20.0;

    return {
      "min_price": price * 0.8,
      "suggested_price": price,
      "max_price": price * 1.25,
      "market_avg": price,
      "confidence": 0.4,
      "source": "fallback"
    };
  }

  static void dispose() {
    _imageLabeler.close();
  }
}
