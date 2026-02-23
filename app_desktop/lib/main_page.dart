import 'dart:math';
import 'dart:ui';

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

  late AppData appData;

  @override
  Widget build(Object context) {
    AppData appData = Provider.of<AppData>(context, listen: true)

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              if (appData.tagList.isNotEmpty)
                ...appData.tagList.map((tagName) {
                  bool? selectTag;
                  return CheckboxListTile(
                    value: selectTag, 
                    onChanged: (bool? newValue) {
                      appData.selectTag(selectTag, tagName);
                    },
                    title: Text(tagName),
                  );
                })
              else Text("No tags found.")
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
                borderData: borderData,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
              )
            )
          )
        )
      ]
    );
  }

  BarTouchData get barTouchData => BarTouchData(
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
    String text = switch (value.toInt()) {
      0 => 'Mn',
      1 => 'Te',
      2 => 'Wd',
      3 => 'Tu',
      4 => 'Fr',
      5 => 'St',
      6 => 'Sn',
      _ => '',
    };
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

  FlBorderData get borderData => FlBorderData(
    show: false,
  );

  LinearGradient get _barsGradient => LinearGradient(
    colors: [
      Colors.deepPurple,
      Colors.cyan,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  List<BarChartGroupData> get barGroups => [
    BarChartGroupData(
      x: 0,
      barRods: [
        BarChartRodData(
          toY: 8,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 1,
      barRods: [
        BarChartRodData(
          toY: 10,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 2,
      barRods: [
        BarChartRodData(
          toY: 14,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 3,
      barRods: [
        BarChartRodData(
          toY: 15,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 4,
      barRods: [
        BarChartRodData(
          toY: 13,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 5,
      barRods: [
        BarChartRodData(
          toY: 10,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 6,
      barRods: [
        BarChartRodData(
          toY: 16,
          gradient: _barsGradient,
        )
      ],
      showingTooltipIndicators: [0],
    ),
  ];
}
