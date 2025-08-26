import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'utils/app_bindings.dart';
import 'views/web_view_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AppZap V2 - Sunmi Printer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // Initialize dependencies
      initialBinding: AppBindings(),
      // Set home screen
      home: const WebViewScreen(),
      // Global error handling
      unknownRoute: GetPage(
        name: '/unknown',
        page: () => const Scaffold(body: Center(child: Text('Page not found'))),
      ),
    );
  }
}
