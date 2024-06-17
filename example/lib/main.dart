import 'package:custom_loading_loader/custom_loading_loader.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Custom Loading Indicator Example')),
        body: Center(
          child: CustomLoadingIndicator(
            image: AssetImage('assets/image.png'),
            size: 100.0,
            loaderColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        ),
      ),
    );
  }
}
