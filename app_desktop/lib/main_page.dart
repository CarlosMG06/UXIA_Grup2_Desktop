import 'dart:collection';
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
  
  final List<Color> tagColorList = [Colors.blue, Colors.red, Colors.lime.shade600, Colors.green,
    Colors.deepPurple.shade400, Colors.orange.shade700, Colors.purple.shade300, Colors.blueGrey.shade400];
  final List<Color> tagBGColorList = [Colors.blue.shade100, Colors.red.shade100, Colors.lime.shade100, Colors.green.shade100,
    Colors.indigo.shade100, Colors.deepOrange.shade100, Colors.purple.shade50, Colors.blueGrey.shade100];
  
  late Map<String, int> selectedTags;
  final int maxSelectedTags = 12;
  Map<String, bool> checkboxStates = {};
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlySelected = false;

  // Llista ordenada de major a menor quantitat per al gràfic
  List<MapEntry<String, int>> sortedEntries = [];

  @override
  void initState() {
    super.initState();
    // LinkedHashMap per mantenir ordre de selecció
    selectedTags = LinkedHashMap<String, int>();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Filtrar les tags segons la cerca 
  List<MapEntry<String, int>> _getFilteredEntries(Map<String, int> map) {
    Iterable<MapEntry<String, int>> entries = map.entries;

    // Filtre de "només seleccionats"
    if (_showOnlySelected) {
      entries = entries.where((entry) => selectedTags.containsKey(entry.key));
    }
    
    // Filtre de cerca
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((entry) => 
          entry.key.toLowerCase().contains(_searchQuery));
    }
    
    return entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context, listen: true);

    // Determinar què llista fer servir
    Map<String, int> tagList = appData.tagList.isNotEmpty 
        ? appData.tagList 
        : appData.testTagList;

    // Obtenir llista filtrada
    List<MapEntry<String, int>> filteredEntries = _getFilteredEntries(tagList);

    // Info filtre
    int totalTags = tagList.length;
    int selectedCount = selectedTags.length;
    int filteredCount = filteredEntries.length;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              // Barra de cerca
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.grey)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cercar tags...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              
              // Info filtre i Switch Només seleccionats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(
                      MediaQuery.of(context).size.width < 800
                          ? ''
                          : (filteredCount > 0 
                              ? filteredCount == totalTags 
                                  ? 'Showing all $totalTags tags'
                                  : 'Showing $filteredCount / $totalTags tags' 
                              : ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      MediaQuery.of(context).size.width < 1000 
                          ? '' 
                          : selectedCount > 0 ? '$selectedCount selected' : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      mainAxisSize: .max,
                      children: [
                        Text(
                          'Only Selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: _showOnlySelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: _showOnlySelected,
                            onChanged: (value) {
                              setState(() {
                                _showOnlySelected = value;
                              });
                            },
                            activeThumbColor: Colors.blue,
                          ),
                        )
                      ],
                    ),
                  ]
                )
              ),

              // Llista de tags amb scroll
              Expanded(
                child: filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty 
                              ? _showOnlySelected 
                                  ? "No tags selected." 
                                  : "No tags available." 
                              : "No tags found with '$_searchQuery'",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return Center(
                            child: CheckboxListTile(
                            value: checkboxStates[entry.key] ?? false,
                            onChanged: (bool? newValue) {
                              setState(() {
                                if (selectedTags.length >= maxSelectedTags && newValue == true) {
                                  appData.showMessage(context, "Maximum Selected Tags Reached", "Please de-select another tag before selecting this one.", Colors.amber);
                                } else {
                                  checkboxStates[entry.key] = newValue ?? false;
                                  
                                  if (newValue == true) {
                                    selectedTags[entry.key] = entry.value;
                                  } else {
                                    selectedTags.remove(entry.key);
                                  }
                                  
                                  // Actualizar la llista ordenada en canviar els tags selccionats
                                  _updateSortedEntries();
                                }
                              });
                            },
                            title: Text(
                            entry.key, 
                            style: TextStyle(
                                color: getColorForTag(entry.key), 
                                fontWeight: selectedTags.containsKey(entry.key) ? FontWeight.bold : FontWeight.normal,
                              )
                            ),
                            activeColor: getColorForTag(entry.key),
                            tileColor: getBGColorForTag(entry.key) ?? Colors.transparent
                            )
                          );
                        },
                      ),
              ),

              // Botó d'actualitzar
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.grey)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        appData.listTags(context);
                      },
                      child: Text("Update Tags List")
                    )
                  )
                )
              )
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsetsGeometry.directional(
              top: 64.0,
              start: 16.0,
              end: 16.0,
              bottom: 32.0
            ),
            child: BarChart(
              BarChartData(
                barTouchData: barTouchData,
                titlesData: titlesData,
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  int index = entry.key;
                  MapEntry<String, int> tagEntry = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: tagEntry.value.toDouble(),
                        color: getColorForTag(tagEntry.key),
                      )
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
                gridData: const FlGridData(
                  horizontalInterval: 2,
                  drawVerticalLine: false,
                ),
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY
              )
            )
          )
        )
      ]
    );
  }

  void _updateSortedEntries() {
    sortedEntries = selectedTags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Color? getColorForTag(String tagKey) {
    List<String> selectedKeys = selectedTags.keys.toList();
    int index = selectedKeys.indexOf(tagKey);
    if (index == -1) return null;
    return tagColorList[index % tagColorList.length];
  }
  Color? getBGColorForTag(String tagKey) {
    List<String> selectedKeys = selectedTags.keys.toList();
    int index = selectedKeys.indexOf(tagKey);
    if (index == -1) return null;
    return tagBGColorList[index % tagBGColorList.length];
  }

  double get maxY {
    if (selectedTags.values.isEmpty) {
      return 10;
    }
    int maxValue = 0;
    for (int value in selectedTags.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return max(10, (maxValue / 5).ceil() * 5).toDouble();
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
              color: Colors.black,
              fontWeight: FontWeight.w600,
            )
          );
        },
      )
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    int index = value.toInt();

    if (index < 0 || index >= sortedEntries.length) {
        return Container();
    }

    String text = sortedEntries[index].key;
    return SideTitleWidget(
      meta: meta,
      space: 4,
      angle: pi/4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => 
    FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: getTitles,
        ),
      ),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 2,
          maxIncluded: false,
          minIncluded: false
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );

}
