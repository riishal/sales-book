import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:salesbook/l10n/app_localizations.dart';

import 'package:salesbook/provider/language_provider.dart';
import 'screens/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Please generate your own firebase_options.dart file by running the FlutterFire CLI.
  // See the official documentation for more information: https://firebase.flutter.dev/docs/cli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        // ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: const SalesApp(),
    ),
  );
}

class SalesApp extends StatelessWidget {
  const SalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        return MaterialApp(
          title: 'Sales Management',
          // Your selected language (en or ml)
          locale: langProvider.locale,

          // Supported languages
          supportedLocales: const [Locale('en'), Locale('ml')],

          // Critical Fix: Use Global delegates + fallback
          localizationsDelegates: const [
            AppLocalizations.delegate, // Your custom translations
            GlobalMaterialLocalizations
                .delegate, // For Material widgets (buttons, dialogs)
            GlobalWidgetsLocalizations.delegate, // For text direction (LTR/RTL)
            GlobalCupertinoLocalizations.delegate, // For iOS-style widgets
            DefaultMaterialLocalizations.delegate, // Fallback
          ],

          // This fixes the crash when switching to Malayalam
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            // Always respect user's choice
            if (langProvider.isMalayalam) {
              return const Locale('ml');
            }
            return const Locale('en');
          },

          // RTL support when Malayalam is active
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: langProvider.isMalayalam ? 'NotoSansMalayalam' : null,
            primaryColor: Colors.teal,
            primarySwatch: Colors.teal,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              primary: Colors.teal,
              secondary: Colors.teal,
            ),
            scaffoldBackgroundColor: Colors.grey[100],
            cardTheme: CardThemeData(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              shadowColor: Colors.black.withOpacity(0.05),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black54),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.grey[800]),
              bodyMedium: TextStyle(color: Colors.grey[600]),
              titleLarge: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.teal),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
