import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/requests/data/recircle_api.dart';

void main() {
  final error = ReCircleApi.configurationError;
  runApp(error == null ? const ReCircleApp() : ApiConfigurationErrorApp(error));
}

class ApiConfigurationErrorApp extends StatelessWidget {
  const ApiConfigurationErrorApp(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('ReCircle configuration error\n\n$message', textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
