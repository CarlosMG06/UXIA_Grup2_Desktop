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

  //================//
  // Peticions HTTP //
  //================//
  
  // POST api/admin/usuaris/login
  Future<void> connectToServer(String url, String email, String password, BuildContext context) async {
    if (!(url.isEmpty || email.isEmpty || password.isEmpty)) {
      // Preparar JSON
      Map<String, String> jsonData = {
        'email': email,
        'password': password,
      };
      String jsonString = jsonEncode(jsonData);
      
      // POST
      String urlRequest = "$url/api/admin/usuaris/login";
      var jsonResponse = await _loadHttpPostByChunks(urlRequest, jsonString, null);
      if (jsonResponse != null && jsonResponse["status"] == "OK") {
        // Canviar a MainPage
        changeToMainPage(context);

        // Guardar dades de configuració
        String apiKey = jsonResponse["data"]["token"];
        saveSettingsData(apiKey, url, email, password);
        
        // Carregar llista d'usuaris
        await listUsuaris(apiKey);
      }

      notifyListeners();

    } else {
      showMessage(context, "Warning Error", "All fields must be filled out.", Colors.red);
    }
  }

  // GET api/admin/usuaris
  Future<void> listUsuaris(String apiKey) async {
    List<dynamic> list = [];

    String url = retrieveSettingsData('url');
    String urlRequest = "$url/api/admin/usuaris";
    
    var response = await _loadHttpGetByChunks(urlRequest, apiKey);
    if (response != null && response["status"] == "OK") {
      list = response["data"];
      userList = list.where((element) => element != null).toList();

      print(userList);
    } else {
      print("Error del servidor (appData/listUsuaris)");
    }
  }

  // POST api/admin/usuaris/logout
  Future<void> disconnectFromServer(BuildContext context) async {
    String apiKey = retrieveSettingsData('token');
    clearSettingsData();

    // POST
    String url = "https://uxia2.ieti.site/api/admin/usuaris/logout";
    String jsonString = "{}";
    var jsonResponse = await _loadHttpPostByChunks(url, jsonString, apiKey);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      print("Logout correcto. (Token válido)");
      changeToLoginPage(context);
    } else {
      print("Error en el logout. (Token inválido)");
    }
    notifyListeners();
  }

  // POST api/admin/usuaris/testtoken
  Future<void> testToken(BuildContext context) async {
    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('url');

    String urlRequest = "$url/api/admin/usuaris/testtoken";
    String jsonString = "{}";
    var jsonResponse = await _loadHttpPostByChunks(urlRequest, jsonString, apiKey);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      showMessage(context, "Valid Token", "The token is valid.", Colors.green);
    } else {
      showMessage(context, "Invalid Token", "The token is invalid.", Colors.red);
    }
    notifyListeners();
  }

  //======================//
  // Gestió settings.json //
  //======================//

  void saveSettingsData(String token, String url, String email, String password) {
    Map<String, String> settingsData = {
      'token': token,
      'url': url,
      'email': email,
      'password': password,
    };
    String settingsString = jsonEncode(settingsData);
    File(settingsPath).writeAsStringSync(settingsString);
  }
  
  String retrieveSettingsData(String key) {
    String settingsString = File(settingsPath).readAsStringSync();
    Map<String, dynamic> settingsData = jsonDecode(settingsString);
    return settingsData[key];
  }
  
  void clearSettingsData() {
    Map<String, String> settingsData = {
        'token': "", 
        'url': "",
        'email': "",
        'password': "",
    };
    String settingsString = jsonEncode(settingsData);
    File(settingsPath).writeAsStringSync(settingsString);
}

  //====================//
  // Funcions Auxiliars //
  //====================//

  // Canvis de pàgina
  void changeToMainPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  void changeToLoginPage(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Missatge emergent
  void showMessage(BuildContext context, String title, String message, Color titleColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Petició POST, amb o sense autenticació
  Future<Map<String, dynamic>?> _loadHttpPostByChunks(String url, String jsonString, String? apiKey) async {
    try {
      http.Response response;
      if (apiKey != null) {
        response = await http.post(
        Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': '$apiKey',
          },
          body: jsonString,
        );
      } else {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonString,
        );
      }
      if (response.statusCode == 200) {
        print('RESPONSE: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print("Error del servidor (appData/loadHttpPostByChunks): ${response.statusCode} \n${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción (appData/loadHttpPostByChunks): $e");
      return null;
    }
  }

  // Petició GET, amb o sense autenticació
  Future<Map<String, dynamic>?> _loadHttpGetByChunks(String url, String? apiKey) async {
    try {
      http.Response response;
      if (apiKey != null) {
        response = await http.get(
        Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': '$apiKey',
          },
        );
      } else {
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }
      if (response.statusCode == 200) {
        print('RESPONSE: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print("Error del servidor (appData/loadHttpGetByChunks): ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Excepción (appData/loadHttpGetByChunks): $e");
      return null;
    }
  }

}
