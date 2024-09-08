import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/cobro_page.dart';
import 'pages/catalogo_page.dart';
import 'pages/inventario_page.dart';
import 'pages/reportes_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papelería App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginPage());
          case '/home':
            return MaterialPageRoute(builder: (_) => HomePage());
          default:
            return MaterialPageRoute(builder: (_) => LoginPage());
        }
      },
    );
  }
}
