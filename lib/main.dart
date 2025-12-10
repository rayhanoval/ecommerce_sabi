import 'package:ecommerce_sabi/src/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/theme.dart';
import 'src/widgets/session_guard.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: "https://nygaawgyuyekadfleefb.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55Z2Fhd2d5dXlla2FkZmxlZWZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2NzI5ODEsImV4cCI6MjA3ODI0ODk4MX0.JoXpQOzSH_POEWBH0G0XLW1f_l1VfQSCHjOoubvhNwg");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SABI',
      theme: AppTheme.dark(),
      home: const SplashPage(),
      builder: (context, child) => SessionGuard(child: child!),
    );
  }
}
