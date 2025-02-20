import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';

class Translate {
  static Map<String, Map<String, String>> _translations = {};

  static Future<void> load() async {
    // Load the JSON file from assets
    String jsonString = await rootBundle.loadString('assets/language.json');
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    
    // Convert to Map for easier access
    _translations = jsonMap.map((key, value) {
      Map<String, String> translation = Map<String, String>.from(value);
      return MapEntry(key, translation);
      
    });
  }

  // Fetch translation for a given word and language
  static String? translate(String key, String languageCode) {
    try {
      return _translations[key]?[languageCode];
    } catch (e) {
      return key; // Return the key if no translation is found
    }
  }
}
