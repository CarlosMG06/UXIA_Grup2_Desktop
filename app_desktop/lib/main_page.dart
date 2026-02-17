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
    AppData appData = Provider.of<AppData>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
          child: Text('Main Page')
        )
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Row(
              mainAxisAlignment: .center,
              children: [
                TextButton(
                  onPressed: () {
                    appData.disconnectFromServer(context);
                  },
                  child: Text("Disconnect")
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    appData.testToken(context);
                  },
                  child: Text("Test Token")
                ),
              ],
            ),
            SizedBox(height: 50),
            Table(
              border: TableBorder.all(),
              defaultColumnWidth:IntrinsicColumnWidth(),
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("ID", style: TextStyle(fontWeight: .bold), textAlign: .center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Nickname", style: TextStyle(fontWeight: .bold), textAlign: .center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Email", style: TextStyle(fontWeight: .bold), textAlign: .center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Actions", style: TextStyle(fontStyle: .italic), textAlign: .center),
                    ),
                  ]
                ),
                // Mostrar llista d'usuaris dinàmicament
                if (appData.userList.isNotEmpty)
                  ...appData.userList.map((user) {
                    return TableRow(
                      children: [
                        Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(user['user_id'].toString(), textAlign: .center),
                        ),
                        Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(user['nickname'].toString(), textAlign: .center),
                        ),
                        Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(user['email'].toString(), textAlign: .center),
                        ),
                        TextButton(
                          onPressed: () {
                            appData.eliminarUsuari(user['user_id'], context);
                          },
                          child: Text("Remove")
                        ),
                      ],
                    );
                  })
                else
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No users found', textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No users found', textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No users found', textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No users found', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: .center,
              children: [
                TextButton(
                  onPressed: () {
                    appData.listUsuaris(context);
                  }, 
                  child: Text("Update User List")
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    appData.afegirUsuari(context);
                  }, child: Text("Add")
                ),
              ],
            )
          ],
        ),
      ),

    );
  }
}