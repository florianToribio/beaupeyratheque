import 'package:beaupeyratheque_mobile/screens/home/home_screen.dart';
import 'package:beaupeyratheque_mobile/screens/login/login_screen.dart';
import 'package:beaupeyratheque_mobile/screens/preload/preload_screen.dart';
import 'package:beaupeyratheque_mobile/services/api_service.dart';
import 'package:flutter/material.dart';

final apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await apiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beaupeyratheque',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: PreloadPageRoute.routeName,
      onGenerateRoute: (settings) {
        return switch (settings.name) {
          PreloadPageRoute.routeName => PreloadPageRoute(),
          LoginPageRoute.routeName => LoginPageRoute(),
          HomePageRoute.routeName => HomePageRoute(),
          _ => null,
        };
      },
    );
  }
}
