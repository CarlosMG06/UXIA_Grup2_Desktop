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
  
  // Funció auxiliar per fer peticions POST, amb o sense autenticació
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

  // Funció auxiliar per fer peticions GET, amb o sense autenticació
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

  Future<void> connectToServer(String url, String email, String password, BuildContext context) async {
    if (!(url.isEmpty || email.isEmpty || password.isEmpty)) {
      // Preparar JSON
      Map<String, String> jsonData = {
        'email': email,
        'password': password,
      };
      String jsonString = jsonEncode(jsonData);
      
      String urlFinal = "$url/api/admin/usuaris/login";

      // POST
      var jsonResponse = await _loadHttpPostByChunks(urlFinal, jsonString, null);
      
      if (jsonResponse != null && jsonResponse["status"] == "OK") {
        // Anar a pàgina principal
        changeToMainPage(context);

        // Guardar token en settings.json
        apiKey = jsonResponse["data"]["token"];
        Map<String, String> settingsData = {
          'token': apiKey,
          'url': url,
          'email': email,
          'password': password,
        };
        String settingsString = jsonEncode(settingsData);
        File(settingsPath).writeAsStringSync(settingsString);

        listUsuaris(apiKey);
      }

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

  Future<void> listUsuaris(String apiKey) async {
    Map<String, dynamic> jsonResponse;
    Map<String, dynamic> jsonData;
    
    List<dynamic> list = [];
    String url = "http://uxia2.ieti.site/api/admin/usuaris";
    
    var response = await _loadHttpGetByChunks(url, apiKey);

    if (response != null && response["status"] == "OK") {
      list = response["data"];
      userList = list.where((element) => element != null).toList();

      print(userList);
    } else {
      print("Error del servidor (appData/listUsuaris)");
    }
  }

  void changeToMainPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  Future<void> disconnectFromServer(BuildContext context) async {
    // Obtenir token de settings.json
    String settingsString = File(settingsPath).readAsStringSync();
    Map<String, dynamic> settingsData = jsonDecode(settingsString);
    String apiKey = settingsData['token'];

    // Netejar settings.json
    settingsData = {'token': ""};
    settingsString = jsonEncode(settingsData);
    File(settingsPath).writeAsStringSync(settingsString);

    // POST
    String url = "http://uxia2.ieti.site/api/admin/usuaris/logout";
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

  void changeToLoginPage(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> testToken(BuildContext context) async {
    // Obtener token de settings.json
    String settingsString = File(settingsPath).readAsStringSync();
    Map<String, dynamic> settingsData = jsonDecode(settingsString);
    String apiKey = settingsData['token'];

    // Petición HTTP a servidor (.../api/admin/usuaris/testtoken)
    String url = "http://uxia2.ieti.site/api/admin/usuaris/testtoken";
    String jsonString = "{}";
    var jsonResponse = await _loadHttpPostByChunks(url, jsonString, apiKey);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Valid Token",
            style: TextStyle(color: Colors.green),
          ),
          content: const Text("The token is valid."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Invalid Token",
            style: TextStyle(color: Colors.red),
          ),
          content: const Text("The token is invalid."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    notifyListeners();
  }


  
  /*
  Future<void> _getList() async {
    var completer = Completer<void>();

    Map<String, dynamic> jsonResponse;
    Map<String, dynamic> jsonData;
    
    List<dynamic> list = [];
    String url = "http://uxia2.ieti.site/api/users/admin_get_list";
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Bearer $apiKey'
        }
      );

      if (response.statusCode == 200) {
        // La solicitud ha sido exitosa
        /// print('RESPONSE: ${response.body}');
        jsonResponse = jsonDecode(response.body);
        if (jsonResponse["status"] == "OK") {
          list = jsonResponse["data"];
          userList = list.where((element) => element != null).toList();
        }

        completer.complete();
      } else {
        // La solicitud ha fallado
        completer.completeError(
            "Error del servidor (appData/loadHttpPostByChunks): ${response.reasonPhrase}");
      }
    } catch (e) {
      completer.completeError("Excepción (appData/loadHttpPostByChunks): $e");
    }

    return completer.future;
    

  }
  */
}
