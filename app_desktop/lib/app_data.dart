import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:app_desktop/main_page.dart';

class AppData extends ChangeNotifier {
  String apiKey = "";
  String settingsPath = "files/settings.json";

  double textFieldWidth = 305;
  double textFieldHeight = 40;

  List<dynamic> userList = [];
  
  Future<void> connectToServer(String url, String email, String password, BuildContext context) async {
    if (!(url.isEmpty || email.isEmpty || password.isEmpty)) {

      await _loadHttpPostByChunks(url, email, password, context);

      // await _getList();
      // print("getList done");
      // print(userList);

      notifyListeners();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Warning Error",
            style: TextStyle(color: Colors.red),
          ),
          content: const Text("All fields must be filled out."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadHttpPostByChunks(String url, String email, String password, BuildContext context) async {
    var completer = Completer<void>();

    Map<String, String> jsonData = {
      'email': email,
      'password': password,
    };
    String jsonString = jsonEncode(jsonData);

    Map<String, dynamic> jsonResponse;
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json', 
        },
        body: jsonString
      );

      if (response.statusCode == 200) {
        // Request Successful
        print('RESPONSE: ${response.body}');
        jsonResponse = jsonDecode(response.body);

        if (jsonResponse["status"] == "OK") {
          apiKey = jsonResponse["data"]["token"];
          changeToMainPage(context);
        }

        // Guardar token en settings.json
        Map<String, String> settingsData = {
          'token': apiKey,
          'url': url,
          'email': email,
          'password': password,
        };
        String settingsString = jsonEncode(settingsData);
        File(settingsPath).writeAsStringSync(settingsString);

        completer.complete();
      } else {
        // Request Failed
        completer.completeError(
            "Error del servidor (appData/loadHttpPostByChunks): ${response.reasonPhrase}");
      }
    } catch (e) {
      completer.completeError("Excepción (appData/loadHttpPostByChunks): $e");
    }

    return completer.future;
  }

  void changeToMainPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  // Future<void> _getList() async {
  //   var completer = Completer<void>();

  //   Map<String, dynamic> jsonResponse;
  //   Map<String, dynamic> jsonData;
    
  //   List<dynamic> list = [];
  //   String url = "http://uxia2.ieti.site/api/users/admin_get_list";
  //   try {
  //     var response = await http.post(
  //       Uri.parse(url),
  //       headers: {
  //         'Content-Type': 'application/json', 
  //         'Authorization': 'Bearer $apiKey'
  //       }
  //     );

  //     if (response.statusCode == 200) {
  //       // La solicitud ha sido exitosa
  //       /// print('RESPONSE: ${response.body}');
  //       jsonResponse = jsonDecode(response.body);
  //       if (jsonResponse["status"] == "OK") {
  //         list = jsonResponse["data"];
  //         userList = list.where((element) => element != null).toList();
  //       }

  //       completer.complete();
  //     } else {
  //       // La solicitud ha fallado
  //       completer.completeError(
  //           "Error del servidor (appData/loadHttpPostByChunks): ${response.reasonPhrase}");
  //     }
  //   } catch (e) {
  //     completer.completeError("Excepción (appData/loadHttpPostByChunks): $e");
  //   }

  //   return completer.future;
    

  // }
}