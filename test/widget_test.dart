import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                'Flutter is Working!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Android Studio setup is successful.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  debugPrint('Button clicked!');
                },
                child: const Text('Test Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}