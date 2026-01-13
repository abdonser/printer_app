import 'package:flutter/material.dart';
import 'package:printer_app/presentation/screens/home_print_screen.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        //colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePrintScreen(),
    );
  }
}


