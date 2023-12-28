import 'dart:async';
import 'dart:math';

import 'package:find_your_way/data/map_config.dart';
import 'package:find_your_way/data/path_finder.dart';
import 'package:find_your_way/data/position.dart';
import 'package:find_your_way/data/trilateration.dart';
import 'package:find_your_way/manager/mqtt_manager.dart';
import 'package:find_your_way/provider/map_data.dart';
import 'package:find_your_way/provider/trilateration_data.dart';
import 'package:find_your_way/widgets/home/home.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurfaceMap extends StatefulWidget {
  final MqttManager mqttManager;

  const SurfaceMap({super.key, required this.mqttManager});

  @override
  State<SurfaceMap> createState() => _SurfaceMapState();
}

class _SurfaceMapState extends State<SurfaceMap> {
  late List<List<String>> mapMatrix;
  late List<List<String>> originalMapMatrix;

  Color openNodeColor = Colors.green;
  Color closedNodeColor = Colors.red;
  Color joinNodeColor = Colors.blue;
  Color beaconNodeColor = Colors.orange;
  Color privateNodeColor = Colors.purple;
  Color userNodeColor = Colors.yellow;
  Color selectedNodeColor = Colors.amber;
  Color pathNodeColor = Colors.cyan;

  late Trilateration triangulation;

  MapConfig? mapConfig;

  int? lastClickedRow;
  int? lastClickedCol;

  late Timer _updateTimer;

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      openNodeColor =
          Color(prefs.getInt('openNodeColor') ?? Colors.green.value);
      closedNodeColor =
          Color(prefs.getInt('closedNodeColor') ?? Colors.red.value);
      joinNodeColor = Color(prefs.getInt('joinNodeColor') ?? Colors.blue.value);
      beaconNodeColor =
          Color(prefs.getInt('beaconNodeColor') ?? Colors.orange.value);
      privateNodeColor =
          Color(prefs.getInt('privateNodeColor') ?? Colors.purple.value);
      userNodeColor =
          Color(prefs.getInt('userNodeColor') ?? Colors.yellow.value);
      selectedNodeColor =
          Color(prefs.getInt('selectedNodeColor') ?? Colors.amber.value);
      pathNodeColor = Color(prefs.getInt('pathNodeColor') ?? Colors.cyan.value);
    });
  }

  @override
  void initState() {
    super.initState();

    mapConfig = Provider.of<MapData>(context, listen: false).mapConfig;

    mapMatrix = _parseInput(mapConfig!.mapConfig);
    originalMapMatrix = List.generate(
      mapMatrix.length,
      (i) => List.generate(mapMatrix[i].length, (j) => mapMatrix[i][j]),
    );

    List<Position> beaconPositions = _findBeaconPositions();
    triangulation = Trilateration(beaconsPosition: beaconPositions);

    _updateTimer = Timer.periodic(const Duration(milliseconds: 700), (Timer t) {
      _updateUserPositionPeriodically();
    });
  }

  List<Position> _findBeaconPositions() {
    List<Position> positions = [];

    for (int i = 0; i < mapMatrix.length; i++) {
      for (int j = 0; j < mapMatrix[i].length; j++) {
        if (mapMatrix[i][j].startsWith('X')) {
          positions.add(Position(i.toDouble(), j.toDouble()));
          if (positions.length == 3) break;
        }
      }
    }

    // Add default positions if less than three beacons are found
    if (positions.length < 3) {
      List<Position> defaultPositions = [
        Position(0, 0), // Top left corner
        Position(
          0,
          mapMatrix[0].length - 1.0,
        ), // Top right corner
        Position(
          mapMatrix.length - 1.0,
          mapMatrix[0].length - 1.0,
        ) // Bottom right corner
      ];

      positions.addAll(defaultPositions.take(3 - positions.length));
    }

    return positions;
  }

  List<Point<int>> path = [];

  void calculateAndDisplayPath() {
    int startX = 0, startY = 0;
    for (int i = 0; i < mapMatrix.length; i++) {
      for (int j = 0; j < mapMatrix[i].length; j++) {
        if (mapMatrix[i][j] == 'U') {
          startX = i;
          startY = j;
          break;
        }
      }
    }

    if (lastClickedRow != null && lastClickedCol != null) {
      Point<int> start = Point(startX, startY);
      Point<int> goal = Point(lastClickedRow!, lastClickedCol!);
      PathFinder pathFinder = PathFinder(mapMatrix, start, goal);

      setState(() {
        path = pathFinder.findPath();
      });
    }
  }

  void customBackButtonBehavior() {
    widget.mqttManager.disconnect();

    Navigator.of(context).pop();
  }

  void _updateUserPositionPeriodically() {
    TrilaterationData triangulationData =
        Provider.of<TrilaterationData>(context, listen: false);

    if (triangulationData.devicesDistance.length >= 3) {
      if (triangulationData.devicesDistance.values
          .any((element) => element.isEmpty)) return;

      var distances = triangulationData.devicesDistance.values
          .map((list) => list.last)
          .toList();

      // Assuming the first three devices are the ones we're interested in
      var newPosition = triangulation.calculatePosition(
          distances[0], distances[1], distances[2]);

      if (newPosition != null) {
        _updateMapMatrixWithNewPosition(newPosition);
      }
    }
  }

  void _updateMapMatrixWithNewPosition(Position newPosition) {
    for (int i = 0; i < mapMatrix.length; i++) {
      for (int j = 0; j < mapMatrix[i].length; j++) {
        if (mapMatrix[i][j] == 'U') {
          mapMatrix[i][j] = originalMapMatrix[i][j];
          break;
        }
      }
    }

    int newX = min(max(newPosition.x.round(), 0), mapMatrix.length - 1);
    int newY = min(max(newPosition.y.round(), 0), mapMatrix[0].length - 1);

    Position adjustedPosition =
        findClosestOpenNode(Position(newX.toDouble(), newY.toDouble()));

    // TODO: Here check if we go over a node that is set as 3 (private area),
    // and if we walk over the area, we will notify a server that a user went
    // in a private area of the map!

    mapMatrix[adjustedPosition.x.toInt()][adjustedPosition.y.toInt()] = 'U';

    setState(() {});
  }

  Position findClosestOpenNode(Position currentPosition) {
    int x = currentPosition.x.round();
    int y = currentPosition.y.round();

    // Check if the current position is open
    if (isOpenNode(x, y)) {
      return currentPosition;
    }

    // Search radius
    int radius = 1;
    while (radius < max(mapMatrix.length, mapMatrix[0].length)) {
      // Check cells around the current position within the radius
      for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
          int newX = x + i;
          int newY = y + j;

          // Check bounds and if the node is open
          if (newX >= 0 &&
              newX < mapMatrix.length &&
              newY >= 0 &&
              newY < mapMatrix[0].length &&
              isOpenNode(newX, newY)) {
            return Position(newX.toDouble(), newY.toDouble());
          }
        }
      }
      radius++;
    }

    // If no open node is found, return the original position
    return currentPosition;
  }

  bool isOpenNode(int x, int y) {
    String node = mapMatrix[x][y];
    return node != '0';
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double cellSize = screenSize.width / mapMatrix[0].length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Way!'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Custom back button behavior
            customBackButtonBehavior();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.house),
            onPressed: () {
              widget.mqttManager.disconnect();

              Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const Home(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mapMatrix[0].length,
                  ),
                  itemCount: mapMatrix.length * mapMatrix[0].length,
                  itemBuilder: (BuildContext context, int index) {
                    int row = index ~/ mapMatrix[0].length;
                    int col = index % mapMatrix[0].length;
                    return GridTile(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _getBackgroundColor(row, col),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          if (mapMatrix[row][col] != '0' &&
                              mapMatrix[row][col] != 'U' &&
                              mapMatrix[row][col] != '3') {
                            setState(() {
                              lastClickedRow = row;
                              lastClickedCol = col;
                            });
                          }
                        },
                        child: Text(
                          mapMatrix[row][col],
                          style: TextStyle(
                            fontSize: cellSize / 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.16,
                  ),
                  Text(
                      "Distance to travel: ${getPathDistance().toString()} mt"),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showOwnerInfo(context),
                    icon: const Icon(
                      FontAwesomeIcons.circleInfo,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  calculateAndDisplayPath();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).highlightColor,
                  shadowColor: Theme.of(context).colorScheme.tertiary,
                  elevation: 5,
                ),
                child: const Text('Navigate!'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 8.0,
                right: 30,
                left: 30,
              ),
              child: ElevatedButton(
                onPressed: () => setState(() {
                  path.clear();
                }),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                  elevation: 5,
                ),
                child: const Text('Reset Path'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOwnerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Map Info',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).highlightColor,
            ),
          ),
          content: Text(
              'This map has been created by the user: ${mapConfig!.owner}'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double getPathDistance() {
    if (path.isEmpty) return 0;

    return (path.length - 1) * mapConfig!.dbp;
  }

  List<List<String>> _parseInput(String input) {
    List<List<String>> matrix = [];
    List<String> lines = input.trim().split('\n');

    for (var line in lines) {
      List<String> row = [];
      for (var char in line.split('')) {
        row.add(char);
      }
      matrix.add(row);
    }
    return matrix;
  }

  Color _getBackgroundColor(int row, int col) {
    String cellValue = mapMatrix[row][col];
    if (path.contains(Point(row, col))) {
      return pathNodeColor;
    } else if (lastClickedRow == row && lastClickedCol == col) {
      return selectedNodeColor;
    } else {
      return _getColor(cellValue);
    }
  }

  Color _getColor(String char) {
    switch (char) {
      case '1':
        return openNodeColor;
      case '0':
        return closedNodeColor;
      case '2':
        return joinNodeColor;
      case '3':
        return privateNodeColor;
      case 'X':
        return beaconNodeColor;
      case 'U':
        return userNodeColor;
      default:
        return Colors.grey;
    }
  }
}
