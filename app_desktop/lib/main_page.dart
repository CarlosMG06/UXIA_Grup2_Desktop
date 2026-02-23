import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_desktop/app_data.dart';
import 'package:fl_chart/fl_chart.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Admin Control Panel'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                appData.disconnectFromServer(context);
              },
              child: Text("Disconnect")
            ),
            TextButton(
              onPressed: () {
                appData.testToken(context);
              },
              child: Text("Test Token")
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.manage_accounts)),
              Tab(icon: Icon(Icons.sell))
            ]
          )
        ),
        body: TabBarView(
          children: [
            _UserManagement(),
            Center(child: _TagStats())
          ]
        ),
      ),
    );
  }
}

class _UserManagement extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserManagementState();
}

class _UserManagementState extends State<_UserManagement> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, appData, child) {
        return Column(
          mainAxisAlignment: .center,
          children: [
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
        );
    });
  }
}

class _TagStats extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TagStatsState();
}

class _TagStatsState extends State<_TagStats> {
  
  Map<String, int> selectedTags = // test data
    {"cat": 2, "classroom": 12, "hallway": 7, "school": 9, "mundane": 3};

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context, listen: true);

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              if (appData.tagList.isNotEmpty)
                ...appData.tagList.entries.map((entry) {
                  bool? selectTag;
                  return CheckboxListTile(
                    value: selectTag, 
                    onChanged: (bool? newValue) {
                      if (newValue == true) {
                        selectedTags[entry.key] = entry.value;
                      } else {
                        selectedTags.remove(entry.key);
                      }
                    },
                    title: Text(entry.key),
                  );
                })
              // else Text("No tags found."),
              else 
                ...selectedTags.entries.map((entry) {
                  bool? selectTag = false;
                  return CheckboxListTile(
                    value: selectTag, 
                    onChanged: (bool? newValue) {
                       setState(() => selectTag = newValue);
                      if (newValue == true) {
                        selectedTags[entry.key] = entry.value;
                      } else {
                        selectedTags.remove(entry.key);
                      }
                    },
                    title: Text(entry.key),
                  );
                }),
              TextButton(
                onPressed: () {
                  appData.listTags(context);
                },
                child: Text("Update Tags List")
              )
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsGeometry.all(64.0),
            child: BarChart(
              BarChartData(
                barTouchData: barTouchData,
                titlesData: titlesData,
                borderData: FlBorderData(show: false),
                barGroups: selectedTags.entries.map((entry) {
                  return BarChartGroupData(
                    x: selectedTags.entries.toList().indexOf(entry),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        gradient: _barsGradient,
                      )
                    ],
                  );
                }).toList(),
                gridData: const FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: selectedTags.values.isEmpty ? 0 : selectedTags.values.reduce((a, b) => a > b ? a : b).toDouble()*1.5
              )
            )
          )
        )
      ]
    );
  }

  BarTouchData get barTouchData =>
    BarTouchData(
      enabled: false,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 8,
        getTooltipItem:(group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            rod.toY.round().toString(),
            const TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
            )
          );
        },
      )
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.deepPurple,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text = selectedTags[selectedTags.keys.toList()[value.toInt()]].toString();
    return SideTitleWidget(
      meta: meta,
      space: 4,
      angle: pi/5,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: getTitles,
      ),
    ),
    leftTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  LinearGradient get _barsGradient => LinearGradient(
    colors: [
      Colors.deepPurple,
      Colors.cyan,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
