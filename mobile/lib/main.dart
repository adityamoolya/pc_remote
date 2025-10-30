// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'connection_service.dart'; // Import our new service
import 'main_screen.dart'; // Import the correct MainScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the whole app in a provider.
    // This creates one instance of our ConnectionService and makes it
    // available to all widgets below it in the tree.
    return ChangeNotifierProvider(
      create: (context) => ConnectionService(),
      child: MaterialApp(
        title: 'Remote Control',
        theme: ThemeData.dark(),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
