import 'package:ecommerce_sabi/src/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: "https://htptgxfylufqpnjldhps.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0cHRneGZ5bHVmcXBuamxkaHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMDgxNDEsImV4cCI6MjA3NzU4NDE0MX0.Qs5WbtDmvi60N8a3Wy8glCQuRdgcBhZ8Aqb3rrkMT0E");
  runApp(const MyApp());
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
    );
  }
}
