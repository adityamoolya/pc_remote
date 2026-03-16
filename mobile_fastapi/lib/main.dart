import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/connection_provider.dart';
import 'screens/connection_mode_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PCRemoteApp());
}

class PCRemoteApp extends StatelessWidget {
  const PCRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectionProvider()..init(),
      child: MaterialApp(
        title: 'PC Remote',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF161B22),
            primary: Color(0xFF58A6FF),
            secondary: Color(0xFF3FB950),
            error: Color(0xFFF85149),
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF161B22),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0D1117),
            elevation: 0,
            centerTitle: false,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF0D1117),
            selectedItemColor: Color(0xFF58A6FF),
            unselectedItemColor: Color(0xFF8B949E),
          ),
        ),
        home: const ConnectionModeScreen(),
      ),
    );
  }
}