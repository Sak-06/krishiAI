import 'package:flutter/material.dart';

class AppTranslations {
  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Direct Market Access',
      'farmer_dashboard': 'Farmer Dashboard',
      'buyer_dashboard': 'Buyer Dashboard',
      'add_product': 'Add Product',
      'product_name': 'Product Name',
      'price_per_kg': 'Price per kg',
      'no_products': 'No products listed yet.',
      'offers': 'Offers',
      'dashboard':'Dashboard',
      'no_offers': 'No offers yet',
      'logout': 'Logout',
      'send_offer': 'Send Offer',
      'type_message': 'Type a message...',
      'price_prediction': 'Price Prediction',
      'crop_analysis': 'Crop Analysis',
      'smart_listing': 'Smart Listing',
      'chat': 'Chat',
      'language': 'Language',
      'check_back_later': 'Check back later for farmer listings.',
      'get_otp': 'Get OTP',
      'enter_mobile': 'Enter mobile number',
      'continue_google': 'Continue with Google',
      'or': 'OR',
      'enter_otp': 'Enter OTP',
      'verify': 'Verify',
      'tagline': 'Direct Market Access for Farmers',
      'profilesetup':'Lets setup your profile',
      'complete_your_profile':'Complete your profile to get started with KrashiAI'
    },
    'hi': {
      'app_title': 'सीधा बाजार पहुंच',
      'farmer_dashboard': 'किसान डैशबोर्ड',
      'buyer_dashboard': 'खरीदार डैशबोर्ड',
      'dashboard':'डैशबोर्ड',
      'add_product': 'उत्पाद जोड़ें',
      'product_name': 'उत्पाद का नाम',
      'price_per_kg': 'प्रति किलो कीमत',
      'no_products': 'अभी कोई उत्पाद सूचीबद्ध नहीं है।',
      'offers': 'ऑफर',
      'no_offers': 'अभी कोई ऑफर नहीं',
      'logout': 'लॉग आउट',
      'send_offer': 'ऑफर भेजें',
      'type_message': 'संदेश लिखें...',
      'price_prediction': 'मूल्य भविष्यवाणी',
      'crop_analysis': 'फसल विश्लेषण',
      'smart_listing': 'स्मार्ट लिस्टिंग',
      'chat': 'चैट',
      'language': 'भाषा',
      'check_back_later': 'किसान की सूची बाद में देखें।',
      'get_otp': 'ओटीपी प्राप्त करें',
      'enter_mobile': 'मोबाइल नंबर दर्ज करें',
      'continue_google': 'Google से जारी रखें',
      'or': 'या',
      'enter_otp': 'ओटीपी दर्ज करें',
      'verify': 'सत्यापित करें',
      'tagline': 'किसानों के लिए सीधा बाजार पहुंच',
      'profilesetup': 'अपना प्रोफ़ाइल सेट करें',
      'complete_your_profile':'KrashiAI का उपयोग शुरू करने के लिए अपना प्रोफ़ाइल पूर्ण करें'

    }
  };

  static String text(BuildContext context, String key) {
    String lang = Localizations.localeOf(context).languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']![key]!;
  }
}
