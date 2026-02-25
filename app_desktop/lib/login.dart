import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_desktop/app_data.dart';
import 'dart:io';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController controllerURL = TextEditingController();
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Emplenar url i email si existeixen
    AppData appData = Provider.of<AppData>(context, listen: false);
    controllerURL.text = appData.retrieveSettingsData('urlHTTPS');
    controllerEmail.text = appData.retrieveSettingsData('email');
  }

  @override
  void dispose() {
    controllerURL.dispose();
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }
  
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
            const Text('URL'),
            SizedBox(
              height: appData.textFieldHeight,
              width: appData.textFieldWidth,
              child: TextField(
                controller: controllerURL,
              ),
            ),
            SizedBox(height: 5),
            const Text('Email'),
            SizedBox(
              height: appData.textFieldHeight,
              width: appData.textFieldWidth,
              child: TextField(
                controller: controllerEmail,
              ),
            ),
            SizedBox(height: 5),
            const Text("Password"),
            SizedBox(
              height: appData.textFieldHeight,
              width: appData.textFieldWidth,
              child: TextField(
                controller: controllerPassword,
              ),
            ),
            SizedBox(height: 5),
            MaterialButton(
              onPressed: () { 
                appData.connectToServer(controllerURL.text, controllerEmail.text, controllerPassword.text, context);
              },
              color: Colors.blue,
              child: Text(
                'Connect',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),

    );
  }
}