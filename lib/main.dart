import 'package:flutter/material.dart';
import 'theme/risk_palette.dart';

void main() {
  runApp(const WildFireApp());
}

class WildFireApp extends StatelessWidget {
  const WildFireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WildFire MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: RiskPalette.brandForest,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WildFire Risk Assessment'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'WildFire Risk Assessment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'EffisService implementation in progress...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
