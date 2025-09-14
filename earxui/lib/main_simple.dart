import 'package:flutter/material.dart';

void main() => runApp(const SimpleApp());

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF2A1B3D),
        appBar: AppBar(
          title: const Text('Simple Test', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2A1B3D),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Flutter App Running',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                'No white screen!',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}