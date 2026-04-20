import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/home_provider.dart';

void main() {
  runApp(const MoSlidesApp());
}

class MoSlidesApp extends StatelessWidget {
  const MoSlidesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(),
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          return MaterialApp(
            title: 'MoSlides',
            debugShowCheckedModeBanner: false,
            themeMode: homeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4E45E4),
                brightness: Brightness.light,
              ),
              fontFamily: 'Segoe UI',
              appBarTheme: const AppBarTheme(
                scrolledUnderElevation: 1,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: false,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                shape: StadiumBorder(),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4E45E4),
                brightness: Brightness.dark,
              ),
              fontFamily: 'Segoe UI',
              appBarTheme: const AppBarTheme(
                scrolledUnderElevation: 1,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: false,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                shape: StadiumBorder(),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
