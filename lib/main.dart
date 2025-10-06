// main.dart
import 'package:flutter/material.dart';
import 'package:techie/provider/UserProvider.dart';
import 'MainAppWrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCu0cNLl-WxTlwQkh3vSuFJTrV1kKFTjuo",
      appId: "1:307700786183:android:0826cbe5001e418b1976a2",
      messagingSenderId: "307700786183",
      projectId: "techie-8e07b",
      databaseURL:
          "https://techie-8e07b-default-rtdb.asia-southeast1.firebasedatabase.app/",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainAppWrapper();
  }
}
