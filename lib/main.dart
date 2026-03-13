import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/farmer_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/chat_screen.dart';
import 'screens/smart_listing_screen.dart';
import 'screens/price_prediction_screen.dart';
import 'screens/crop_analysis_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env only for mobile/desktop
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DirectMarketApp());
}

class DirectMarketApp extends StatefulWidget {
  const DirectMarketApp({super.key});

  static _DirectMarketAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_DirectMarketAppState>();

  @override
  State<DirectMarketApp> createState() => _DirectMarketAppState();
}

class _DirectMarketAppState extends State<DirectMarketApp> {
  Locale _locale = const Locale('en'); // Default English

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Direct Market Access',
      debugShowCheckedModeBanner: false,
      locale: _locale,

      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const LoginScreen(),
        '/farmer': (context) => const FarmerDashboard(),
        '/buyer': (context) => const BuyerDashboard(),
        '/chat': (context) => const ChatScreen(),
        '/smart_listing': (context) => const SmartListingScreen(),
        '/price_prediction': (context) => const PricePredictionScreen(),
        '/crop_analysis': (context) => const CropAnalysisScreen(),
      },
    );
  }
}
