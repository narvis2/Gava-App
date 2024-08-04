import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gava/Profile/Login/LoginScreen.dart';
import 'package:gava/Firebase/FirebaseDBHelper.dart';
import 'package:gava/TabbarScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb && kDebugMode) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Optionally set a flag to indicate that Firebase initialization failed.
  }

  initializeDateFormatting('ko_KR', null);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedEmail = prefs.getString('email');
  final String? savedPassword = prefs.getString('password');

  runApp(MyApp(savedEmail: savedEmail, savedPassword: savedPassword));
}

class MyApp extends StatelessWidget {
  final String? savedEmail;
  final String? savedPassword;

  MyApp({this.savedEmail, this.savedPassword});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: createMaterialColor(Color(0xFF507AE9)),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor:
              Color(0xFF000000), // This sets the background color of the app
          fontFamily: 'Pretendard'),
      home: savedEmail != null && savedPassword != null
          ? TabbarScreen(email: savedEmail!, password: savedPassword!)
          : LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
