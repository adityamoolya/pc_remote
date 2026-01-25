import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/server_provider.dart';
import 'providers/pc_provider.dart';
import 'screens/connection_screen.dart';

void main() {
  runApp(const PCRemoteApp());
}

class PCRemoteApp extends StatelessWidget {
  const PCRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProxyProvider<ServerProvider, PCProvider>(
          create: (context) => PCProvider(context.read<ServerProvider>()),
          update: (context, server, previous) => 
              previous ?? PCProvider(server)..updateConnection(),
        ),
      ],
      child: MaterialApp(
        title: 'PC Remote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ConnectionScreen(),
      ),
    );
  }
}
