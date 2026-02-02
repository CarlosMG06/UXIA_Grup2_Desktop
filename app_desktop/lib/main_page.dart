import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_desktop/app_data.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
          child: Text('Login')
        )
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
          ],
        ),
      ),

    );
  }
}