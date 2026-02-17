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

  // admin@domain.com
  // admin123
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
      var jsonResponse = await _loadHttpPostByChunks(urlRequest, jsonString, null, context);
      if (jsonResponse != null && jsonResponse["status"] == "OK") {
        // Canviar a MainPage
        changeToMainPage(context);

        // Guardar dades de configuració
        String apiKey = jsonResponse["data"]["token"];
        saveSettingsData(apiKey, url, email, password);
        
        // Carregar llista d'usuaris
        await listUsuaris(context);
      } else {
        showMessage(context, "Login Failed", "Invalid URL, email, or password.", Colors.red);
      }

      // Notificar canvis
      notifyListeners();
    } else {
      showMessage(context, "Warning Error", "All fields must be filled out.", Colors.red);
    }
  }

  // GET api/admin/usuaris
  Future<void> listUsuaris(BuildContext context) async {
    List<dynamic> list = [];

    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('urlHTTP');
    String urlRequest = "$url/api/admin/usuaris";
    
    // GET
    var response = await _loadHttpGetByChunks(urlRequest, apiKey, context);
    if (response != null && response["status"] == "OK") {
      // Guardar llista d'usuaris no nuls
      list = response["data"];
      userList = list.where((element) => element != null).toList();

      notifyListeners();
    } else {
      showMessage(context, "Error", "Failed to retrieve user list.", Colors.red);
    }
  }

  // POST api/admin/usuaris/logout
  Future<void> disconnectFromServer(BuildContext context) async {
    // Recuperar dades abans de netejar-les
    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('urlHTTPS');
    

    String urlRequest = "$url/api/admin/usuaris/logout";
    var jsonResponse = await _loadHttpPostByChunks(urlRequest, "{}", apiKey, context);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      showMessage(context, "Logout", "You have been successfully logged out.", Colors.green);
      clearSettingsData();
      changeToLoginPage(context);
    } else {
      showMessage(context, "Error", "Logout failed. Invalid token.", Colors.red);
    }
    notifyListeners();
  }

  // POST api/admin/usuaris/testtoken
  Future<void> testToken(BuildContext context) async {
    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('urlHTTPS');

    String urlRequest = "$url/api/admin/usuaris/testtoken";
    var jsonResponse = await _loadHttpGetByChunks(urlRequest, apiKey, context);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      showMessage(context, "Valid Token", "The token is valid.", Colors.green);
    } else {
      showMessage(context, "Invalid Token", "The token is invalid.", Colors.red);
    }
    notifyListeners();
  }

  // POST api/admin/usuaris/add
  Future<void> afegirUsuari(BuildContext context) async {
    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('urlHTTPS');

    String urlRequest = "$url/api/admin/usuaris/add";

    final jsonData = await showAddUserMessage(context);
    if (jsonData != null) {
      String jsonString = jsonEncode(jsonData);
      var jsonResponse = await _loadHttpPostByChunks(urlRequest, jsonString, apiKey, context);
      if (jsonResponse != null && jsonResponse["status"] == "OK") {
        showMessage(context, "Add User", "User added successfully.", Colors.green);
        
        // Actualitzar llista d'usuaris amb les dades default de la BBDD
        await listUsuaris(context);
      } else {
        showMessage(context, "Error", "Failed to add user.", Colors.red);
      }
    }
  }

  // POST api/admin/usuaris/remove
  Future<void> eliminarUsuari(int userId, BuildContext context) async {
    String apiKey = retrieveSettingsData('token');
    String url = retrieveSettingsData('urlHTTPS');

    Map<String, String> jsonData = {
      'user_id': userId.toString()
    };
    String jsonString = jsonEncode(jsonData);

    String urlRequest = "$url/api/admin/usuaris/remove";
    var jsonResponse = await _loadHttpPostByChunks(urlRequest, jsonString, apiKey, context);
    if (jsonResponse != null && jsonResponse["status"] == "OK") {
      showMessage(context, "Remove User", "User removed succesfully.", Colors.green);

      // Treure de la llista
      userList.removeWhere((user) => user['user_id'] == userId);

      notifyListeners();
    } else {
      showMessage(context, "Error", "Failed to remove user.", Colors.red);
    } 
  }

  //======================//
  // Gestió settings.json //
  //======================//

  void saveSettingsData(String token, String url, String email, String password) {
    Map<String, String> settingsData = {
      'token': token,
      'urlHTTPS': url,
      'urlHTTP': url.replaceAll("https://", "http://"),
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

  // Missatge emergent per afegir un usuari
  Future<Map<String, dynamic>?> showAddUserMessage(BuildContext context) async {
    final TextEditingController controllerId = TextEditingController();
    final TextEditingController controllerNickname = TextEditingController();
    final TextEditingController controllerEmail = TextEditingController();

    final result = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("Add User"),
        content: Column(
          children: [
            const Text('ID'),
            SizedBox(
              height: textFieldHeight,
              width: textFieldWidth,
              child: TextField(
                controller: controllerId,
              ),
            ),
            SizedBox(height: 5),
            const Text('Nickname'),
            SizedBox(
              height: textFieldHeight,
              width: textFieldWidth,
              child: TextField(
                controller: controllerNickname,
              ),
            ),
            SizedBox(height: 5),
            const Text("Email"),
            SizedBox(
              height: textFieldHeight,
              width: textFieldWidth,
              child: TextField(
                controller: controllerEmail,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final userData = {
                "user_id": controllerId.text,
                "nickname": controllerNickname.text,
                "email": controllerEmail.text
              };
              Navigator.pop(context, userData);
            },
            child: const Text("Add"))
        ],
      ));

    controllerId.dispose();
    controllerNickname.dispose();
    controllerEmail.dispose();

    return result;
  }
  // Petició POST, amb o sense autenticació
  Future<Map<String, dynamic>?> _loadHttpPostByChunks(String url, String jsonString, String? apiKey, BuildContext context) async {
    try {
      http.Response response;
      if (apiKey != null) {
        response = await http.post(
        Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
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
        return jsonDecode(response.body);
      } else {
        showMessage(context, "Server Error", "Status code: ${response.statusCode}\n${response.body}", Colors.red);
        return null;
      }
    } catch (e) {
      showMessage(context, "Client Exception", "Exception in loadHttpPostByChunks: $e", Colors.red);
      return null;
    }
  }

  // Petició GET, amb o sense autenticació
  Future<Map<String, dynamic>?> _loadHttpGetByChunks(String url, String? apiKey, BuildContext context) async {
    try {
      http.Response response;
      if (apiKey != null) {
        response = await http.get(
        Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
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
        return jsonDecode(response.body);
      } else {
        showMessage(context, "Server Error", "Status code: ${response.statusCode}\n${response.body}", Colors.red);
        return null;
      }
    } catch (e) {
      showMessage(context, "Client Exception", "Exception in loadHttpGetByChunks: $e", Colors.red);
      return null;
    }
  }

}
